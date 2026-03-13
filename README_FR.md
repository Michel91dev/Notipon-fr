# Notipon-fr 🇫🇷

> **Fork français de [Notipon](https://github.com/Mugendesk/Notipon)** par [Mugendesk](https://github.com/Mugendesk)

[![macOS](https://img.shields.io/badge/macOS-13.0+-blue.svg)](https://www.apple.com/macos)
[![Swift](https://img.shields.io/badge/Swift-5.9-orange.svg)](https://swift.org)
[![License](https://img.shields.io/badge/license-MIT-green.svg)](LICENSE)
[![Fork](https://img.shields.io/badge/Fork-Fran%C3%A7ais-blue)](https://github.com/Michel91dev/Notipon-fr)

**Notifications personnalisées pour macOS entièrement en français** — Contrôlez la position, la taille, l'opacité et la durée. Historique complet des notifications avec recherche et export.

---

## 🍴 À propos de ce fork

Ce dépôt est un **fork communautaire** du projet original [Notipon](https://github.com/Mugendesk/Notipon) par [Mugendesk](https://github.com/Mugendesk), avec l'interface utilisateur **entièrement traduite en français**.

### Modifications apportées

- ✅ **Traduction complète** de l'interface (japonais → français)
- ✅ **Localisation des dates** (format français : "Aujourd'hui", "Hier", "1 janvier")
- ✅ **Traduction des paramètres** (délais, modes d'affichage, etc.)
- ✅ **Correction des erreurs de compilation** (fonctions dupliquées, scope variables)
- ✅ **Sécurisation des permissions** (désactivation des fonctionnalités réseau/serveur non utilisées)
- ✅ **Mise à jour des commentaires de code** en français

### Crédits

- **Auteur original** : [Mugendesk](https://github.com/Mugendesk) — [Notipon original](https://github.com/Mugendesk/Notipon)
- **Fork et traduction** : [Michel91dev](https://github.com/Michel91dev)
- **Licence** : MIT (même licence que l'original)

---

## ✨ Pourquoi Notipon ?

Les notifications macOS disparaissent rapidement et vous ne pouvez pas personnaliser leur apparence ou leur position. Notipon résout ces deux problèmes :

1. **Popups de notification personnalisés** — Affichez les notifications exactement où vous voulez, à la taille souhaitée, aussi longtemps que vous le souhaitez
2. **Historique des notifications** — Chaque notification est sauvegardée et consultable, vous ne manquez plus rien

Parfait pour les streamers, les setups multi-moniteurs, et tous ceux qui ont besoin de plus de contrôle sur les notifications macOS.

---

## 🚀 Fonctionnalités principales

### Popup personnalisé
- **Position** — Placement libre sur l'écran (coordonnées X/Y)
- **Taille** — Largeur 200-1200px, Hauteur 60-400px
- **Opacité** — Transparence 30-100%
- **Taille de police** — 10-30pt
- **Durée** — 0-30 secondes (0 = persistant jusqu'à fermeture manuelle)
- **Icône et images** — Affiche l'icône de l'application et les images de notification

### Historique des notifications
- **Capture automatique** — Sauvegarde en temps réel de toutes les notifications macOS
- **Recherche** — Recherche par titre, contenu ou nom d'application
- **Filtrage par app** — Filtre par applications spécifiques
- **Groupement par date** — Organisation auto : "Aujourd'hui", "Hier", "1 janvier"
- **Export** — Formats JSON/CSV

### Barre de menu
- **Survol** — Aperçu des 5 dernières notifications
- **Clic** — Menu déroulant avec les 20 dernières notifications
- **Clic droit** — Ouvre la fenêtre d'historique complète
- **Badge non-lus** — Nombre de notifications non lues en un coup d'œil

### Autres
- **Nettoyage automatique** — Supprime les notifications du Centre de notifications après sauvegarde
- **Applications exclues** — Empêche la capture de certaines applications
- **Lancement auto** — Démarrage à la connexion
- **Contrôle de rétention** — 24h / 7 jours / 30 jours / Illimité

---

## 📥 Installation

### Depuis ce fork (Compilation manuelle)

```bash
# Cloner le fork
git clone https://github.com/Michel91dev/Notipon-fr.git
cd Notipon-fr

# Ouvrir dans Xcode
open Notipon.xcodeproj
```

Puis dans Xcode :
1. Sélectionnez votre équipe de développement (Signing & Capabilities)
2. Cliquez sur **▶ Run** (ou `Cmd + R`)
3. Autorisez les permissions demandées (voir ci-dessous)

### Version originale (Homebrew)

Si vous préférez la version originale en anglais/japonais :

```bash
brew tap mugendesk/tap
brew install --cask notipon
```

---

## 🔐 Permissions requises

### 1. Accès complet au disque (Obligatoire)

Nécessaire pour lire la base de données des notifications macOS.

**Configuration :**
1. `Réglages Système` → `Confidentialité et sécurité` → `Accès complet au disque`
2. Cliquez sur le cadenas pour vous authentifier
3. Cliquez sur le bouton `+`
4. Sélectionnez `/Applications/Notipon.app`
5. Redémarrez Notipon

### 2. Accessibilité (Recommandé)

Permet la détection en temps réel des notifications avec une latence réduite.

**Configuration :**
1. `Réglages Système` → `Confidentialité et sécurité` → `Accessibilité`
2. Cliquez sur le cadenas pour vous authentifier
3. Cliquez sur le bouton `+`
4. Sélectionnez `/Applications/Notipon.app`
5. Redémarrez Notipon

---

## 🛠️ Spécifications techniques

### Architecture
- **Langage** : Swift 5.9
- **Frameworks** : SwiftUI, AppKit
- **Base de données** : SQLite (GRDB.swift)
- **Détection des notifications** : API Accessibilité (polling adaptatif)

### Performances
| Métrique | Performance |
|----------|-------------|
| Latence de détection | 50-200ms (adaptatif) |
| Changement de filtre | Instantané (filtre en mémoire) |
| Utilisation mémoire | ~50 Mo |
| Utilisation CPU | 0% en veille / ~10% à la notification |
| Impact énergétique | Faible |

### Emplacement des données
```
~/Library/Application Support/Notipon/notifications.db
```

---

## 🔧 Dépannage

### Les notifications ne sont pas sauvegardées

1. Vérifiez que la permission **Accès complet au disque** est accordée
2. Redémarrez Notipon
3. Vérifiez que la base de données existe :
   ```bash
   ls ~/Library/Application\ Support/Notipon/
   ```

### Détection lente

1. Ajoutez la permission **Accessibilité**
2. La détection en temps réel sera activée, réduisant la latence

### L'application ne se lance pas

1. Clic droit → "Ouvrir" pour lancer
2. Nécessite macOS 13.0 ou ultérieur
3. Consultez Console.app pour les journaux d'erreur

---

## 🤝 Contribuer

Les pull requests sont les bienvenues !

```bash
git clone https://github.com/Michel91dev/Notipon-fr.git
cd Notipon-fr
open Notipon.xcodeproj
```

### Prérequis de développement
- Xcode 15.0 ou ultérieur
- Swift 5.9 ou ultérieur

---

## 📄 Licence

MIT License

Copyright (c) 2026 Mugendesk (auteur original)  
Copyright (c) 2026 Michel91dev (fork et traduction)

Voir le fichier [LICENSE](LICENSE) pour les détails.

---

## 🔗 Liens

- **Fork français** : [github.com/Michel91dev/Notipon-fr](https://github.com/Michel91dev/Notipon-fr)
- **Original** : [github.com/Mugendesk/Notipon](https://github.com/Mugendesk/Notipon)
- **Signaler un problème** (fork) : [Issues](https://github.com/Michel91dev/Notipon-fr/issues)
- **Signaler un problème** (original) : [Issues](https://github.com/Mugendesk/Notipon/issues)

---

Made with ❤️ by [Mugendesk](https://github.com/Mugendesk) — Traduit avec 🥖 par [Michel91dev](https://github.com/Michel91dev)
