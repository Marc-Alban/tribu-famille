# Tribu Famille 👨‍👩‍👧‍👦 (100% Native iOS - SwiftUI)

Application mobile **100% Native iOS (Swift / SwiftUI)** développée pour réunir la famille :

### 🚀 Fonctionnalités Clés
1. **🎂 Anniversaires & Alertes Intelligentes** :
   - Calcul automatique des âges et jours restants pour chaque membre et enfant.
   - Prochain anniversaire mis en avant en bannière Hero avec compte à rebours.
   - Bouton d'action directe "Lui Souhaiter" (SMS pré-rempli).
   - Notifications push locales natives (`UserNotifications`) le Jour J à 9h00 et rappel J-7.
2. **🎄 Événements & Qui ramène quoi ?** :
   - Checklist collaborative pour les réveillons de Noël et repas de famille.
   - Réservation des plats en 1 tap avec assignation immédiate du nom du membre.
3. **🛒 Liste de Courses Collective** :
   - Organisée par rayons (Épicerie, Frais, Fruits & Légumes, Bébé, Maison).
   - Cochez les articles au magasin pour les barrer en direct.
4. **🎁 Idées Cadeaux & Wishlists Secrètes** :
   - Chaque membre et enfant a sa liste de souhaits.
   - Système de réservation secrète (les autres membres voient que c'est réservé, mais la personne garde la surprise).
5. **❤️ Le Coin Tribu & Mémère** :
   - **Mode Mémère (Gros Textes)** : adaptation instantanée pour les aînés.
   - **💬 Perles & Mots d'enfants** : citations cultes des repas et des enfants.
   - **🏥 Trousseau Santé & Pratique** : médecin de famille, SAMU, pédiatre et code Wi-Fi de la maison.
   - **📸 Journal Photo** : fil des souvenirs de la famille.

---

### 🛠️ Architecture Technique
- **Technologie :** 100% Native iOS (SwiftUI, iOS 17+, Swift 5.0)
- **Frameworks système :** `SwiftUI`, `UserNotifications`, `Combine`
- **Projet Xcode :** `TribuFamille.xcodeproj`
- **Bundle ID :** `fr.tribufamille.app`
- **Déploiement CI/CD :** GitHub Actions (`macos-latest` runner gratuit) + Fastlane vers Apple TestFlight.
