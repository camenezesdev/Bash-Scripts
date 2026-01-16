#!/bin/bash

# ********************************************
#    Monitorização em tempo real: Nginx, SSH 
#		  e Postfix
# 	    Carlos 'Snake' Menezes
#   [Megabyte Security Labs] - VoRTeX Corp.
# ********************************************

sudo tail -f /var/log/nginx/access.log /var/log/auth.log /var/log/mail.log | awk '
/==> / {
    if ($0 ~ /access.log/) { source="[NGINX]"; color_src="\033[36m" }
    else if ($0 ~ /auth.log/) { source="[SSH]"; color_src="\033[35m" }
    else if ($0 ~ /mail.log/) { source="[MAIL]"; color_src="\033[33m" }
    else if ($0 ~ /honeypot.log/) { source="[HONEY]"; color_src="\033[1;31;40m" }
    next
}

{
    # Evita linhas vazias
    if ($1 == "" || NF < 3) next;

    ts="\033[33m[" strftime("%H:%M:%S") "]\033[0m";

# ***************************
# Logica do monitor do NGinx
# ***************************
    if (source == "[NGINX]") {
        status=$9;
        color_st="\033[0m";
        if (status ~ /^2/) color_st="\033[32m";
        else if (status ~ /^3/) color_st="\033[34m";
        else if (status ~ /^4/) color_st="\033[31m";
        else if (status ~ /^5/) color_st="\033[35m";

        metodo=$6; gsub(/"/, "", metodo);
        print ts, color_src source "\033[0m", "IP:", $1, "ST:", color_st status "\033[0m", "MET:", metodo, "PATH:", $7
    }

# *************************
# Logica de Monitor de SSH
# *************************
    else if (source == "[SSH]") {
        if ($0 ~ /sshd/ && ($0 ~ /Accepted/ || $0 ~ /Failed/ || $0 ~ /Invalid/)) {
            event_color=($0 ~ /Accepted/) ? "\033[32m" : "\033[31m";
            match($0, /[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+/);
            ip=substr($0, RSTART, RLENGTH);
            msg=($0 ~ /Accepted/) ? "SUCCESS" : "FAILED/INVALID";
            print ts, color_src source "\033[0m", "IP:", ip, "EVENT:", event_color msg "\033[0m", "USER:", $9
        }
    }

# ************************
# Logica de Deny de mail
# ************************
    else if (source == "[MAIL]") {
        if ($0 ~ /reject:/) {
            match($0, /[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+/);
            ip=substr($0, RSTART, RLENGTH);
            print ts, "\033[1;31m" source "\033[0m", "IP:", ip, "EVENT:", "\033[31mRELAY_REJECTED\033[0m", "DATA:", $0
        }
}
# *******************************
# Logica de allow de Email
# *******************************
    else if ($0 ~ /status=sent/ || $0 ~ /status=deferred/) {
            event_color=($0 ~ /sent/) ? "\033[32m" : "\033[33m";
            msg=($0 ~ /sent/) ? "SUCCESS_MAIL" : "DEFERRED";
            print ts, color_src source "\033[0m", "EVENT:", event_color msg "\033[0m", "TO:", $7
        }
# ***************************
# Logica do Honeypot port 22
# ***************************
    if (source == "[HONEY]") {
        # Deteta tentativas de login ou comandos no Honeypot
        event_color="\033[1;31;5m"; # Vermelho a piscar (se o terminal suportar)
        match($0, /[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+/);
        ip=substr($0, RSTART, RLENGTH);
        print ts, color_src source "\033[0m", "\033[1;31m!!! ALERTA DE INTRUSÃO !!!\033[0m", "IP:", ip, "DATA:", $0
    }
}'
