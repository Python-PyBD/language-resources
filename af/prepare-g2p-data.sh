#! /bin/bash

set -o errexit
set -o nounset
set -o pipefail

if [ "$#" -ne 1 ]; then
  echo "Usage: $0 OUTPUT_DIRECTORY" >&2
  exit 2
fi

outdir="$1"

# Output files that will be generated in $outdir:
syms="$outdir/graphone.syms"
train="$outdir/g2p_train.far"
test="$outdir/g2p_test.tsv"

# Input files and tools:
runfiles="${0}.runfiles"
projdir="$runfiles/language_resources"
dict="$projdir/af/lex_regular.txt"
alignables="$projdir/af/alignables.txt"
words="$projdir/af/test_words.txt"
festus="$projdir/festus"
openfst="$runfiles/openfst"

export LC_ALL=C.UTF-8

"$festus/make-alignable-symbols" \
  --alignables="$alignables" \
  "$syms"

sort -c "$words"

sort -t$'\t' -k1,1 "$dict" |
join -t$'\t' -j1 "$words" - \
  > "$test"

sort -t$'\t' -k1,1 "$dict" |
comm -23 - "$test" |
"$festus/lexicon-diagnostics" \
  --alignables="$alignables" \
  --unique_alignments \
  --filter |
tee "$outdir/g2p_train.tsv" |
cut -f 3 |
"$openfst/farcompilestrings" \
  --symbols="$syms" \
  --keep_symbols \
  --generate_keys=6 \
  > "$train"
