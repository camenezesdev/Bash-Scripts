#!/bin/bash

# ********************************************
# 	 Hardening para SSH + Kernel + 
# 	    Fail2ban + Geo-Block UFW
#         Seguro para rodar em produção 
# 	      NÃO derruba sessão SSH.
# 	    Carlos 'Snake' Menezes
#   [Megabyte Security Labs] - VoRTeX Corp.
# ********************************************


# *******************************************
# *     CONFIGURE O IP PÚBLICO AQUI         *
# *******************************************
MEU_IP=""

# *******************************************
# *	      1. Hardening SSH		    *
# *******************************************
echo "[x] Aplicando hardening ao SSH…"

sudo cp /etc/ssh/sshd_config /etc/ssh/sshd_config.bak

sudo tee /etc/ssh/sshd_config >/dev/null <<EOF
# --- SECURITY HARDENING ---
Subsystem       sftp    /usr/lib/openssh/sftp-server
IgnoreRhosts yes
IgnoreUserKnownHosts no
StrictModes yes
PubkeyAuthentication yes
PermitRootLogin no
PermitEmptyPasswords no
PasswordAuthentication no
ChallengeResponseAuthentication no
UsePAM yes
X11Forwarding no
AllowAgentForwarding no
AllowTcpForwarding no
MaxAuthTries 3
LoginGraceTime 20
PrintMotd no
# Mantém a porta padrão para evitar travar sessões
EOF

sudo systemctl restart ssh

echo "[OK] Hardening do SSH finalizado com sucesso."
echo


# *******************************************
# *     2. Hardening do Kernel (sysctl)     *
# *******************************************
echo "[x] Realizando hardening no Kernel…"

sudo tee -a /etc/sysctl.conf >/dev/null <<EOF

# *******************************************
# *        Hardening do Kernel              *
# *******************************************
net.ipv4.icmp_echo_ignore_all=1
net.ipv4.tcp_syncookies=1
net.ipv4.conf.all.rp_filter=1
net.ipv4.conf.default.rp_filter=1
net.ipv4.conf.all.accept_source_route=0
net.ipv4.conf.default.accept_source_route=0
net.ipv4.conf.all.arp_ignore=1
net.ipv4.conf.all.arp_announce=2
EOF

sudo sysctl -p

echo "[OK] Kernel Hardening finalizado com sucesso."
echo

# *******************************************
# *     3. Fail2Ban hardening               *
# *******************************************
echo "[x] Aplicando hadrening ao Fail2Ban…"

sudo tee /etc/fail2ban/jail.local >/dev/null <<EOF
[DEFAULT]
ignoreip = 127.0.0.1/8 192.168.0.0/16 $MEU_IP
bantime = 1h
findtime = 10m
maxretry = 5

[sshd]
enabled = true
port = ssh
filter = sshd
logpath = /var/log/auth.log
backend = systemd

# Jail contra atacantes reincidentes
[recidive]
enabled = true
filter = recidive
logpath = /var/log/fail2ban.log
bantime = 7d
findtime = 1d
maxretry = 5

# Proteção contra brute force mais agressivo e scanning
[sshd-dos]
enabled = true
filter = sshd
logpath = /var/log/auth.log
maxretry = 10
findtime = 30m
bantime = 1h
EOF

sudo systemctl restart fail2ban

echo "[OK] Fail2Ban reforçado com sucesso."
echo

# *******************************************
# *  4. GEO-BLOCK (paises banidos via UFW)  *
# *******************************************

echo "[x] Configurando Geo-Block no UFW…"

# Países de alto risco (Pode e deve ser sempre atualizada)
Paises_Banidos="cn ru kp ir ua br in pk tr vn"

sudo apt install -y xtables-addons-common geoip-database || true

# Regras de bloqueio
for pais in $Paises_Banidos; do
    echo "[+] Banindo país: $pais"
    sudo ufw deny from any country $pais >/dev/null 2>&1 || true
done

sudo ufw reload

echo "[OK] GEO-BLOCK realizado com sucesso."
echo

# *******************************************
# *	        5. Finalização              *
# *******************************************


echo "*****************************************************"
echo "*      	HARDENING FINALIZADO COM SUCESSO          *"
echo "*****************************************************"
echo "SSH, Kernel, Fail2Ban e Geo-Block configurados."
echo "Seu servidor agora está muito mais protegido!"