# 📱 Guide de Lancement de l'Application Mobile (Flutter) — SmartFleet

Ce guide explique comment configurer, lancer et tester l'application mobile SmartFleet sur un émulateur, un simulateur ou un appareil physique.

> [!TIP]
> **Alternative Simple (Recommandée pour le Professeur) :**
> Puisque l'application est développée avec Flutter, elle est **entièrement adaptative (responsive)**. Le professeur peut tester exactement la même interface, les mêmes fonctionnalités et la même logique via la **version Web** (exécutée simplement avec Docker en 1 clic sans aucune installation). Voir le fichier `DOCKER_GUIDE_FR.md` dans ce dossier.

---

## 📋 Prérequis pour le développement mobile

Pour exécuter l'application mobile en mode développement, vous devez disposer des outils suivants sur votre machine :
1. **Flutter SDK** installé et configuré (version stable de Flutter, de préférence `3.44.2`).
2. **Android Studio** (avec un émulateur Android configuré) ou **Xcode** (pour simulateur iOS — requis uniquement sur macOS).
3. Assurez-vous que la commande suivante ne renvoie pas d'erreurs bloquantes :
   ```bash
   flutter doctor
   ```

---

## 🔌 Étape critique : Configuration de l'adresse du Backend (IP)

Par défaut, l'application mobile pointe vers `http://localhost:8080/api`. Cependant, selon l'appareil de test utilisé, **cette adresse doit être modifiée** dans le fichier source :
👉 **`lib/service/api_client.dart` (ligne 18)** :

| Appareil de Test | IP à renseigner dans `api_client.dart` | Rationale / Explication |
| :--- | :--- | :--- |
| **Simulateur iOS** | `http://localhost:8080/api` | Le simulateur iOS partage directement le réseau de l'ordinateur hôte. |
| **Émulateur Android** | `http://10.0.2.2:8080/api` | `10.0.2.2` est l'IP spéciale permettant à l'émulateur Android d'accéder au `localhost` du PC hôte. |
| **Téléphone physique** | `http://<IP_DE_VOTRE_PC>:8080/api` (ex: `http://192.168.1.50:8080/api`) | Le téléphone et le PC exécutant le backend doivent être connectés au **même réseau Wi-Fi**. |

---

## 🚀 Méthode 1 : Lancement sur Émulateur / Simulateur (Mode Debug)

1. Démarrez votre émulateur Android (via Android Studio) ou votre simulateur iOS (via Xcode).
2. Ouvrez un terminal dans le dossier **`smartFleet_frontend`**.
3. Modifiez la ligne 18 du fichier `lib/service/api_client.dart` en fonction de votre cible (ex: `10.0.2.2` pour un émulateur Android).
4. Téléchargez les dépendances de l'application :
   ```bash
   flutter pub get
   ```
5. Lancez l'application :
   ```bash
   flutter run
   ```
6. Sélectionnez votre émulateur dans la liste qui s'affiche pour démarrer l'application.

---

## 📦 Méthode 2 : Générer et installer un fichier APK (Appareil Android Physique)

Si vous souhaitez installer l'application directement sur un smartphone Android physique sans passer par un câble ou un émulateur :

1. Récupérez l'adresse IP locale de votre ordinateur :
   - Sur Windows : Ouvrez l'invite de commande, tapez `ipconfig` et cherchez "Adresse IPv4" (ex: `192.168.1.50`).
2. Ouvrez `lib/service/api_client.dart` (ligne 18) et remplacez `localhost` par l'IP locale de votre ordinateur :
   ```dart
   baseUrl: 'http://192.168.1.50:8080/api',
   ```
3. Connectez votre téléphone physique sur le **même réseau Wi-Fi** que votre ordinateur.
4. Ouvrez un terminal dans le dossier **`smartFleet_frontend`** et lancez la compilation :
   ```bash
   flutter build apk --release
   ```
5. Une fois la compilation terminée, récupérez le fichier d'installation APK généré ici :
   `build/app/outputs/flutter-apk/app-release.apk`
6. Transférez le fichier `.apk` sur votre téléphone (par e-mail, WhatsApp Web, Google Drive ou câble USB), ouvrez-le sur votre téléphone et acceptez l'installation pour tester l'application directement.
