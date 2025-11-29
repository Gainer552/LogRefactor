#!/usr/bin/env bash

# ===============================
#   Log Noise Reducer Tool
# ===============================

# Color Codes
RED="\033[31m"
YELLOW="\033[33m"
GREEN="\033[32m"
BLUE="\033[34m"
MAGENTA="\033[35m"
CYAN="\033[36m"
RESET="\033[0m"

CACHE_FILE=".log_patterns_cache"
OUTPUT_FILE="log_reduced_output_$(date +%Y%m%d_%H%M%S).txt"

# Ensure cache exists
touch "$CACHE_FILE"

echo -e "${CYAN}[+] Log Noise Reducer${RESET}"
read -rp "Enter path to log file: " LOGFILE

if [[ ! -f "$LOGFILE" ]]; then
    echo -e "${RED}Error: File does not exist.${RESET}"
    exit 1
fi

echo -e "${BLUE}Processing...${RESET}"

# -----------------------------------------
# PREP STEP: ANALYZE + NORMALIZE PATTERNS
# -----------------------------------------
# Normalization: replace variable tokens (IPs, PIDs, numbers) with placeholders
normalize_pattern() {
    sed -E \
        -e 's/[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+/<IP>/g' \
        -e 's/[0-9]{4,}/<NUM>/g' \
        -e 's/ pid=[0-9]+/ pid=<PID>/g' \
        -e 's/\[[0-9]+\]/\[<PID>\]/g'
}

# -----------------------------------------
# MAIN PROCESSING
# -----------------------------------------
awk '
function strip_ts(line) {
    sub(/^[A-Z][a-z]{2} [ 0-9]{2} [0-9]{2}:[0-9]{2}:[0-9]{2}/,"",line);
    return line;
}

{
    full=$0;

    # Extract timestamp
    ts=$1" "$2" "$3;

    # Extract process & PID
    match($0, /([a-zA-Z0-9_.-]+)\[([0-9]+)\]/, m);
    proc = (m[1] != "" ? m[1] : "unknown");
    pid  = (m[2] != "" ? m[2] : "none");

    # Strip timestamp from message
    msg = full;
    sub(/^[A-Z][a-z]{2} [ 0-9]{2} [0-9]{2}:[0-9]{2}:[0-9]{2}/, "", msg);

    # Save data
    linecount[full]++;
    processcount[proc]++;
    pidcount[pid]++;
    timestamp[full]=ts;

} END {
    print "---RAW_AGGREGATION_START---"
    for (l in linecount) {
        print linecount[l] "||" timestamp[l] "||" l;
    }
    print "---RAW_AGGREGATION_END---"

    print "---PROCESS_AGG_START---"
    for (p in processcount) {
        print p "||" processcount[p];
    }
    print "---PROCESS_AGG_END---"

    print "---PID_AGG_START---"
    for (pp in pidcount) {
        print pp "||" pidcount[pp];
    }
    print "---PID_AGG_END---"
}' "$LOGFILE" > .tmp_logdata

# -----------------------------------------
# NEW PATTERN DETECTION (STRUCTURAL MATCH)
# -----------------------------------------
echo -e "${MAGENTA}Detecting unseen patterns...${RESET}"

NEW_PATTERNS=()

while IFS= read -r line; do
    normalized=$(echo "$line" | normalize_pattern)

    if ! grep -qxF "$normalized" "$CACHE_FILE"; then
        NEW_PATTERNS+=("$normalized")
        echo "$normalized" >> "$CACHE_FILE"
    fi
done < "$LOGFILE"

# -----------------------------------------
# DISPLAY RESULTS
# -----------------------------------------
{
echo ""
echo "===================================================="
echo "                 LOG NOISE REDUCTION"
echo "===================================================="

echo -e "\n${GREEN}Top Unique Log Lines (Grouped)${RESET}"
printf "%-10s | %-20s | %s\n" "COUNT" "TIMESTAMP" "MESSAGE"
echo "----------------------------------------------------"

grep "RAW_AGGREGATION_START" -A9999 .tmp_logdata | sed '1d' | sed '/RAW_AGGREGATION_END/,$d' \
| sort -nr \
| while IFS="||" read -r count ts msg; do
    # Severity coloring
    if echo "$msg" | grep -qi "error\|fail\|denied\|refused"; then
        color="$RED"
    elif echo "$msg" | grep -qi "warn"; then
        color="$YELLOW"
    else
        color="$RESET"
    fi

    printf "${color}%-10s | %-20s | %s${RESET}\n" "$count" "$ts" "$msg"
done

echo -e "\n${CYAN}Process Aggregation${RESET}"
printf "%-20s | %s\n" "PROCESS" "COUNT"
echo "-----------------------------------"
grep "PROCESS_AGG_START" -A9999 .tmp_logdata | sed '1d' | sed '/PROCESS_AGG_END/,$d' \
| sort -t"||" -k2 -nr \
| awk -F"||" '{printf "%-20s | %s\n", $1, $2}'

echo -e "\n${CYAN}PID Aggregation${RESET}"
printf "%-10s | %s\n" "PID" "COUNT"
echo "-----------------------------------"
grep "PID_AGG_START" -A9999 .tmp_logdata | sed '1d' | sed '/PID_AGG_END/,$d' \
| sort -t"||" -k2 -nr \
| awk -F"||" '{printf "%-10s | %s\n", $1, $2}'

# -----------------------------------------
# NEW PATTERNS SECTION
# -----------------------------------------
echo -e "\n${MAGENTA}New / Unseen Patterns${RESET}"
if [[ ${#NEW_PATTERNS[@]} -eq 0 ]]; then
    echo "None"
else
    for np in "${NEW_PATTERNS[@]}"; do
        echo -e "${GREEN}+ $np${RESET}"
    done
fi

# -----------------------------------------
# SUMMARY
# -----------------------------------------
echo -e "\n${BLUE}Summary${RESET}"
echo "----------------------------"
echo "Total unique lines: $(grep RAW_AGGREGATION_START -A9999 .tmp_logdata | sed '1d' | sed '/RAW_AGGREGATION_END/,$d' | wc -l)"
echo "Total processes:    $(grep PROCESS_AGG_START -A9999 .tmp_logdata | sed '1d' | sed '/PROCESS_AGG_END/,$d' | wc -l)"
echo "New patterns:       ${#NEW_PATTERNS[@]}"
echo "Output saved to:    $OUTPUT_FILE"

} | tee "$OUTPUT_FILE"

# Make output immutable
chattr +i "$OUTPUT_FILE" 2>/dev/null || {
    echo -e "${YELLOW}Warning: Could not set immutable bit. Requires root.${RESET}"
}

rm -f .tmp_logdata

echo -e "${GREEN}Done.${RESET}"
