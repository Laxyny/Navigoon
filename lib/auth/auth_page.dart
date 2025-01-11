import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthPage extends StatelessWidget {
  const AuthPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Connexion'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () async {
                try {
                  final googleUser = await GoogleSignIn().signIn();
                  if (googleUser == null) return;

                  final googleAuth = await googleUser.authentication;
                  final credential = GoogleAuthProvider.credential(
                    accessToken: googleAuth.accessToken,
                    idToken: googleAuth.idToken,
                  );
                  await FirebaseAuth.instance.signInWithCredential(credential);
                  Navigator.pop(context);
                } catch (e) {
                  print('Erreur Google Sign-In: $e');
                }
              },
              child: const Text('Se connecter avec Google'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(context, '/login');
              },
              child: const Text('Se connecter avec Email/Mot de passe'),
            ),
          ],
        ),
      ),
    );
  }
}
