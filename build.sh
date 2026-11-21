#!/usr/bin/env bash
# Arma el repo apt en .site/ a partir de los Releases de cada app de apps.txt.
#
#   ./build.sh                 # firma con la clave GPG del llavero (APT_KEY_ID)
#
# Estructura que genera:
#   .site/key.asc                                 clave pública
#   .site/pool/main/<letra>/<paquete>/*.deb       todos los .deb de todos los Releases
#   .site/dists/stable/main/binary-amd64/Packages(.gz)
#   .site/dists/stable/{Release,InRelease,Release.gpg}
set -euo pipefail

KEY_ID="${APT_KEY_ID:-044EC70FDD4B244C570D8EDCBB942FEDC223C785}"
SITE=.site
DIST=stable
COMP=main
ARCHS="amd64"

rm -rf "$SITE"
mkdir -p "$SITE/pool/$COMP"
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT

# 1) Bajar los .deb de todos los Releases de cada app (las apps ya borran sus
#    Releases viejos, así que esto mantiene solo las últimas versiones).
grep -vE '^\s*(#|$)' apps.txt | while read -r repo; do
  echo "== $repo"
  gh release list -R "$repo" --limit 50 --json tagName --jq '.[].tagName' |
  while read -r tag; do
    d="$tmp/$repo/$tag"
    mkdir -p "$d"
    gh release download "$tag" -R "$repo" -p '*.deb' -D "$d" 2>/dev/null || true
  done
done

# 2) Copiarlos al pool con el nombre estándar <paquete>_<versión>_<arch>.deb
find "$tmp" -name '*.deb' | while read -r deb; do
  pkg=$(dpkg-deb -f "$deb" Package)
  ver=$(dpkg-deb -f "$deb" Version)
  arch=$(dpkg-deb -f "$deb" Architecture)
  dir="$SITE/pool/$COMP/${pkg:0:1}/$pkg"
  mkdir -p "$dir"
  cp "$deb" "$dir/${pkg}_${ver}_${arch}.deb"
  echo "   + ${pkg} ${ver} (${arch})"
done

# 3) Índices
cd "$SITE"
for arch in $ARCHS; do
  out="dists/$DIST/$COMP/binary-$arch"
  mkdir -p "$out"
  apt-ftparchive --arch "$arch" packages "pool/$COMP" > "$out/Packages"
  gzip -9nk "$out/Packages"
done

apt-ftparchive \
  -o APT::FTPArchive::Release::Origin="santiagofr1" \
  -o APT::FTPArchive::Release::Label="santiagofr1" \
  -o APT::FTPArchive::Release::Suite="$DIST" \
  -o APT::FTPArchive::Release::Codename="$DIST" \
  -o APT::FTPArchive::Release::Architectures="$ARCHS" \
  -o APT::FTPArchive::Release::Components="$COMP" \
  release "dists/$DIST" > "dists/$DIST/Release"

# 4) Firmar
gpg --batch --yes --local-user "$KEY_ID" --clearsign -o "dists/$DIST/InRelease" "dists/$DIST/Release"
gpg --batch --yes --local-user "$KEY_ID" -abs -o "dists/$DIST/Release.gpg" "dists/$DIST/Release"

# 5) Clave pública y página de bienvenida
cp ../key.asc key.asc
cp ../index.html index.html
touch .nojekyll
echo "listo: $(find pool -name '*.deb' | wc -l) paquetes"
