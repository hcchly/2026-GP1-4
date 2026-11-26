import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';

import 'firebase_options.dart';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'screens/auth/splash_screen.dart';
import 'settings/app_settings.dart';
import 'theme/app_theme.dart';

const _useFirebaseEmulators = bool.fromEnvironment(
  'USE_FIREBASE_EMULATORS',
  defaultValue: false,
);
const _firebaseEmulatorHost = String.fromEnvironment(
  'FIREBASE_EMULATOR_HOST',
  defaultValue: '127.0.0.1',
);
const _resetLocalAuth = bool.fromEnvironment(
  'RESET_LOCAL_AUTH',
  defaultValue: false,
);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  if (_useFirebaseEmulators) {
    await FirebaseAuth.instance.useAuthEmulator(_firebaseEmulatorHost, 9099);
    FirebaseFirestore.instance.useFirestoreEmulator(_firebaseEmulatorHost, 8080);
    await FirebaseStorage.instance.useStorageEmulator(
      _firebaseEmulatorHost,
      9199,
    );
    if (_resetLocalAuth) {
      await FirebaseAuth.instance.signOut();
    }
  }
  await AppSettings.instance.load();
  runApp(const KhotaApp());
}

class KhotaApp extends StatelessWidget {
  const KhotaApp({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = AppSettings.instance;
    return ListenableBuilder(
      listenable: settings,
      builder: (context, _) {
        return MaterialApp(
          title: 'خُطى',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light(),
          darkTheme: AppTheme.dark(),
          themeMode: settings.themeMode,

          // Arabic only, right-to-left for the whole app.
          locale: const Locale('ar'),
          supportedLocales: const [Locale('ar')],
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],

          // Apply the in-app font size and bold text on top of the
          // phone's own accessibility settings (up to 200%).
          builder: (context, child) {
            final media = MediaQuery.of(context);
            final systemScale = media.textScaler.scale(1);
            final scale = (systemScale * settings.textScale)
                .clamp(0.8, 2.0)
                .toDouble();
            return MediaQuery(
              data: media.copyWith(
                textScaler: TextScaler.linear(scale),
                boldText: media.boldText || settings.boldText,
              ),
              child: child!,
            );
          },

          // Animated intro, then login (or home if already signed in).
          home: const SplashScreen(),
        );
      },
    );
  }
}
