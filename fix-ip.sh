#!/bin/bash

# ********************************************
# 	Script para Atualização dinâmica de 
# 	     ACLs de Gestão no UFW
# 	    Carlos 'Snake' Menezes
#   [Megabyte Security Labs] - VoRTeX Corp.
# ********************************************

if [ -z "$1" ]; then
    echo "Erro: Forneça o novo IP. Uso: sudo $0 <NOVO_IP>"
    exit 1
fi

NEW_IP=$1
OLD_IP=""
# Lista de portos que estão abertos apenas para o meu ip
ADMIN_PORTS=(2222 10000 3306 8000 8089 3389)

echo " *******************************************************"
echo " *  Iniciando Atualização de Perímetro para: $NEW_IP   *"

echo " *******************************************************"
for PORT in "${ADMIN_PORTS[@]}"; do
# 1. Limpeza de permissão do IP antigo
    sudo ufw delete allow from $OLD_IP to any port $PORT proto tcp > /dev/null 2>&1
    
# 2. Adiciona a permissão para o IP novo
    sudo ufw allow from $NEW_IP to any port $PORT proto tcp
    echo "[OK] Porto $PORT migrado para $NEW_IP"
done

# 3. Atualiza o script para a próxima execução automática
sed -i "s/OLD_IP=\"$OLD_IP\"/OLD_IP=\"$NEW_IP\"/" $0
echo " **********************************"
echo " * Migração Concluída com Sucesso *"
echo " **********************************"