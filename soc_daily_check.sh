#!/bin/bash

# ********************************************
# SOC Checagem Diária - Monitorização de Nginx
# 	    Carlos 'Snake' Menezes
#   [Megabyte Security Labs] - VoRTeX Corp.
# ********************************************

LOG_FILE="/var/log/nginx/access.log"
MY_IP=""

echo "--- [SOC REPORT] - $(date) ---"
echo ""
echo "[x] TOP 10 IPs Externos (Excluindo o teu):"
awk -v myip="$MY_IP" '$1 != myip {print $1}' $LOG_FILE | sort | uniq -c | sort -nr | head -n 10

echo ""
echo "[x] Possíveis Ataques de Fuzzing (404 excessivos):"
awk '$9 == 404 {print $1}' $LOG_FILE | sort | uniq -c | sort -nr | head -n 5

echo ""
echo "[x] Acessos a Páginas Sensíveis (Login/Admin):"
grep -E "login|admin|config|setup" $LOG_FILE | awk '{print $1 " -> " $7}' | sort | uniq -c | sort -nr | head -n 5