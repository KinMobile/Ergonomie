# Ergonomie – Application d'expertise ergonomique sur iOS

Ce dépôt décrit la conception d'une application iOS destinée aux ergonomes
pour analyser les mouvements filmés sur le terrain à l'aide d'un iPhone 13.
L'objectif est de fournir un outil mobile capable de :

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
