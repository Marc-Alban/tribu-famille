# Tribu Famille 👨‍👩‍👧‍👦

Application mobile iOS pour réunir la famille :
1. **Anniversaires automatiques & Notifications** : chaque membre s'inscrit, et toute la famille reçoit une alerte le jour J et 7 jours avant.
2. **Organisation d'Événements (Noël / Réveillons / Fêtes)** : checklist interactive "Qui ramène quoi ?" pour ne plus rien oublier et éviter les doublons.
3. **Gazette & Mur Photos pour Mémère** : partage des moments forts avec mode gros textes ("Mode Mémère") et génération de la synthèse mensuelle.

## Déploiement iOS (TestFlight / App Store)

Ce projet est configuré pour se déployer directement sur **Apple TestFlight** via **GitHub Actions (runner macOS gratuit)** sans abonnement payant EAS :
- Workflow CI : `.github/workflows/deploy-ios.yml`
- Fastlane + App Store Connect API (`AuthKey_2BU8N5TXA7.p8`)
- Team ID Apple : `NTNAWJQ2N3`
- Bundle ID : `fr.tribufamille.app`
