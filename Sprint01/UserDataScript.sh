#!/bin/bash
# Atualiza o sistema, instala o Nginx e dependências adicionais.
sudo apt-get update -y; sudo apt-get upgrade -y; sudo apt-get install -y nginx curl cron unzip;

# Inicia e habilita o Nginx
sudo systemctl start nginx
sudo systemctl enable nginx

# Troca o Timezone para Brasil
sudo timedatectl set-timezone America/Sao_Paulo


# ------- Baixa Site para usar no Nginx -------

sudo curl -L "https://github.com/master-rogerio/CompassUol_PB_2025/raw/refs/heads/main/Sprint01/site.zip" -o "/tmp/site.zip"

sudo unzip -q -o "/tmp/site.zip" -d "/var/www/html/"

sudo rm -f "/tmp/site.zip"

# Ajusta Permissões
sudo chown -R www-data:www-data /var/www/html
sudo find /var/www/html -type d -exec chmod 755 {} \;
sudo find /var/www/html -type f -exec chmod 644 {} \;

##-------- Fim Site --------


# --- AWSCLI Config Install ----
# Baixa o instalador oficial AWSCLI
sudo curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "/tmp/awscliv2.zip"

# Descompacta
sudo unzip -q /tmp/awscliv2.zip -d /tmp

# Instala AWSCLI
sudo /tmp/aws/install --bin-dir /usr/local/bin --install-dir /usr/local/aws-cli --update

sudo rm -rf /tmp/aws /tmp/awscliv2.zip
## --------- FIM Configuração AWSCLI --------


## Cria SCRIPT de monitoramento Telegram
cat <<'EOF' > /usr/local/bin/monitor_site.sh
#!/bin/bash

aws configure set region us-east-1

TELEGRAM_BOT_TOKEN=$(aws ssm get-parameter --name "/telegram/bot_token" --with-decryption --query "Parameter.Value" --output text)
TELEGRAM_CHAT_ID=$(aws ssm get-parameter --name "/telegram/chat_id" --query "Parameter.Value" --output text)

# Configurações do Telegram
BOT_TOKEN="$TELEGRAM_BOT_TOKEN"
CHAT_ID="$TELEGRAM_CHAT_ID"
SITE_URL="http://$(curl -s https://checkip.amazonaws.com/)" # Busca Ip Publico

# Verifica resposta do site
response=$(curl -s -o /dev/null -w "%{http_code}" $SITE_URL)
timestamp=$(date "+%Y-%m-%d %H:%M:%S")

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
EOF


# Tornar o script executável
chmod +x /usr/local/bin/monitor_site.sh

## Configuração do cron job para executar a cada minuto
(crontab -l 2>/dev/null; echo "* * * * * /usr/local/bin/monitor_site.sh") | crontab -

# Mensagem final
echo "Configuração inicial concluída. Realizada pelo User Data em: $(date)" > /var/log/monitor_site.log