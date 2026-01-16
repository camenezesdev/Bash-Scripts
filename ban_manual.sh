#!/bin/bash

# *******************************
#       Ban Script (v1.1)
# Carlos 'Snake' Menezes
# *******************************

# 1. Pedir o IP ao utilizador
read -p "Introduza o IP para banir: " banir_ip

# 2. Verificar se o IP não está vazio
if [ -z "$banir_ip" ]; then
    echo "Erro: Nenhum IP foi introduzido."
    exit 1
fi

# 3. Executar o banimento no UFW
# Usamos aspas duplas para a variável ser lida corretamente
sudo ufw insert 1 deny from "$banir_ip"

# 4. Feedback visual
echo "************************************************************"
echo "O IP $banir_ip foi inserido na BAN LIST  com sucesso."
echo "Terminando a rotina de ban e voltando ao posto de escuta."
echo "      Obrigado por usar o Ban Script v1.0 por Snake.        "
echo "         [Megabyte Security Labs] - VoRTeX Corp.            "
echo "************************************************************"