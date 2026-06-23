# Guide d'exécution SmartFleet (Docker) 🚀

Ce guide vous explique comment exécuter l'application **SmartFleet** (Backend et Frontend Flutter) de manière simple et automatisée grâce à **Docker**. Vous n'avez pas besoin d'installer Flutter, Dart, Java ou de base de données sur votre machine.

---

## 📋 Prérequis

Avant de commencer, assurez-vous d'avoir installé **Docker Desktop** sur votre ordinateur :
1. Téléchargez et installez **Docker Desktop** pour votre système d'exploitation :
   - [Télécharger Docker Desktop](https://www.docker.com/products/docker-desktop/)
2. Lancez l'application **Docker Desktop**. Elle doit rester ouverte en arrière-plan pendant toute la durée des tests (l'icône de la baleine dans la barre des tâches doit être verte).

---

## ⚡ Étape 1 : Démarrer le Backend et la Base de Données

Le backend fournit les données et gère les calculs. Il doit être démarré en premier.

1. Ouvrez un terminal (Invite de commandes, PowerShell ou Terminal sous macOS/Linux).
2. Naviguez vers le dossier **`backend`** de votre projet :
   ```bash
   cd chemin/vers/le/projet/backend
   ```
3. Exécutez la commande suivante pour télécharger et lancer tous les services du backend (Base de données PostGIS, moteur d'itinéraires Valhalla et l'application serveur) :
   ```bash
   docker compose up -d
   ```
   *(Note : Le premier démarrage peut prendre quelques minutes pour télécharger les images et la carte du Maroc pour Valhalla).*
4. Pour vérifier que le backend fonctionne, vous pouvez visiter ce lien dans votre navigateur :
   [http://localhost:8080/api/health](http://localhost:8080/api/health)
   Vous devriez voir un message indiquant que le système est fonctionnel.

---

## 🖥️ Étape 2 : Démarrer l'application Flutter (Frontend)

Une fois le backend démarré, vous pouvez lancer l'interface utilisateur.

1. Ouvrez une nouvelle fenêtre de terminal ou restez dans la même.
2. Naviguez vers le dossier **`smartFleet_frontend`** de votre projet :
   ```bash
   cd chemin/vers/le/projet/smartFleet_frontend
   ```
3. Exécutez la commande suivante pour compiler et démarrer l'application web :
   ```bash
   docker compose up -d --build
   ```
   *(Note : Docker va compiler l'application Flutter pour le web. Cela peut prendre 2 à 3 minutes lors du premier lancement).*

---

## 🎈 Étape 3 : Accéder à l'application

Une fois les deux étapes terminées :
1. Ouvrez votre navigateur Web (Chrome, Firefox, Safari ou Edge).
2. Rendez-vous sur l'adresse suivante :
   👉 **[http://localhost:3000](http://localhost:3000)**
3. L'application est prête à être testée !

---

## 🛑 Étape 4 : Arrêter les applications

Lorsque vous avez terminé vos tests, vous pouvez libérer les ressources de votre ordinateur en éteignant les conteneurs :

1. Dans le dossier **`smartFleet_frontend`**, exécutez :
   ```bash
   docker compose down
   ```
2. Dans le dossier **`backend`**, exécutez :
   ```bash
   docker compose down
   ```
ou fermez simplement l'application **Docker Desktop**.

---

## 🛠️ En cas de problème

- **Erreur de connexion (CORS / Backend inaccessible)** : Vérifiez bien que vous accédez à l'application via `http://localhost:3000` (et non `localhost:80` ou un autre port) et que le backend est bien en cours d'exécution sur `http://localhost:8080`.
- **Docker ne démarre pas** : Assurez-vous que l'application Docker Desktop est bien ouverte et active sur votre machine avant de lancer les commandes.
