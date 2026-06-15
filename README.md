Vide Coded app to manage System76-power modes for computers with multiple GPUs

# System76-Power-Graphic-Applet

Petit utilitaire graphique pour **Pop!_OS / Wayland** permettant de piloter la commande `system76-power graphics` depuis une fenêtre GTK et, selon le support de la barre système, depuis une icône dans le panneau supérieur.

L'outil sert à :
- voir le **mode graphique actuel** ;
- afficher les **modes disponibles** sur la machine ;
- lire une **description rapide** de chaque mode au survol ;
- demander un **changement de mode** ;
- voir le **mode en attente**, les **actions à réaliser** (par exemple redémarrer), et la **sortie de la commande** pour diagnostiquer une erreur.

## Modes pris en charge

Selon la machine et le pilote installé, l'application peut afficher ces modes :

- `integrated` : utilise uniquement le GPU intégré, généralement pour réduire la consommation.
- `hybrid` : utilise le GPU intégré par défaut et le GPU dédié à la demande.
- `nvidia` : utilise le GPU NVIDIA comme mode principal.
- `compute` : garde le rendu principal sur l'iGPU et réserve le GPU dédié aux tâches de calcul.

## Fonctionnement

L'application s'appuie sur la commande système :

```bash
system76-power graphics
```

Et pour demander un changement de mode :

```bash
system76-power graphics <mode>
```

En pratique, le changement de mode graphique peut nécessiter un **redémarrage** avant de devenir effectif.

## Installation

Utiliser le script d'installation :

```bash
chmod +x install-system76-graphics-applet.sh
./install-system76-graphics-applet.sh
```

Le script :
- installe les dépendances Python / GTK ;
- copie l'application dans `~/.local/share/system76-graphics-applet` ;
- crée un lanceur dans `~/.local/bin` ;
- ajoute une entrée dans `~/.local/share/applications` pour l'ouvrir depuis le lanceur d'applications ;
- ajoute une entrée d'autostart dans `~/.config/autostart`.

## Lancer l'application

Après installation, l'application peut être démarrée de deux façons :

### Depuis le lanceur d'applications

Chercher :

```text
System76 Graphics Applet
```

### Depuis le terminal

```bash
~/.local/bin/system76-graphics-applet
```

## Utilisation

1. Ouvrir l'application.
2. Lire le **mode actuel** dans la section `État`.
3. Passer la souris sur un bouton pour voir la **description** du mode.
4. Cliquer sur le mode souhaité.
5. Lire la zone `Sortie de la commande system76-power` pour vérifier le résultat.
6. Si l'application indique qu'un redémarrage est requis, redémarrer la machine.

## Interface

L'interface contient trois zones principales :

### 1. Modes disponibles

- affiche les boutons de sélection des modes ;
- montre une courte description à droite ;
- affiche aussi cette description au survol du bouton.

### 2. État

- indique le **mode actuel** ;
- indique le **mode en attente** après une demande de changement ;
- indique les **actions à réaliser**.

### 3. Sortie de la commande

- affiche `stdout` ;
- affiche `stderr` ;
- affiche le code de retour ;
- aide à comprendre ce qui a échoué si la commande ne passe pas.

## Désinstallation

Utiliser le script de désinstallation :

```bash
chmod +x uninstall-system76-graphics-applet.sh
./uninstall-system76-graphics-applet.sh
```

Le script supprime :
- les fichiers de l'application ;
- le lanceur utilisateur ;
- l'entrée du menu d'applications ;
- l'entrée d'autostart.

## Dépannage

### L'application n'apparaît pas dans le lanceur

Essayer :

```bash
update-desktop-database ~/.local/share/applications
```

Puis se déconnecter / reconnecter si nécessaire.

### Le changement de mode échoue

Vérifier :
- que `system76-power` est bien installé ;
- que le mode demandé est réellement supporté par la machine ;
- le contenu de la zone `Sortie de la commande` dans l'application.

### L'icône ne s'affiche pas dans le panneau supérieur

Selon l'environnement et le support de la barre système, `Gtk.StatusIcon` peut ne pas être affiché de façon identique. Dans ce cas, l'application reste utilisable normalement depuis le lanceur.

## Public visé

Cet outil est surtout utile pour les utilisateurs de **Pop!_OS** qui veulent une petite interface graphique simple au-dessus de `system76-power graphics`, sans devoir saisir la commande à la main à chaque fois.
