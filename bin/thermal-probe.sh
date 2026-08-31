#!/usr/bin/env bash
# Snapshot thermal pressure, GPU state, and the top compositing/CPU offenders.
# Run this twice: once on the built-in display, once with the external monitor attached.
set -u

echo "== $(date '+%F %T') =="

echo "-- thermal level (0 = no pressure, higher = throttling) --"
sysctl -n machdep.xcpm.cpu_thermal_level machdep.xcpm.gpu_thermal_level \
  | paste -d' ' - - | awk '{printf "cpu=%s gpu=%s\n", $1, $2}'

echo "-- displays (look for 'Scaled' / UI Looks like != Resolution) --"
system_profiler SPDisplaysDataType 2>/dev/null \
  | grep -E 'Chipset|Display Type|Resolution|UI Looks like|Connection Type|Mirror'

echo "-- top CPU --"
ps -Ao pcpu,comm -r | head -8

echo "-- WindowServer --"
ps -Ao pcpu,rss,comm | grep -m1 WindowServer

echo "-- fans / power (needs sudo; ctrl-c to skip) --"
sudo powermetrics --samplers smc,gpu_power -n 1 -i 1000 2>/dev/null \
  | grep -iE 'fan|GPU .*Power|CPU die|package'
