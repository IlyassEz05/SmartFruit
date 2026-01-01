# Configuration Firebase - Guide de résolution

## Problème : Erreur CONFIGURATION_NOT_FOUND

Si vous voyez l'erreur `CONFIGURATION_NOT_FOUND` lors de la connexion/inscription, cela signifie que l'authentification Email/Password n'est pas activée dans Firebase Console.

## Solution : Activer l'authentification Email/Password

### Étapes détaillées :

1. **Allez sur Firebase Console**
   - URL : https://console.firebase.google.com
   - Connectez-vous avec votre compte Google

2. **Sélectionnez votre projet**
   - Projet : `smartfruit-f843a`
   - ID du projet : `76025940106`

3. **Accédez à Authentication**
   - Dans le menu de gauche, cliquez sur **"Authentication"** (ou "Authentification")
   - Si c'est la première fois, cliquez sur **"Get started"** (Commencer)

4. **Activez Email/Password**
   - Cliquez sur l'onglet **"Sign-in method"** (Méthodes de connexion)
   - Dans la liste des providers, trouvez **"Email/Password"**
   - Cliquez sur **"Email/Password"**
   - Activez le toggle **"Enable"** (Activer)
   - Optionnel : Activez aussi "Email link (passwordless sign-in)" si vous le souhaitez
   - Cliquez sur **"Save"** (Enregistrer)

5. **Vérification**
   - Vous devriez voir un checkmark vert ✅ à côté de "Email/Password"
   - Le statut devrait indiquer "Enabled"

## Après activation

Une fois l'authentification activée :
1. Attendez quelques secondes (propagation de la configuration)
2. Relancez votre application Flutter
3. Essayez de créer un compte ou de vous connecter

## Vérification supplémentaire

Si le problème persiste après activation :

1. **Vérifiez que votre application Android est bien configurée**
   - Package name : `com.example.smart_fruit`
   - Le fichier `google-services.json` est présent dans `android/app/`

2. **Vérifiez les logs**
   - Regardez les logs dans la console Android Studio
   - Recherchez les messages Firebase

3. **Nettoyez et reconstruisez**
   ```bash
   flutter clean
   flutter pub get
   flutter run
   ```

## Informations du projet Firebase

- **Project ID** : smartfruit-f843a
- **Project Number** : 76025940106
- **Package Name** : com.example.smart_fruit
- **App ID** : 1:76025940106:android:a30d281dcaade1f2878573

