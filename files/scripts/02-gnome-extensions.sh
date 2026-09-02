#!/bin/bash
set -ex

# GNOME Shell extensions are shipped as git submodules under
# files/system/usr/share/gnome-shell/extensions/<uuid> (see .gitmodules) and
# built from source here. Non-GNOME variants get the unbuilt source trees
# deleted instead.

EXT_DIR="/usr/share/gnome-shell/extensions"
OVERRIDE="/usr/share/glib-2.0/schemas/zz1-fe02-extensions.gschema.override"

APPINDICATOR="appindicatorsupport@rgcjonas.gmail.com"
BLUR_MY_SHELL="blur-my-shell@aunetx"
GSCONNECT="gsconnect@andyholmes.github.io"
JUST_PERFECTION="just-perfection-desktop@just-perfection"
CLIPBOARD_INDICATOR="clipboard-indicator@tudmotu.com"
DDTERM="ddterm@amezin.github.com"
ROUNDED_WINDOW_CORNERS="rounded-window-corners@fxgn"

if [[ "${DESKTOP_ENV,,}" != "gnome" ]]; then
    echo "Not a GNOME image; removing GNOME Shell extension sources..."
    rm -rf \
        "$EXT_DIR/$APPINDICATOR" \
        "$EXT_DIR/$BLUR_MY_SHELL" \
        "$EXT_DIR/$GSCONNECT" \
        "$EXT_DIR/$JUST_PERFECTION" \
        "$EXT_DIR/$CLIPBOARD_INDICATOR" \
        "$EXT_DIR/$DDTERM" \
        "$EXT_DIR/$ROUNDED_WINDOW_CORNERS"
    rm -f "$OVERRIDE"
    exit 0
fi

echo "Building GNOME Shell extensions from source..."

# Snapshot installed packages so every package pulled in for the build below
# (explicit build deps and whatever they drag in transitively) can be
# removed afterwards, even if it wasn't named explicitly.
PKGS_BEFORE="$(mktemp)"
rpm -qa --qf '%{NAME}\n' | sort > "$PKGS_BEFORE"

# libxslt: xsltproc, required by ddterm's build. nodejs: npm/npx, required to
# compile Rounded Window Corners' TypeScript sources.
BUILD_DEPS=(glib2-devel gettext meson ninja-build unzip make gcc libxslt nodejs npm)
dnf --setopt=install_weak_deps=False install -y "${BUILD_DEPS[@]}"

# AppIndicator and KStatusNotifierItem Support
glib-compile-schemas --strict "$EXT_DIR/$APPINDICATOR/schemas"

# Blur My Shell
make -C "$EXT_DIR/$BLUR_MY_SHELL"
unzip -o "$EXT_DIR/$BLUR_MY_SHELL/build/$BLUR_MY_SHELL.shell-extension.zip" -d "$EXT_DIR/$BLUR_MY_SHELL"
glib-compile-schemas --strict "$EXT_DIR/$BLUR_MY_SHELL/schemas"
rm -rf "$EXT_DIR/$BLUR_MY_SHELL/build"

# GSConnect
# Installed via a DESTDIR staging tree, then the source checkout is replaced
# with only what meson actually marks install:true (it also installs a
# D-Bus service and a Nautilus extension outside $EXT_DIR/$GSCONNECT, so the
# whole staged tree - not just the extension subdir - gets copied onto /).
meson setup --prefix=/usr "$EXT_DIR/$GSCONNECT" "$EXT_DIR/$GSCONNECT/_build"
GSCONNECT_DESTDIR="$(mktemp -d)"
meson install -C "$EXT_DIR/$GSCONNECT/_build" --skip-subprojects --destdir "$GSCONNECT_DESTDIR"
rm -rf "$EXT_DIR/$GSCONNECT"
cp -a "$GSCONNECT_DESTDIR"/. /
rm -rf "$GSCONNECT_DESTDIR"

# Just Perfection
bash "$EXT_DIR/$JUST_PERFECTION/scripts/build.sh"
unzip -o "$EXT_DIR/$JUST_PERFECTION/$JUST_PERFECTION.shell-extension.zip" -d "$EXT_DIR/$JUST_PERFECTION"
rm -f "$EXT_DIR/$JUST_PERFECTION/$JUST_PERFECTION.shell-extension.zip"
glib-compile-schemas --strict "$EXT_DIR/$JUST_PERFECTION/schemas"

# Clipboard Indicator
glib-compile-schemas --strict "$EXT_DIR/$CLIPBOARD_INDICATOR/schemas"

# ddterm
# Same DESTDIR staging approach as GSConnect - ddterm also installs a
# launcher symlink to /usr/bin, a D-Bus service, and a .desktop file outside
# $EXT_DIR/$DDTERM.
meson setup --prefix=/usr "$EXT_DIR/$DDTERM" "$EXT_DIR/$DDTERM/_build"
DDTERM_DESTDIR="$(mktemp -d)"
meson install -C "$EXT_DIR/$DDTERM/_build" --destdir "$DDTERM_DESTDIR"
rm -rf "$EXT_DIR/$DDTERM"
cp -a "$DDTERM_DESTDIR"/. /
rm -rf "$DDTERM_DESTDIR"

# Rounded Window Corners (Reborn) - TypeScript, built by hand since it's
# normally driven by `just build` (see its justfile); replicated here rather
# than adding `just` as another build dep for one extension.
RWC_DIR="$EXT_DIR/$ROUNDED_WINDOW_CORNERS"
RWC_BUILD="$RWC_DIR/_build"

# HOME=/tmp: /root is a symlink to /var/roothome, which doesn't exist yet at
# this point in the build (systemd-tmpfiles only populates /var in the final
# post-setup step), so npm can't create its cache/log dir under the real $HOME.
(cd "$RWC_DIR" && HOME=/tmp npm install --no-audit --no-fund && HOME=/tmp npx tsc --outDir "$RWC_BUILD")

cp -r "$RWC_DIR/resources/." "$RWC_BUILD/"
while IFS= read -r f; do
    mkdir -p "$RWC_BUILD/$(dirname "$f")"
    cp "$RWC_DIR/src/$f" "$RWC_BUILD/$f"
done < <(cd "$RWC_DIR" && find src -type f ! -name '*.ts' -printf '%P\n')

for po in "$RWC_DIR"/po/*.po; do
    locale="$(basename "$po" .po)"
    dir="$RWC_BUILD/locale/$locale/LC_MESSAGES"
    mkdir -p "$dir"
    msgfmt -o "$dir/$ROUNDED_WINDOW_CORNERS.mo" "$po"
done

glib-compile-schemas --strict "$RWC_BUILD/schemas"

find "$RWC_DIR" -mindepth 1 -maxdepth 1 ! -name "$(basename "$RWC_BUILD")" -exec rm -rf {} +
mv "$RWC_BUILD"/* "$RWC_DIR"/
rm -rf "$RWC_BUILD"

# Recompile the system schema cache so the extensions' schemas and the
# enabled-extensions default below are picked up.
rm -f /usr/share/glib-2.0/schemas/gschemas.compiled
glib-compile-schemas /usr/share/glib-2.0/schemas

# Remove every package that wasn't present before the build-dep install,
# not just the ones named in BUILD_DEPS, so nothing pulled in transitively
# (e.g. -devel packages meson/gcc depend on, or npm's node dependencies) is
# left behind.
PKGS_AFTER="$(mktemp)"
rpm -qa --qf '%{NAME}\n' | sort > "$PKGS_AFTER"
NEW_PKGS="$(comm -13 "$PKGS_BEFORE" "$PKGS_AFTER")"
if [[ -n "$NEW_PKGS" ]]; then
    dnf remove -y $NEW_PKGS
fi
rm -f "$PKGS_BEFORE" "$PKGS_AFTER"

for ext in "$APPINDICATOR" "$BLUR_MY_SHELL" "$GSCONNECT" "$JUST_PERFECTION" \
    "$CLIPBOARD_INDICATOR" "$DDTERM" "$ROUNDED_WINDOW_CORNERS"; do
    rm -rf "$EXT_DIR/$ext/.git"
done

echo "GNOME Shell extensions built."
