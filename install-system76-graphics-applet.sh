#!/bin/bash
# Script d'installation : install-system76-graphics-applet.sh
# Objectif :
#  - Installer une app GTK (Python) pour gérer `system76-power graphics`
#  - Lancer l'app depuis le lanceur / centre d'applications de Pop!_OS
#  - Démarrer automatiquement l'app à la connexion
#  - Utiliser une UI mise à jour :
#      * plus d'espace entre les blocs
#      * bloc de sortie de commande plus petit
#      * boutons de modes de même taille
#      * marge autour de la colonne de boutons
#      * titres de blocs décalés vers la droite

set -e

APP_NAME="System76 Graphics Applet"
APP_ID="system76-graphics-applet"
APP_DIR="$HOME/.local/share/$APP_ID"
BIN_PATH="$HOME/.local/bin/$APP_ID"
AUTOSTART_FILE="$HOME/.config/autostart/$APP_ID.desktop"
APPLICATIONS_FILE="$HOME/.local/share/applications/$APP_ID.desktop"
ICON_DIR="$HOME/.local/share/icons"
ICON_PATH="$ICON_DIR/$APP_ID.png"
APP_PY="$APP_DIR/app.py"

echo "=== Installation de $APP_NAME ==="

# 1) Dépendances
echo "[1/7] Installation des dépendances…"
sudo apt update
sudo apt install -y python3 python3-gi gir1.2-gtk-3.0 python3-cairo

# 2) Dossiers
echo "[2/7] Création des dossiers…"
mkdir -p "$APP_DIR"
mkdir -p "$HOME/.local/bin"
mkdir -p "$HOME/.config/autostart"
mkdir -p "$HOME/.local/share/applications"
mkdir -p "$ICON_DIR"

# 3) Icône simple générée en SVG puis PNG via GTK-compatible path
echo "[3/7] Création de l'icône…"

cat > "$APP_DIR/icon.svg" << 'SVGEOL'
<svg xmlns="http://www.w3.org/2000/svg" width="128" height="128" viewBox="0 0 128 128">
  <rect x="10" y="10" width="108" height="108" rx="24" fill="#2b2f3a"/>
  <rect x="22" y="26" width="84" height="52" rx="10" fill="#5aa9e6"/>
  <rect x="30" y="34" width="68" height="36" rx="6" fill="#d9f0ff"/>
  <circle cx="42" cy="94" r="8" fill="#7bd389"/>
  <circle cx="64" cy="94" r="8" fill="#f2c14e"/>
  <circle cx="86" cy="94" r="8" fill="#ef6f6c"/>
</svg>
SVGEOL

# On garde l'icône SVG directement, ce qui fonctionne avec les desktop entries modernes
ICON_PATH="$APP_DIR/icon.svg"

# 4) Application Python
echo "[4/7] Création de l'application…"

cat > "$APP_PY" << 'PYEOF'
#!/usr/bin/env python3
import gi
import subprocess
import threading

gi.require_version("Gtk", "3.0")
from gi.repository import Gtk, GLib

MODES = {
    "integrated": "L'iGPU (Intel/AMD intégré) est utilisé exclusivement. Moins de performances, meilleure autonomie.",
    "nvidia":     "La dGPU NVIDIA est utilisée exclusivement. Hautes performances, consommation plus élevée.",
    "hybrid":     "Mode hybride : iGPU principal, dGPU utilisé à la demande (PRIME render offload).",
    "compute":    "Mode compute : dGPU utilisée comme noeud de calcul, rendu assuré par l'iGPU.",
}

CMD_BASE = ["system76-power", "graphics"]


def run_cmd(cmd):
    try:
        proc = subprocess.Popen(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
        out, err = proc.communicate()
        return out.strip(), err.strip(), proc.returncode
    except Exception as e:
        return "", str(e), 1


def get_current_mode():
    out, err, code = run_cmd(CMD_BASE)
    if code != 0:
        return None, out + ("\n" + err if err else "")
    return out.strip().lower(), out


def make_frame(title):
    frame = Gtk.Frame()

    title_label = Gtk.Label(label=title)
    title_label.set_xalign(0.0)
    title_label.set_margin_start(10)
    title_label.set_margin_end(6)
    frame.set_label_widget(title_label)
    frame.set_label_align(0.0, 0.5)

    frame.set_margin_top(4)
    frame.set_margin_bottom(4)

    return frame


class GraphicsApplet(Gtk.Window):
    def __init__(self):
        Gtk.Window.__init__(self, title="System76 Graphics Applet")
        self.set_default_size(600, 280)
        self.set_border_width(12)

        self.current_mode = None
        self.pending_mode = None

        root_scroll = Gtk.ScrolledWindow()
        root_scroll.set_policy(Gtk.PolicyType.NEVER, Gtk.PolicyType.AUTOMATIC)
        self.add(root_scroll)
        
        outer = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=12)
        outer.set_margin_top(12)
        outer.set_margin_bottom(12)
        outer.set_margin_start(12)
        outer.set_margin_end(12)
        
        root_scroll.add(outer)

        # --- Bloc modes disponibles ---
        frame_modes = make_frame("Modes disponibles")
        outer.pack_start(frame_modes, False, False, 0)

        modes_outer = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=12)
        modes_outer.set_margin_top(10)
        modes_outer.set_margin_bottom(10)
        modes_outer.set_margin_start(10)
        modes_outer.set_margin_end(10)
        frame_modes.add(modes_outer)

        # Colonne de boutons homogènes
        buttons_box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=8)
        buttons_box.set_homogeneous(True)
        buttons_box.set_margin_top(4)
        buttons_box.set_margin_bottom(4)
        buttons_box.set_margin_start(4)
        modes_outer.pack_start(buttons_box, False, False, 0)

        # Colonne de descriptions
        descs_box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=8)
        descs_box.set_margin_top(4)
        descs_box.set_margin_bottom(4)
        descs_box.set_margin_end(4)
        modes_outer.pack_start(descs_box, True, True, 0)

        self.mode_buttons = {}
        for mode, desc in MODES.items():
            btn = Gtk.Button(label=mode)
            btn.connect("clicked", self.on_mode_clicked, mode)
            btn.set_tooltip_text(desc)
            btn.set_size_request(120, 34)
            self.mode_buttons[mode] = btn
            buttons_box.pack_start(btn, True, True, 0)

            lbl = Gtk.Label(label=desc)
            lbl.set_line_wrap(True)
            lbl.set_xalign(0.0)
            lbl.set_yalign(0.5)
            descs_box.pack_start(lbl, True, True, 0)

        # --- Bloc état ---
        frame_info = make_frame("État")
        outer.pack_start(frame_info, False, False, 0)

        info_box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=6)
        info_box.set_margin_top(10)
        info_box.set_margin_bottom(10)
        info_box.set_margin_start(10)
        info_box.set_margin_end(10)
        frame_info.add(info_box)

        self.label_current = Gtk.Label(label="Mode actuel : inconnu")
        self.label_current.set_xalign(0.0)
        info_box.pack_start(self.label_current, False, False, 0)

        self.label_pending = Gtk.Label(label="Mode en attente : aucun")
        self.label_pending.set_xalign(0.0)
        info_box.pack_start(self.label_pending, False, False, 0)

        self.label_actions = Gtk.Label(label="Actions à réaliser : aucune")
        self.label_actions.set_xalign(0.0)
        info_box.pack_start(self.label_actions, False, False, 0)

        # --- Bloc sortie commande ---
        frame_output = make_frame("Sortie de la commande system76-power")
        outer.pack_start(frame_output, True, True, 0)

        output_box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=0)
        output_box.set_margin_top(10)
        output_box.set_margin_bottom(14)
        output_box.set_margin_start(10)
        output_box.set_margin_end(10)
        frame_output.add(output_box)

        scrolled = Gtk.ScrolledWindow()
        scrolled.set_policy(Gtk.PolicyType.AUTOMATIC, Gtk.PolicyType.AUTOMATIC)   # Hauteur plus petite pour forcer l'apparition du scroll plus tôt
        scrolled.set_size_request(-1, 120)     # Petite marge sous le bloc de sortie pour l'éloigner du bas de la fenêtre
        scrolled.set_margin_bottom(10)
        
        output_box.pack_start(scrolled, True, True, 0)

        self.textview = Gtk.TextView()
        self.textview.set_editable(False)
        self.textview.set_wrap_mode(Gtk.WrapMode.WORD_CHAR)
        self.textview.set_top_margin(6)    # Marge permettant plus de lisibilité
        self.textview.set_bottom_margin(6)
        self.textview.set_left_margin(6)
        self.textview.set_right_margin(6)
        scrolled.add(self.textview)

        # --- Bouton refresh ---
        btn_refresh = Gtk.Button(label="Rafraîchir l'état")
        btn_refresh.connect("clicked", self.on_refresh_clicked)
        btn_refresh.set_margin_top(4)
        outer.pack_start(btn_refresh, False, False, 0)

        # Icône barre système (legacy ; selon la barre utilisée)
        self.tray = Gtk.StatusIcon()
        self.tray.connect("activate", self.on_tray_activate)
        self.tray.set_visible(True)

        self.refresh_state()
        GLib.timeout_add_seconds(15, self.on_timer)

    def append_output(self, text):
        buf = self.textview.get_buffer()
        end = buf.get_end_iter()
        buf.insert(end, text + "\\n")

    def set_tray_icon(self):
        mode = self.current_mode
        if mode == "nvidia":
            icon = "video-display"
            tooltip = "Graphics: NVIDIA"
        elif mode == "integrated":
            icon = "computer"
            tooltip = "Graphics: Integrated"
        elif mode == "hybrid":
            icon = "applications-system"
            tooltip = "Graphics: Hybrid"
        elif mode == "compute":
            icon = "system-run"
            tooltip = "Graphics: Compute"
        else:
            icon = "dialog-warning"
            tooltip = "Graphics: inconnu"

        self.tray.set_from_icon_name(icon)
        self.tray.set_tooltip_text(tooltip)

    def refresh_state(self):
        mode, raw = get_current_mode()
        self.current_mode = mode

        if mode is None:
            self.label_current.set_text("Mode actuel : erreur")
            self.append_output("Erreur lecture mode actuel :\\n" + raw + "\\n")
        else:
            self.label_current.set_text(f"Mode actuel : {mode}")

        self.set_tray_icon()
        return True

    def on_timer(self):
        self.refresh_state()
        return True

    def on_tray_activate(self, icon):
        if self.is_visible():
            self.hide()
        else:
            self.show_all()

    def on_refresh_clicked(self, btn):
        self.refresh_state()

    def on_mode_clicked(self, btn, mode):
        self.pending_mode = mode
        self.label_pending.set_text(f"Mode en attente : {mode}")
        self.label_actions.set_text("Actions à réaliser : changement demandé… (un redémarrage sera nécessaire)")
        self.append_output(f"=== Changement demandé vers : {mode} ===")

        t = threading.Thread(target=self.change_mode_thread, args=(mode,))
        t.daemon = True
        t.start()

    def change_mode_thread(self, mode):
        cmd = CMD_BASE + [mode]
        out, err, code = run_cmd(cmd)

        def done():
            self.append_output("Commande : " + " ".join(cmd))
            if out:
                self.append_output("STDOUT:\\n" + out)
            if err:
                self.append_output("STDERR:\\n" + err)
            self.append_output(f"Code de sortie : {code}\\n")

            self.refresh_state()

            if code == 0:
                self.label_pending.set_text(f"Mode en attente : {mode} (reboot requis)")
                self.label_actions.set_text("Actions à réaliser : redémarrer la machine pour appliquer le mode.")
            else:
                self.label_pending.set_text("Mode en attente : erreur, voir sortie ci-dessous")
                self.label_actions.set_text("Actions à réaliser : corriger l'erreur, recommencer la commande.")

        GLib.idle_add(done)


def main():
    win = GraphicsApplet()
    win.connect("destroy", Gtk.main_quit)
    win.show_all()
    Gtk.main()


if __name__ == "__main__":
    main()
PYEOF

chmod +x "$APP_PY"

# 5) Wrapper exécutable
echo "[5/7] Création du lanceur binaire utilisateur…"

cat > "$BIN_PATH" << 'BINEOF'
#!/bin/bash
exec "$HOME/.local/share/system76-graphics-applet/app.py" "$@"
BINEOF

chmod +x "$BIN_PATH"

# 6) Entrée du lanceur d'applications
echo "[6/7] Création de l'entrée dans le lanceur d'apps…"

cat > "$APPLICATIONS_FILE" << DESKEOF
[Desktop Entry]
Version=1.0
Type=Application
Name=System76 Graphics Applet
Comment=Applet graphique pour gérer system76-power graphics
Exec=$BIN_PATH
Icon=$ICON_PATH
Terminal=false
Categories=System;Settings;Utility;
StartupNotify=true
Keywords=system76;graphics;gpu;nvidia;integrated;hybrid;compute;popos;
DESKEOF

chmod +x "$APPLICATIONS_FILE"

# 7) Entrée Autostart
echo "[7/7] Création de l'entrée Autostart…"

cat > "$AUTOSTART_FILE" << DESKEOF
[Desktop Entry]
Version=1.0
Type=Application
Name=System76 Graphics Applet
Comment=Applet graphique pour gérer system76-power graphics
Exec=$BIN_PATH
Icon=$ICON_PATH
Terminal=false
X-GNOME-Autostart-enabled=true
X-GNOME-Autostart-Delay=5
StartupNotify=false
DESKEOF

# Rafraîchir la base des desktop files si l'outil existe
if command -v update-desktop-database >/dev/null 2>&1; then
    update-desktop-database "$HOME/.local/share/applications" || true
fi

echo ""
echo "=== Installation terminée ==="
echo ""
echo "Tu peux maintenant :"
echo "  - lancer l'app depuis le lanceur / centre d'applications en cherchant :"
echo "      $APP_NAME"
echo "  - ou la lancer en terminal avec :"
echo "      $BIN_PATH"
echo ""
echo "Si l'app n'apparaît pas immédiatement dans le lanceur :"
echo "  - déconnecte/reconnecte ta session"
echo "  - ou lance : update-desktop-database ~/.local/share/applications"
echo ""
echo "Remarque :"
echo "  - les changements de mode graphique via system76-power nécessitent généralement un redémarrage pour être effectifs."
