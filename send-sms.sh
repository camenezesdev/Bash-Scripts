#!/bin/bash
# ********************************************
# Script para enviar SMS ao detetar Login SSH)
# 	    Carlos 'Snake' Menezes
#   [Megabyte Security Labs] - VoRTeX Corp.
# ********************************************
# Script para enviar SMS ao detetar Login SSH
# Autor: Carlos 'Snake' Menezes
# Megabyte Security Labs

# Dados Conta Twilio
SID_CONTA=""
AUTH_TOKEN=""
NUMERO_TWILLIO=""
MEU_NUMERO="" 

# Captura dados do login
SNAKE_USER=${PAM_USER:-$USER}
SNAKE_RHOST=${PAM_RHOST:-$(echo $SSH_CONNECTION | cut -d " " -f 1)}
#USER_LOGIN=$USER
#IP_LOGIN=$(echo $SSH_CONNECTION | cut -d " " -f 1)
DATA=$(date '+%d/%m/%Y %H:%M')

# Mensagem o mais curta possível
MENSAGEM="[SOC] Login detectado: $SNAKE_USER via $SNAKE_RHOST em $DATA. - Megabyte Server"

# Envio via API Twilio
curl -X POST "https://api.twilio.com/2010-04-01/Accounts/$SID_CONTA/Messages.json" \
--data-urlencode "Body=$MENSAGEM" \
--data-urlencode "From=$NUMERO_TWILLIO" \
--data-urlencode "To=$MEU_NUMERO" \
-u "$SID_CONTA:$AUTH_TOKEN" > /dev/null 2>&1
