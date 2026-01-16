#!/bin/bash

# ********************************************
#      Script de Rotina de verificação SOC
# 	    Carlos 'Snake' Menezes
#   [Megabyte Security Labs] - VoRTeX Corp.
# ********************************************

# Configuração
IP_LIST_URL="https://lists.blocklist.de/lists/all.txt"
LOCK_FILE="/var/tmp/ban_ip.lock"
IPSET_NAME="blacklist"


# Ficheiros Temporários
TEMP_IP_FILE="/tmp/ip_list.txt"
IPSET_RESTORE_FILE="/tmp/ipset_restore.txt"


# Ficheiros de Produção (Logs e Splunk)
LOG_FILE="/opt/splunk/var/log/splunk/ban_script.log"
SPLUNK_LOOKUP_FILE="/opt/splunk/etc/apps/search/lookups/ips_a_banir.csv"


# Verificação de Lock
if [ -e "$LOCK_FILE" ]; then
    if kill -0 $(cat "$LOCK_FILE") 2>/dev/null; then
        echo "$(date): Script já em execução. Saindo." >> $LOG_FILE
        exit 1
    fi
fi
echo $$ > "$LOCK_FILE"

echo "************************************************************" >> $LOG_FILE
echo "$(date): Início ban_ip.sh (Modo: IPSET + SPLUNK UPDATE)" >> $LOG_FILE


# Download da Lista
if ! wget -qO "$TEMP_IP_FILE" "$IP_LIST_URL"; then
    echo "$(date): Erro fatal ao baixar lista de IPs." >> $LOG_FILE
    rm "$LOCK_FILE"
    exit 1
fi


# Preparar IPSet ** Performance Firewall **
echo "create $IPSET_NAME hash:ip hashsize 16384 -exist" > "$IPSET_RESTORE_FILE"
echo "flush $IPSET_NAME" >> "$IPSET_RESTORE_FILE"


# Limpa e valida os IPs antes de adicionar
grep -Eo '([0-9]{1,3}\.){3}[0-9]{1,3}' "$TEMP_IP_FILE" | while read IP; do
    echo "add $IPSET_NAME $IP -exist" >> "$IPSET_RESTORE_FILE"
done


# Aplicar no Firewall
# Requer regra no sudoers para o user splunk
sudo /sbin/ipset restore < "$IPSET_RESTORE_FILE"


# Salvar persistência
sudo /usr/sbin/netfilter-persistent save > /dev/null 2>&1


# Atualizar lookups do Splunk para funcionar
# nos dashboards correspondentes

# Copia a lista limpa para onde o Splunk a lê
cp "$TEMP_IP_FILE" "$SPLUNK_LOOKUP_FILE"


# Garante que o cabeçalho dos Lookups tenham "ip" no CSV, caso seja necessário. 
# Descomentar a linha abaixo caso necessário
# sed -i '1i ip' "$SPLUNK_LOOKUP_FILE"


# Ajustar permissões para garantir que o Splunk consegue ler
chmod 644 "$SPLUNK_LOOKUP_FILE"
chown splunk:splunk "$SPLUNK_LOOKUP_FILE"


# Relatório Final
COUNT=$(wc -l < "$TEMP_IP_FILE")
echo "$(date): Sucesso Total." >> $LOG_FILE
echo "$(date): Firewall IPSet atualizada com $COUNT IPs." >> $LOG_FILE
echo "$(date): Splunk Lookup atualizado em $SPLUNK_LOOKUP_FILE" >> $LOG_FILE


# Limpeza do sistema
rm "$LOCK_FILE"
rm "$TEMP_IP_FILE"
rm "$IPSET_RESTORE_FILE"