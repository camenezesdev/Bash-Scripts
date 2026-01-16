#!/bin/bash 

# ********************************************
# 	  Live Check - Somente NGINX
#    Consome menos recursos que o SOC Master
# 	    Carlos 'Snake' Menezes
#   [Megabyte Security Labs] - VoRTeX Corp.
# ********************************************

#sudo tail -f /var/log/nginx/access.log | awk '{ status=$9; color="\033[0m"; if (status ~ /^2/) color="\033[32m"; else if (status ~ /^3/) color="\033[36m"; else if (status ~ /^4/) color="\033[31m"; else if (status ~ /^5/) color="\033[35m";
#timestamp="\033[33m[" strftime("%Y-%m-%d %H:%M:%S") "]\033[0m"; $9 = color status "\033[0m";
#print timestamp, $1, $6, $7, $11 }'

sudo tail -f /var/log/nginx/access.log | awk '{ status=$9; color="\033[0m"; if (status ~ /^2/) color="\033[32m"; else if (status ~ /^3/) color="\033[36m"; else if (status ~ /^4/) color="\033[31m"; else if (status ~ /^5/) color="\033[35m";

timestamp="\033[33m[" strftime("%Y-%m-%d %H:%M:%S") "]\033[0m"; st_colorido = color status "\033[0m";

print timestamp, "IP:", $1, "ST:", st_colorido, "MET:", $6, "PATH:", $7, "REF:", $11 }'


