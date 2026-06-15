#!/bin/bash
# Script de désinstallation : uninstall-system76-graphics-applet.sh
# Supprime l'applet System76 Graphics Applet installée dans l'espace utilisateur.

set -e

APP_NAME="System76 Graphics Applet"
APP_ID="system76-graphics-applet"
APP_DIR="$HOME/.local/share/$APP_ID"
BIN_PATH="$HOME/.local/bin/$APP_ID"
AUTOSTART_FILE="$HOME/.config/autostart/$APP_ID.desktop"
APPLICATIONS_FILE="$HOME/.local/share/applications/$APP_ID.desktop"

echo "=== Désinstallation de $APP_NAME ==="

# 1) Arrêter l'application si elle tourne
echo "[1/6] Arrêt de l'application si elle est en cours d'exécution…"
pkill -f "$APP_DIR/app.py" 2>/dev/null || true
pkill -f "$BIN_PATH" 2>/dev/null || true

# 2) Supprimer le lanceur du centre d'applications / menu
echo "[2/6] Suppression de l'entrée dans le lanceur d'applications…"
if [ -f "$APPLICATIONS_FILE" ]; then
    rm -f "$APPLICATIONS_FILE"
    echo "  ✓ Supprimé : $APPLICATIONS_FILE"
else
    echo "  - Absent : $APPLICATIONS_FILE"
fi

# 3) Supprimer l'autostart
echo "[3/6] Suppression de l'entrée de démarrage automatique…"
if [ -f "$AUTOSTART_FILE" ]; then
    rm -f "$AUTOSTART_FILE"
    echo "  ✓ Supprimé : $AUTOSTART_FILE"
else
    echo "  - Absent : $AUTOSTART_FILE"
fi

# 4) Supprimer le lanceur binaire utilisateur
echo "[4/6] Suppression du lanceur utilisateur…"
if [ -f "$BIN_PATH" ]; then
    rm -f "$BIN_PATH"
    echo "  ✓ Supprimé : $BIN_PATH"
else
    echo "  - Absent : $BIN_PATH"
fi

# 5) Supprimer les fichiers de l'application
echo "[5/6] Suppression des fichiers de l'application…"
if [ -d "$APP_DIR" ]; then
    rm -rf "$APP_DIR"
    echo "  ✓ Supprimé : $APP_DIR"
else
    echo "  - Absent : $APP_DIR"
fi

# 6) Rafraîchir la base des desktop files si possible
echo "[6/6] Rafraîchissement de la base des applications…"
if command -v update-desktop-database >/dev/null 2>&1; then
    update-desktop-database "$HOME/.local/share/applications" || true
    echo "  ✓ Base des applications rafraîchie"
else
    echo "  - update-desktop-database non disponible, ignoré"
fi

echo ""
echo "=== Désinstallation terminée ==="
echo ""
echo "Si l'icône apparaît encore dans le lanceur :"
echo "  - attends quelques secondes,"
echo "  - ou déconnecte/reconnecte ta session,"
echo "  - ou relance le lanceur d'applications."
