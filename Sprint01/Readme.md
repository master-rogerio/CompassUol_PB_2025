# Sprint 01 - Projeto Linux com Servidor Web na AWS e Monitoramento Webhook com Telegram
###### Por Rogério Anastácio

## 📝 Descrição
<p align="justify">&nbsp;&nbsp;&nbsp;&nbsp; O objetivo desse projeto é implementar um sistema de monitoramento Web com notificações em tempo real. Aplicando os conhecimentos adquiridos em Linux, servidor web usando a estrutura AWS para hospedar os sistemas. É disponibilizado o relatório completo </p>
<br>
<p align="justify">&nbsp;&nbsp;&nbsp;&nbsp; A execução do projeto foi dividida em várias etapas: </p>

1. **Configuração do Ambiente**
   - Criação da VPC com 2 Sub-redes Públicas e 2 sub-redes privadas;
   - Adicionado ao Repositório de parâmetros as informações sensíveis (token e chat_id do telegram);
   - Criado perfil no IAM para acessar os parâmetros armazenados;
   - Configuração e criação de uma instância EC2 na AWS utiliazndo Linux (com uso das VPCs criadas).
2. **Configuração do Servidor Web**
   - Instalação do Nginx;
   - Carregada página HTML para o Nginx exibir.
3. **Script de Monitoramento com Webhook**
   - Criação do *Script Bash* com código responsável por verificar periodicamente o estado da página (Disponível / Indisponível);
   - Agendada rotina no Cron para executar o *script* a cada 60 segundos;
   - Disparo de mensagem pelo Script Bash para o Telegram avisando quando a página estiver indisponível.
4. **Testes**
   - Realização de testes para confirmar o correto funcionamento de toda a implementação.
5. **Desafio Bônus**
    - Criação de Script para ser inserido no campo "Dados de Usuário" durante a criação da instância EC2.
<br>

### [📄 Acesse aqui o **relatório** final e completo do projeto (em pdf).](documentacao.pdf)

<br><br>

## 📊 Diagrama de Arquitetura do Sistema

```mermaid
graph TD
    A[🔑 AWS Parameter Store] -->|Fornece credenciais| B[🛡️ IAM Role]
    B -->|Concede permissões| C[🖥️ EC2 Linux Ubuntu]
    C --> D[🕸️ Nginx]
    C --> E[🤖 Webhook Telegram]
    C --> F[📜 Script Bash]
    
    subgraph "Instância AWS EC2"
        D -->|Serve| G[📄 Página Web]
        E -->|Envia| H[📱 Notificações]
        F -->|Monitora| D
        F -->|Dispara| E
    end

    style A fill:#FF9900,color:#000
    style B fill:#232F3E,color:#FFF
    style C fill:#FF9900,color:#000

```
## Resumo do projeto:
### 1 Configuração do Ambiente
- VPC
   - Criação da *VPC* na AWS, com bloco IP CIDR/24;
   - Criação de duas sub-redes públicas com bloco IP CIDR/28;
   - Criação de duas sub-redes privadas com bloco IP CIDR/28;
   - Criado *Internet Gateway* e anexado à *VPC*
   - Configuração da tabela de rotas para direcionar todo tráfego de saída ao *internet gateway*
<br>

- Repositório de Parâmetros
     - Armazenamento dos parâmetros do Telegram referente ao *Token* do bot *(Secure String)* e *Chat ID (String)*.

 <br>

- *Identity and Acess Management* (IAM)
     - Criar política para associar os parâmetros do Telegram armazenados.
 
<br>

- EC2
   - Seção **Nome e Tags:** Adicionadas as Tags relacionadas ao projeto;
   - Seção **Imagens de aplicação e de sistema operacional:** Escolhido o Linux Ubuntu como Sistema Operacional;
   - Seção **Par de Chaves (Login):** Criado novo par de chaves (Realizado *download* da chave);
   - Seção **Configuração de Rede:** Seleção da VPC criada, com uma das sub-redes públicas. Habilitada atribuição de IP público automaticamente;
   - Subseção **Adicionar Regra de Grupo de Segurança:** Abertura das portas, no grupo de segurança (Firewall)
        - SSH: 22;
        - HTTP: 80;
        - HTTPS: 443.
   - Seção **Detalhes Avançados:**
        - Selecionar Perfil do IAM criado.
   -Finalzada as configurações: Executar a instância e aguardar inicialização do **Sistema Operacional**.

<br><br>

### 2 Configuração do Servidor Web
<p align="justify">&nbsp;&nbsp;&nbsp;&nbsp; Foi realizado o acesso à instância recém-configurada da AWS a partir de um sistema local com Debian, por meio de conexão SSH. A autenticação foi feita utilizando a chave privada gerada durante a configuração da instância, juntamente com o endereço IP público atribuído.</p><br>

- Instalação do Nginx: Instalado o Nginx utilizando o instalador de pacotes padrão *apt*;
   - Após a Instalação foi verificado se o serviço entrou em execução, caso necessário o serviço pode ser iniciado manualmente com `systemctl start nginx`.
   - Acessado o site padrão do Nginx usando o endereço de IP público da instância.
![Site Padrão Nginx](https://github.com/master-rogerio/CompassUol_PB_2025/blob/main/assets/s01-padraoNginx.jpg)
<br>

- Realizado a cópia do site com o `curl` para substituir a página padrão do Nginx e armazenado no repositório do **GitHub** e armazenado no diretório `/tmp/`.
  ```bash
  curl -L "https://github.com/master-rogerio/CompassUol_PB_2025/raw/refs/heads/main/Sprint01/site.zip" -o "/tmp/site.zip"
  ```
  - O arquivo copiado foi descompactado com o *unzip*. Após descompactar o site foi removido o arquivo copiado.
    ```bash
    unzip -q -o "/tmp/site.zip" -d "/var/www/html/"
    rm -f "/tmp/site.zip"
    ```
  - Foi alterado o dono e o grupo de todos os arquivos para o `www-data` (Usuário padrão do Nginx)
    ```bash
    chown -R www-data:www-data /var/www/html
    ```
  - Depois alterado a permissão de todos os diretórios do site para que usuário proprietário possa ler, gravar e executar. Enquanto o grupo outros usuários possam ler e executar.
    ```bash
    sudo find /var/www/html -type d -exec chmod 755 {} \;
    ```
  - Também foi alterado a permissão dos arquivos para que o proprietário possa ler e escrever enquanto os outros possam somente realizar a leitura.
    ```bash
    sudo find /var/www/html -type f -exec chmod 644 {} \;
    ```
    - Foi acessado novamente o site com o ip público da instância EC2 para verificar se o site que foi inserido já passou a ser disponibilizado pelo Nginx.
<br>
   
  ![Site Feito](https://github.com/master-rogerio/CompassUol_PB_2025/blob/main/assets/s01-padraoFeito.jpg)

### 3 Script de Monitoramento com Webhook
   - O script de monitoramento `monitor_site.sh`, foi armazenado em `/usr/local/bin/`, é usado para verificar a disponibilidade do site.
   ```bash
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

   ```
<b>

   - Esse script verifica se o site está disponível fazendo a requisição do código http do site com o`curl`. Se retornado o código *200* significa que o site está online e caso contrário significa o oposto e assim é enviado mensagem pelo *bot do Telegram* avisando dessa indisponibilidade. Esse script faz escrita no log a cada 60 segundos, com o código http obtido.
   - O *Cron* é utilizado para agendar a execução do script, sendo chamado por `crontab -e`. Foi escrito o seguinte código nele:
   ```
      * * * * * /usr/local/bin/monitor_site.sh"
   ```

<b>

### 4 Testes
<p align="justify">&nbsp;&nbsp;&nbsp;&nbsp; Para verificar se tudo funcionava conforme necessário. Inicialmente foi verificado se o script `monitor_site.sh` estava escrevendo no log, armazenado em ´var/log` com o nome de `monitor_site.log`, uma vez por minuto.</p><br>

### 5 Desafio Bônus
<p align="justify">&nbsp;&nbsp;&nbsp;&nbsp; Foi realizado o acesso à instância recém-configurada da AWS a partir de um sistema local com Debian, por meio de conexão SSH. A autenticação foi feita utilizando a chave privada gerada durante a configuração da instância, juntamente com o endereço IP público atribuído.</p><br>



## Tecnologias Utilizadas
* Cron
* Linux Ubuntu 24.04
* Nginx (Servidor Web)
* Script Bash
* Serviços de Computação em nuvem AWS (EC2, IAM, Gerenciador de Parâmetros, VPC)
* Telegram Webhook (Bot)

