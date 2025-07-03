#!/bin/bash

export http_proxy="http://127.0.0.1:7890"
export https_proxy="http://127.0.0.1:7890"
export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"

# change this working directory path
WORKDIR="$HOME/bughunt/legionmonitor"
# mkdir -p "$WORKDIR"
cd "$WORKDIR" || exit 1

bug="bug"  # Change this to your target domain
DATE=$(date +"%-d%b_%I%P%Mmin" | tr '[:upper:]' '[:lower:]')
SUBDOMAINS_FILE="${WORKDIR}/${DATE}_subs_${bug}"
NEW_SUBDOMAINS_FILE="${WORKDIR}/new_${DATE}_subs_${bug}"

# Detect the latest previous subdomains file
PREVIOUS_FILE=$(ls -1 "${WORKDIR}"/*_subs_${bug} 2>/dev/null | sort -V | tail -n 1)

# Fetch latest subdomains
# 获取子域名数据
if curl -fsSL https://raw.githubusercontent.com/arkadiyt/bounty-targets-data/refs/heads/main/data/domains.txt > "$SUBDOMAINS_FILE" && \
   curl -fsSL https://raw.githubusercontent.com/arkadiyt/bounty-targets-data/refs/heads/main/data/wildcards.txt >> "$SUBDOMAINS_FILE"; then
    echo "[+] Subdomains data fetched."
    
    # 判断文件是否非空
    if [ ! -s "$SUBDOMAINS_FILE" ]; then
        echo "[-] Subdomains file is empty. Exiting..."
        rm -f "$SUBDOMAINS_FILE"
        exit 1
    fi
else
    echo "[-] Failed to fetch subdomains data. Exiting..."
    rm -f "$SUBDOMAINS_FILE"
    exit 1
fi

# Compare with previous file (if exists)
if [[ -n "$PREVIOUS_FILE" && -f "$PREVIOUS_FILE" ]]; then
    comm -13 <(sort "$PREVIOUS_FILE") <(sort "$SUBDOMAINS_FILE") > "$NEW_SUBDOMAINS_FILE"
else
    cp "$SUBDOMAINS_FILE" "$NEW_SUBDOMAINS_FILE"
fi

# Send notification if new subdomains found
if [ -s "$NEW_SUBDOMAINS_FILE" ]; then
    cat "$NEW_SUBDOMAINS_FILE" | /root/go/bin/notify -id "subs_h1vdp"
fi

# Remove the initial previous file
rm -f "$PREVIOUS_FILE"

# Remove the temporary new subdomains file
rm -f "$NEW_SUBDOMAINS_FILE"
