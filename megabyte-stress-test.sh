#!/bin/bash

# ********************************************
# 		SOC Stress test 
# 	    Carlos 'Snake' Menezes
#   [Megabyte Security Labs] - VoRTeX Corp.
# ********************************************

LOG_FILE="/var/log/megabyte-performance.log"

# Cores para o terminal
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}************************************************************${NC}"
echo -e "${BLUE}   INICIANDO AUDITORIA DE PERFORMANCE - MEGABYTE          ${NC}"
echo -e "${BLUE}    AUTOR: CARLOS 'SNAKE' MENEZES			  ${NC}"
echo -e "${BLUE}************************************************************${NC}"

# Função para logar e mostrar no ecrã ao mesmo tempo
run_test() {
    echo -e "${GREEN}[$(date +%H:%M:%S)] $1${NC}" | tee -a $LOG_FILE
}

{
echo "************************************************************"
echo "AUDITORIA DE PERFORMANCE COMPLETA - $(date)"
echo "************************************************************"
} >> $LOG_FILE

# *** TESTE 1 ***
run_test "Passo 1/5: Medindo Bandwidth Inicial (Aguarde...)"
speedtest | tee -a $LOG_FILE

# *** TESTE 2 ***
run_test "Passo 2/5: Testando Latência e DNS..."
ping -c 5 8.8.8.8 | tee -a $LOG_FILE

# *** TESTE 3 ***
run_test "Passo 3/5: Carga no Splunk (10k requests) + Bandwidth Intermediária..."
speedtest | tee -a $LOG_FILE
ab -n 10000 -c 100 http://127.0.0.1:8000/ | tee -a $LOG_FILE

# *** TESTE 4 ***
run_test "Passo 4/5: Testando Resiliência (Flood) - 15 segundos..."
sudo timeout 15s hping3 -S --flood -V -p 8000 127.0.0.1 | tee -a $LOG_FILE

# *** TESTE 5 ***
run_test "Passo 5/5: Medindo Bandwidth Final..."
speedtest | tee -a $LOG_FILE

echo -e "${BLUE}************************************************************${NC}"
echo -e "${GREEN}   TESTE CONCLUÍDO COM SUCESSO! Log: $LOG_FILE ${NC}"
echo -e "${BLUE}************************************************************${NC}"
