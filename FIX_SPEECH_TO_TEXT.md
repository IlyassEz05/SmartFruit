# Fix pour l'erreur speech_to_text

Si vous rencontrez toujours l'erreur "Unresolved reference 'Registrar'" avec speech_to_text, voici les solutions :

## Solution 1 : Utiliser une version spécifique (RECOMMANDÉ)

Dans `pubspec.yaml`, utilisez une version spécifique qui fonctionne avec Flutter 3.x :

```yaml
speech_to_text: 6.7.0  # Sans le ^ pour forcer cette version exacte
```

Puis exécutez :
```bash
flutter clean
flutter pub get
```

## Solution 2 : Si le problème persiste

1. Supprimez le cache :
```bash
rm -rf ~/.pub-cache/hosted/pub.dev/speech_to_text-*
flutter clean
flutter pub get
```

2. Vérifiez que votre version de Flutter est à jour :
```bash
flutter upgrade
flutter doctor
```

## Solution 3 : Alternative - Utiliser une version antérieure

Si les versions récentes ne fonctionnent pas, essayez :

```yaml
speech_to_text: 6.3.0
```

Puis :
```bash
flutter clean
flutter pub get
flutter run
```

