#!/usr/bin/env bash
# system_health.sh - log CPU, memory and disk usage with a timestamp.
set -euo pipefail

LOG_FILE="$(dirname "$(readlink -f "$0")")/health_log.txt"
DISK_THRESHOLD=80

# CPU usage (%) sampled over 1 second from /proc/stat
read -r _ u1 n1 s1 i1 w1 q1 sq1 _ < /proc/stat
sleep 1
read -r _ u2 n2 s2 i2 w2 q2 sq2 _ < /proc/stat
idle=$(( (i2 + w2) - (i1 + w1) ))
total=$(( (u2 + n2 + s2 + i2 + w2 + q2 + sq2) - (u1 + n1 + s1 + i1 + w1 + q1 + sq1) ))
cpu=$(( total > 0 ? 100 * (total - idle) / total : 0 ))

# Memory usage (%)
mem=$(free | awk '/^Mem:/ {printf "%d", $3 * 100 / $2}')

# Disk usage (%) of root filesystem
disk=$(df -P / | awk 'NR==2 {gsub("%",""); print $5}')

timestamp="$(date '+%Y-%m-%d %H:%M:%S')"
entry="[$timestamp] CPU: ${cpu}% | Memory: ${mem}% | Disk: ${disk}%"

echo "$entry" | tee -a "$LOG_FILE"

if [ "$disk" -gt "$DISK_THRESHOLD" ]; then
    warning="[WARNING] Disk space high!"
    echo "$warning"
    echo "[$timestamp] $warning" >> "$LOG_FILE"
fi
