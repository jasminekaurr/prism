#!/usr/bin/env bash
# Downloads Prism brand fonts (SIL OFL 1.1) as data assets.
# Fraunces, Inter, Figtree, Encode Sans
# Run once from the repo root:  ./scripts/fetch_fonts.sh
set -euo pipefail

ASSETS="Prism/Resources/Assets.xcassets"
BASE="https://github.com/google/fonts/raw/main/ofl"

install_font() {
  local asset="$1" file="$2" url="$3"
  local dir="$ASSETS/$asset.dataset"
  mkdir -p "$dir"
  curl -fsSL "$url" -o "$dir/$file"
  cat > "$dir/Contents.json" <<JSON
{
  "data" : [
    {
      "filename" : "$file",
      "idiom" : "universal",
      "universal-type-identifier" : "public.truetype-ttf-data"
    }
  ],
  "info" : {
    "author" : "xcode",
    "version" : 1
  }
}
JSON
  echo "Installed $asset"
}

install_font "FrauncesVariable" "Fraunces.ttf" "$BASE/fraunces/Fraunces%5BSOFT%2CWONK%2Copsz%2Cwght%5D.ttf"
install_font "InterVariable"    "Inter.ttf"    "$BASE/inter/Inter%5Bopsz%2Cwght%5D.ttf"
install_font "FigtreeVariable"  "Figtree.ttf"  "$BASE/figtree/Figtree%5Bwght%5D.ttf"
install_font "EncodeSansVariable" "EncodeSans.ttf" "$BASE/encodesans/EncodeSans%5Bwdth%2Cwght%5D.ttf"
echo "Done. Rebuild the app in Xcode."
