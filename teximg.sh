#!/bin/bash

# --- Error handling ---
set -e

# --- Help Function ---
show_help() {
cat << EOF
Usage: $0 [options] <formula> <scale>

Generates a transparent PNG image from a LaTeX formula.

Options:
  -o, --output FILE   Set the output file name (default: output.png)
  -h, --help          Display this help and exit

Arguments:
  formula             The LaTeX formula to render (e.g., "\\frac{a}{b}")
  scale               The scaling percentage (e.g., 100)
EOF
}

# --- Dependency Checks ---
command -v pdflatex >/dev/null 2>&1 || { echo >&2 "Error: pdflatex is not installed. Please install a TeX distribution (like TeX Live)."; exit 1; }
command -v convert >/dev/null 2>&1 || { echo >&2 "Error: convert (ImageMagick) is not installed. Please install ImageMagick."; exit 1; }
command -v bc >/dev/null 2>&1 || { echo >&2 "Error: bc is not installed. Please install bc."; exit 1; }
command -v getopt >/dev/null 2>&1 || { echo >&2 "Error: getopt is not installed. It's usually part of the 'util-linux' package."; exit 1; }


# --- Argument Parsing ---
OUTPUT_FILE="output.png"

# Note: The -o option requires a value, so it's followed by a colon.
# The -h option does not, so it is not.
PARSED_OPTIONS=$(getopt -n "$0" -o o:h --longoptions output:,help -- "$@")
if [ $? -ne 0 ]; then
    show_help >&2
    exit 1
fi
# Set the positional parameters ($1, $2, etc.) to the parsed options
eval set -- "$PARSED_OPTIONS"

while true; do
    case "$1" in
        -h|--help) 
            show_help
            exit 0
            ;; 
        -o|--output)
            OUTPUT_FILE="$2"
            shift 2
            ;; 
        --) 
            shift
            break
            ;; 
        *)
            echo "Internal error!" >&2
            exit 1
            ;; 
    esac
done

# Handle positional arguments
if [ "$#" -ne 2 ]; then
    echo "Error: Invalid number of arguments. See --help for usage." >&2
    exit 1
fi

FORMULA=$1
SCALE=$2


# --- Constants ---
BASELINE_HEIGHT=48 # px, this is our 100% reference height
DENSITY=600        # DPI for high-quality rendering

# --- Calculation ---
# Use bc for floating point arithmetic
TARGET_HEIGHT=$(bc <<< "$BASELINE_HEIGHT * $SCALE / 100")
# Round to the nearest integer
TARGET_HEIGHT=$(printf "%.0f" "$TARGET_HEIGHT")

# --- File Handling ---
# Create a unique temporary directory to work in
TMP_DIR=$(mktemp -d)
# Ensure the temporary directory is cleaned up on exit
trap 'rm -rf -- "$TMP_DIR"' EXIT

BASE_NAME="$TMP_DIR/tex"
TEX_FILE="$BASE_NAME.tex"
PDF_FILE="$BASE_NAME.pdf"

# --- LaTeX Generation ---
# Create the .tex file using a heredoc
cat > "$TEX_FILE" << EOF
\documentclass[preview, border=2pt]{standalone}
\usepackage{amsmath}
\usepackage{amssymb}
\usepackage{amsfonts}
\usepackage{xcolor}
\begin{document}
{\color{black} \[$FORMULA\]}
\end{document}
EOF

# --- Compilation and Conversion ---
echo "Generating LaTeX PDF..."
pdflatex -interaction=nonstopmode -output-directory="$TMP_DIR" "$TEX_FILE" >/dev/null 2>&1

echo "Converting PDF to PNG..."
convert -density "$DENSITY" "$PDF_FILE" -resize "x$TARGET_HEIGHT" -transparent white "$OUTPUT_FILE"

echo ""
echo "Success! Image saved as $OUTPUT_FILE"
echo "Dimensions: $(identify -format '%wx%h' "$OUTPUT_FILE")"