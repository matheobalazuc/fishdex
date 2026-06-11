# Fishdex — Frontend & Backend

> Application mobile-first permettant aux pêcheurs d'identifier leurs prises, de les partager et de suivre leur progression.

---

## Architecture globale

Ce dépôt contient le **front-end** de l'application ainsi que la gestion du **back-end Firebase** (base de données utilisateurs, stockage des données, authentification).

La partie **intelligence artificielle** (identification des poissons par photo) est développée dans un dépôt séparé :
→ [github.com/Boyuzhang333/FishDex](https://github.com/Boyuzhang333/FishDex)

---

## Ce dépôt

### Front-end — Flutter Web PWA

Application développée en **Flutter Web**, déployée sur **Vercel** et installable sur iPhone via *Ajouter à l'écran d'accueil* (PWA standalone).

**Écrans principaux :**
- `home_screen` — Fil d'actualité, top pêcheurs, hotspots, succès
- `camera_screen` — Prise de photo, identification IA, sauvegarde de la prise
- `catch_detail_screen` — Détail d'une prise, publication, commentaires, likes
- `collection_screen` — Collection personnelle de prises
- `marketplace_screen` — Catalogue matériel de pêche, recherche, magasins proches
- `profile_screen` — Profil utilisateur, modification des informations, suppression de compte
- `messages_screen` — Notifications (likes, commentaires)

**Stack front-end :**
| Outil | Usage |
|---|---|
| Flutter Web | Framework UI |
| Vercel | Hébergement & déploiement continu |
| `google_fonts` / `flutter_animate` | Design & animations |
| `url_launcher` | Ouverture Google Maps |
| `image_picker` | Capture photo |

---

### Back-end Firebase

#### Authentification — Firebase Auth
- Inscription / connexion par email & mot de passe
- Email interne au format `username@fishdex.app` (l'username visible est la partie avant le `@`)
- Modification du nom d'affichage, du pseudo, du mot de passe
- Suppression de compte (supprime également toutes les données associées)

#### Base de données — Firestore

| Collection | Contenu |
|---|---|
| `users/{uid}` | Profil : `displayName`, `username`, `createdAt` |
| `catches/{id}` | Prise : espèce, photo, taille, poids, lieu, statut publication, likes, commentaires |
| `catches/{id}/comments/{id}` | Commentaires avec auteur, texte, timestamp |
| `notifications/{uid}/items/{id}` | Notifications de likes et commentaires |

#### Règles de sécurité Firestore recommandées

```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {

    match /catches/{catchId} {
      allow read: if true;
      allow create: if request.auth != null;
      allow update, delete: if request.auth != null
        && request.auth.uid == resource.data.userId;

      match /comments/{commentId} {
        allow read: if true;
        allow create: if request.auth != null;
        allow update, delete: if request.auth != null
          && request.auth.uid == resource.data.userId;
      }
    }

    match /users/{userId} {
      allow read: if true;
      allow write: if request.auth != null && request.auth.uid == userId;
    }

    match /notifications/{userId}/items/{itemId} {
      allow read: if request.auth != null && request.auth.uid == userId;
      allow create: if request.auth != null;
      allow update, delete: if request.auth != null && request.auth.uid == userId;
    }
  }
}
```

---

## Déploiement

Le déploiement est automatique via Vercel à chaque push sur `main`.

Le script `build.sh` à la racine :
1. Clone le SDK Flutter stable
2. Build l'app en mode release (`--pwa-strategy=none`)
3. Génère un `version.json` horodaté pour forcer la mise à jour du cache iOS PWA

```bash
bash build.sh
```

---

## Développement local

```bash
flutter pub get
flutter run -d chrome
```

---

## Dépôt IA

L'identification des espèces de poissons par photo (modèle de vision, API) est maintenue ici :
→ [github.com/Boyuzhang333/FishDex](https://github.com/Boyuzhang333/FishDex)
