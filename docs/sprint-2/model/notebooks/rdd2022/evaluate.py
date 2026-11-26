import argparse
import hashlib
import json
from pathlib import Path
import shutil
import tempfile

import torch
import ultralytics
import yaml
from ultralytics.models.yolo.detect import DetectionValidator
from ultralytics.utils.ops import scale_boxes


HERE = Path(__file__).resolve().parent


def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def evaluate(dataset):
    reference = json.loads((HERE / 'original_validation.json').read_text())
    manifest = dataset / 'reports/manifest.json'
    weights = HERE / 'best.pt'
    if sha(manifest) != reference['dataset_id'] or sha(weights) != reference['weights_sha256']:
        raise ValueError('Manifest or checkpoint mismatch')
    rows = [row for row in json.loads(manifest.read_text()) if row['split'] == 'val']
    expected = reference['scores']['overall']
    if len(rows) != expected['images']:
        raise ValueError('Unexpected number of validation images')

    import sys
    sys.path.insert(0, str(dataset))
    from evaluate_fixed import summarize

    torch.set_num_threads(4)
    records = []
    confidence = expected['operating_point']['confidence']

    class Validator(DetectionValidator):
        def update_metrics(self, predictions, batch):
            super().update_metrics(predictions, batch)
            for index, pred in enumerate(predictions):
                image = Path(batch['im_file'][index])
                target = self._prepare_batch(index, batch)
                h, w = target['ori_shape']
                chosen = pred['conf'] >= confidence
                boxes = scale_boxes(target['imgsz'], pred['bboxes'][chosen].clone(),
                                    (h, w), target['ratio_pad'])
                gt = []
                for line in (dataset / 'dataset/labels/val' / image.with_suffix('.txt').name).read_text().splitlines():
                    _, x, y, bw, bh = map(float, line.split())
                    gt.append([(x - bw / 2) * w, (y - bh / 2) * h,
                               (x + bw / 2) * w, (y + bh / 2) * h])
                records.append(dict(boxes=boxes.cpu().tolist(), gt=gt,
                                    scores=pred['conf'][chosen].cpu().tolist()))

    with tempfile.TemporaryDirectory() as work:
        root = Path(work)
        # Copy only the validation inputs so dataset cache writes stay temporary.
        for kind, suffix in (('images', '.jpg'), ('labels', '.txt')):
            destination = root / kind / 'val'
            destination.mkdir(parents=True)
            for row in rows:
                filename = row['id'] + suffix
                source = dataset / 'dataset' / kind / 'val' / filename
                hash_key = 'sha256_image' if kind == 'images' else 'sha256_label'
                if sha(source) != row[hash_key]:
                    raise ValueError(f'Data checksum mismatch: {filename}')
                shutil.copyfile(source, destination / filename)
        listing = root / 'val.txt'
        listing.write_text(''.join(f"{root / 'images/val' / (row['id'] + '.jpg')}\n" for row in rows))
        config = root / 'data.yaml'
        config.write_text(yaml.safe_dump(dict(path=str(root), train='images/val',
                                               val=str(listing), names={0: 'surface_damage'})))
        box = ultralytics.YOLO(str(weights)).val(
            validator=Validator, data=str(config), split='val', imgsz=reference['imgsz'],
            batch=4, conf=0.001, iou=reference['nms_iou'], max_det=reference['max_det'],
            rect=False, augment=reference['augment'], device='cpu', workers=0,
            plots=False, project=str(root / 'runs'),
        ).box
    point = summarize(records, confidence)
    if len(records) != len(rows) or point['tp'] + point['fn'] != 5480:
        raise ValueError('Incomplete evaluation')
    return dict(split='val', images=len(rows), boxes=5480, imgsz=reference['imgsz'],
                dataset_id=reference['dataset_id'], weights_sha256=reference['weights_sha256'],
                ultralytics=ultralytics.__version__, torch=torch.__version__,
                mAP50=float(box.map50), mAP50_95=float(box.map), **point)


if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('dataset', type=Path)
    args = parser.parse_args()
    out = json.dumps(evaluate(args.dataset.resolve()), indent=2) + '\n'
    (HERE / 'rerun_results.json').write_text(out)
    print(out)
