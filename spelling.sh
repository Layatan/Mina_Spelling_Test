#!/usr/bin/env bash

if [[ "$1" == "-h" || "$1" == "--help" ]]; then
    echo "Usage: $0 [ROUNDCOUNT] [MINLEN] [MAXLEN]"
    echo "  MINLEN   Minimum word length (default: 4)"
    echo "  MAXLEN   Maximum word length (default: 35)"
    echo "  ROUNDCOUNT Round count / number of words (default: 10) might take a while based on computer"
    echo "  EXAMPLE: $0 4 35 10"
    echo
    echo "  WARNING: Run with bash -i $0 if it doesnt let you seek input while writing"
    echo "  WARNING: Also don't store shit in the temp folder maybe idunno. all 'mp3's get wiped each run."
    exit 0
fi

set -euo pipefail
ROUNDCOUNT=${1:-10}      # How many rounds to go (default 10)
MINLEN=${2:-4}         # Minimum word length (default 5)
MAXLEN=${3:-35}        # Maximum word length (default 12)

MAX_ROUNDS=100      # the audio files persist till the next run, this is ~1.5 MB (each is about 15KiB)
MAX_JOBS=10          # how many audio to generate at a time. change if you got a beast, i'm gonna chill out

if (( ROUNDCOUNT > MAX_ROUNDS )); then
    echo "Limiting ROUNDCOUNT to $MAX_ROUNDS to avoid overload."
    ROUNDCOUNT=$MAX_ROUNDS
fi

WORDLIST="wordlist.txt"
TEMPDIR="./temp"
mkdir -p "$TEMPDIR"
rm -f "$TEMPDIR"/*.mp3

# Step 1: Pick $ROUNDCOUNT random words between described lengths
mapfile -t WORDS < <(grep -E "^.{$MINLEN,$MAXLEN}$" "$WORDLIST" | tr -d '\r' | shuf -n "$ROUNDCOUNT")


# Step 2: Generate mp3 files in "temp" folder
job_count=0
for i in "${!WORDS[@]}"; do
    echo -ne "\rGenerating word $((i + 1))/$ROUNDCOUNT"
    gtts-cli "${WORDS[$i]}" --output "${TEMPDIR}/${i}.mp3" &

    job_count=$((job_count + 1))
    if (( job_count >= MAX_JOBS )); then
        wait
        job_count=0
    fi
done
wait

# Step 3: Game
echo -e "\nSpelling Game Begins!\n"
SCORE=0

for i in "${!WORDS[@]}"; do
    WORD="${WORDS[$i]}"
    echo "Word $((i+1))/${#WORDS[@]} | Score $SCORE/${#WORDS[@]}"
    
    # Playback
    if command -v mpg123 &> /dev/null; then
        setsid mpg123 --quiet --loop 3 "${TEMPDIR}/${i}.mp3" > /dev/null 2>&1 &
        MPG_PID=$!
    elif command -v afplay &> /dev/null; then
        afplay "${TEMPDIR}/${i}.mp3" # idk
    else
        echo "No audio player found (mpg123 or afplay)."
        exit 1
    fi

    read -e -r -p "Type the word: " INPUT
    if kill -0 "$MPG_PID" 2>/dev/null; then
        kill "$MPG_PID" 2>/dev/null
    fi

    # correct or nah
    if [[ "${INPUT,,}" == "${WORD,,}" ]]; then
        echo -n "Correct! - "
        SCORE=$((SCORE + 1))
    else
        echo -n "Wrong! - "
    fi

    # compares characters 1 by 1, red if wrong green if correct
    for ((j=0; j<${#WORD}; j++)); do
        if [[ "${INPUT:$j:1}" == "${WORD:$j:1}" ]]; then
            echo -ne "\033[0;32m${INPUT:$j:1}\033[0m"
        else
            echo -ne "\033[0;31m${WORD:$j:1}\033[0m"
        fi
    done

    rm -f "${TEMPDIR}/${i}.mp3"
    echo
done

echo -e "\n🎉 Final Score: $SCORE / ${#WORDS[@]}"
rm -rf "$TEMPDIR"
