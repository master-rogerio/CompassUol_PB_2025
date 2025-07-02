#!/bin/bash

#Busca Parametros armazenados no Repositorio de Parametros AWS (IAM)
aws configure set region us-east-1
TELEGRAM_BOT_TOKEN=$(aws ssm get-parameter --name "/telegram/bot_token" --with-decryption --query "Parameter.Value" --output text)
TELEGRAM_CHAT_ID=$(aws ssm get-parameter --name "/telegram/chat_id" --query "Parameter.Value" --output text)

# Configurações do Telegram
BOT_TOKEN="$TELEGRAM_BOT_TOKEN"
CHAT_ID="$TELEGRAM_CHAT_ID"

SITE_URL="http://$(curl -s https://checkip.amazonaws.com/)" # Busca Ip Publico

response=$(curl -s -o /dev/null -w "%{http_code}" $SITE_URL) # Verifica resposta do site

timestamp=$(date "+%Y-%m-%d %H:%M:%S") #Variavel que armazena Data e Hora atual

if [ "$response" -eq 200 ]; then
    echo "[$timestamp] Site $SITE_URL está respondendo normalmente. Código: $response" >> /var/log/monitor_site.log
else
    echo "[$timestamp] ALERTA: $SITE_URL não está respondendo. Código: $response" >> /var/log/monitor_site.log
    
    # Envia mensagem para o Telegram
    message="🚨 *ALERTA DE MONITORAMENTO* 🚨
    
    O site está Offline!
    
	*IP:* $SITE_URL
    *Código HTTP:* $response
    *Hora:* $timestamp"
    
    curl -s -X POST \
        "https://api.telegram.org/bot$BOT_TOKEN/sendMessage" \
        -d chat_id="$CHAT_ID" \
        -d text="$message" \
        -d parse_mode="Markdown" >> /dev/null
fi



