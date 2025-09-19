# Ergonomie – Application d'expertise ergonomique sur iOS

Ce dépôt fournit désormais un squelette complet en SwiftUI prêt à être ouvert
dans Xcode pour compiler sur iPhone 13. L'application permet de :

* filmer un travailleur et suivre ses articulations en temps réel ;
* calculer les angles articulaires, la durée des postures/mouvements et les
  répétitions ;
* générer un rapport synthèse aligné sur les normes ISO pertinentes en
  ergonomie (ISO 11226, ISO 11228, ISO/TR 12295, etc.).

Le projet repose sur les frameworks iOS (Vision, AVFoundation, Core ML,
SwiftUI) ainsi que sur un moteur d'analyse ergonomique spécifique détaillé dans
la documentation du dossier `docs/`.

## Structure de la documentation

| Fichier | Contenu |
| --- | --- |
| `docs/architecture.md` | Architecture logique, flux de données, technologies recommandées. |
| `docs/ergonomic-analysis.md` | Calculs biomécaniques, indicateurs ISO, génération de rapports. |
| `docs/roadmap.md` | Feuille de route de développement avec jalons et priorités. |

Ces documents servent de guide pour démarrer le développement natif Swift et
coordonner l'équipe produit, recherche ergonomique et développement logiciel.

## Démarrage rapide dans Xcode

1. Ouvrir Xcode 15+ et créer un nouveau projet "App" en SwiftUI nommé
   `ErgonomieApp` avec iOS 16 comme cible minimale.
2. Copier le contenu du dossier `ErgonomieApp/` de ce dépôt dans le dossier
   source du projet Xcode généré (remplacer les fichiers `ContentView.swift`
   et `NomDuProjetApp.swift`).
3. Ajouter `isoThresholds.json` au groupe "Resources" en vous assurant que le
   fichier est inclus dans la cible iOS.
4. Activer les capacités caméra dans `Info.plist` en ajoutant les clefs
   `NSCameraUsageDescription` et `NSPhotoLibraryAddUsageDescription` avec un
   texte expliquant l'usage ergonomique.
5. Lancer sur un iPhone 13 (ou simulateur caméra si disponible). L'écran
   "Capture" affiche l'aperçu vidéo et superpose la détection de pose, puis les
   onglets "Tableau de bord" et "Rapports" donnent accès aux métriques ISO et à
   l'export PDF/CSV.
