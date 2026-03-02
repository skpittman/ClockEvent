#!/bin/bash
cd "$(dirname "$0")"

LOGDIR="logs"
mkdir -p "$LOGDIR"

# Rotate logs: keep last 5
for i in 4 3 2 1; do
    next=$((i + 1))
    [ -f "$LOGDIR/test_$i.log" ] && mv "$LOGDIR/test_$i.log" "$LOGDIR/test_$next.log"
done
[ -f "$LOGDIR/test.log" ] && mv "$LOGDIR/test.log" "$LOGDIR/test_1.log"

echo "=== ClockEvent test run: $(date) ===" | tee "$LOGDIR/test.log"
plasmoidviewer -a . 2>&1 | tee -a "$LOGDIR/test.log"
