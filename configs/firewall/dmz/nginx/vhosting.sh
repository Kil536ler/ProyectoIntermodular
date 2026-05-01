#!/bin/bash

# Este script ha sido desarrollado Izan

# La idea de este script es que sea lo mas maleable posible
# para que cada persona que necesite utilizarlo pueda instalar
# lo necesario y solo eso
# jeje, god

# La manera de utilizarlo es comentar aquellas lineas indicadas
# para dejar de hacer ciertas tareas por ejemplo

# Comment this line if you want to unable sftp configuration
# Uncomment this line if you want to enable sftp configuration

# sftp_configuration

# la linea sftp_configuration la deberiamos comentar o no según nuestro interes

# 

################################################################################################

LRED="\e[91m"
LGREEN="\e[92m"
LYELLOW="\e[93m"
LBLUE="\e[94m"
LMAGENTA="\e[95m"
LCYAN="\e[96m"
LGREY="\e[97m"
BOLD="\e[1m"
RESET="\e[0m"
apt purge apache2 >/dev/null 2>&1
apt install nginx >/dev/null 2>&1

# Execution checkers & Basic functions
execute_flag_ssk=0
function passwd-check() {
        if [[ "$passwd" == "$passwd2" ]]; then
                return 0
        else
                return 1
        fi
}
function test-email() {
        local validezemail="^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$"

        if [[ "$email" =~ $validezemail ]]; then
                return 0
        else
                return 1
        fi
}

# Script
function newcomer() {
    clear
    echo -e "$LMAGENTA"
    echo -e "Bienvenido a el script modular de VHOSTING con SFTP hecho por tu it de confis: izan$RESET"
    echo -e "Por favor escriba su nombre de usuario"
    read -p ">" user

    while true; do
        unset passwd
        unset passwd2
        echo -n "Introduzca su contraseña: "
        stty -echo
        PROMPT=""
        CHARCOUNT=0
            while IFS= read -p "$PROMPT" -r -s -n 1 CHAR
            do
                if [[ $CHAR == $'\0' ]] ; then
                    break
                fi
                if [[ $CHAR == $'\177' ]] ; then
                    if [ $CHARCOUNT -gt 0 ] ; then
                        CHARCOUNT=$((CHARCOUNT-1))
                        PROMPT=$'\b \b'
                        passwd="${passwd%?}"
                    else
                        PROMPT=''
                    fi
                elif [[ $CHAR == $'\n' ]] ; then
                    break
                else
                    CHARCOUNT=$((CHARCOUNT+1))
                    PROMPT='*'
                    passwd+="$CHAR"
                fi
            done
            echo
            echo -n "Vuelve a introducir la contraseña: "
            PROMPT=""
            CHARCOUNT=0
            while IFS= read -p "$PROMPT" -r -s -n 1 CHAR
            do
                if [[ $CHAR == $'\0' ]] ; then
                    break
                fi
                if [[ $CHAR == $'\177' ]] ; then
                    if [ $CHARCOUNT -gt 0 ] ; then
                        CHARCOUNT=$((CHARCOUNT-1))
                        PROMPT=$'\b \b'
                        passwd2="${passwd2%?}"
                    else
                        PROMPT=''
                    fi
                else
                    CHARCOUNT=$((CHARCOUNT+1))
                    PROMPT='*'
                    passwd2+="$CHAR"
                fi
            done
        passwd-check
        if [ $? -eq 0 ]; then
            stty echo
            echo
            break
        else
            echo
            echo "La contraseña que has escrito no es correcta, por favor escribela de nuevo."
        fi
    done
    
    # MODIFICADO: Usuario sin shell para cumplir RFTP (R05F01T01)
    useradd -d /var/www/$domain -s /usr/sbin/nologin "$user" >>/dev/null 2>&1
    passwd "$user" <<< "$passwd"$'\n'$passwd >>/dev/null 2>&1
       
    echo -e " Cual es tu dominio?"
    read -p ">" domain

    while true; do
        echo "Por favor escriba su email: "
        read email

        test-email "$email"
        if [ $? -eq 0 ]; then
                break
        else
                echo "El e-mail que has escrito no es correcto, por favor escribalo de nuevo."
        fi
    done
    
    # Directory creation
    mkdir -p /var/www/$domain/html
}

function buffer_bucket(){
    echo "user www-data;
worker_processes auto;
pid /run/nginx.pid;
error_log /var/log/nginx/error.log;
include /etc/nginx/modules-enabled/*.conf;

events {
	worker_connections 768;
	# multi_accept on;
}

http {

	##
	# Basic Settings
	##

	sendfile on;
	tcp_nopush on;
	types_hash_max_size 2048;
	# server_tokens off;

	server_names_hash_bucket_size 64;
	# server_name_in_redirect off;

	include /etc/nginx/mime.types;
	default_type application/octet-stream;

	##
	# SSL Settings
	##

	ssl_protocols TLSv1 TLSv1.1 TLSv1.2 TLSv1.3; # Dropping SSLv3, ref: POODLE
	ssl_prefer_server_ciphers on;

	##
	# Logging Settings
	##

	access_log /var/log/nginx/access.log;

	##
	# Gzip Settings
	##

	gzip on;

	##
	# Virtual Host Configs
	##

	include /etc/nginx/conf.d/*.conf;
	include /etc/nginx/sites-enabled/*;
}
" > /etc/nginx/nginx.conf
}

function sftp_configuration() {
    # MODIFICADO: Permisos adaptados estrictamente para vsftpd (chroot)
    chown root:root /var/www/$domain
    chmod 755 /var/www/$domain
    chown $user:$user /var/www/$domain/html
}

function ssl_ssk() {
    openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout "/etc/ssl/private/$domain.key" -out "/etc/ssl/certs/$domain.crt" -subj "/C=ES/ST=Catalunya/L=Barcelona/O=IJR & Moska Trust Services/OU=IJR & Moska Trust Services/CN=$domain/emailAddress=$email"
    execute_flag_ssk=1
}

function vhost_http_server_config() {
    echo -e "
    server {
        listen 80;
        listen [::]:80;

        root /var/www/$domain/html;
        index index.html index.htm index.nginx-debian.html;

        server_name $domain www.$domain;

        location / {
                try_files \$uri \$uri/ =404;
        }

    }" > /etc/nginx/sites-enabled/$domain
    cp /etc/nginx/sites-enabled/$domain /etc/nginx/sites-available/
    echo -e "<!DOCTYPE html>
    <html lang="es">
        <body>
            <h1>Bienvenido a tu dominio!</h1>
            <p>Esta es la pagina default de $user, 
            para editar tu pagina web entra por SFTP.</p>
        </body>
    </html>" > /var/www/$domain/html/index.html
}

function vhost_https_server_config() {
    echo -e "
    server {
        listen 443 ssl;
        listen [::]:443 ssl;
        ssl_certificate /etc/ssl/certs/$domain.crt;
        ssl_certificate_key /etc/ssl/private/$domain.key;
        include snippets/ssl-params.conf;

        root /var/www/$domain/html;
        index index.html index.htm index.nginx-debian.html;

        server_name $domain www.$domain;

        location / {
                try_files \$uri \$uri/ =404;
        }
    }
    server {
        listen 80;
        listen [::]:80;

        server_name $domain www.$domain;

        return 302 https://\$server_name\$request_uri;
    }" > /etc/nginx/sites-available/$domain
    cp /etc/nginx/sites-available/$domain /etc/nginx/sites-enabled/
    echo -e "<!DOCTYPE html>
    <html lang="es">
        <title>DHM S.L</title>
        <body>
            <h1>Bienvenido a tu dominio!</h1>
            <p>Esta es la pagina default de $user, 
            para editar tu pagina web entra por SFTP.</p>
        </body>
    </html>" > /var/www/$domain/html/index.html

    echo -e "
    ssl_protocols TLSv1.3;
    ssl_prefer_server_ciphers on;
    ssl_dhparam /etc/nginx/dhparam.pem; 
    ssl_ciphers EECDH+AESGCM:EDH+AESGCM;
    ssl_ecdh_curve secp384r1;
    ssl_session_timeout  10m;
    ssl_session_cache shared:SSL:10m;
    ssl_session_tickets off;
    ssl_stapling on;
    ssl_stapling_verify on;
    resolver 8.8.8.8 8.8.4.4 valid=300s;
    resolver_timeout 5s;
    add_header X-Frame-Options DENY;
    add_header X-Content-Type-Options nosniff;
    add_header X-XSS-Protection \"1; mode=block\";
    " > /etc/nginx/snippets/ssl-params.conf
    
    # Genera dhparam.pem si no existe para evitar errores
    if [ ! -f /etc/nginx/dhparam.pem ]; then
        openssl dhparam -out /etc/nginx/dhparam.pem 2048
    fi
} 

# Zona del script modular

# User and passwd creation
newcomer
# Creation of an sftp user and password
buffer_bucket
sftp_configuration
# Creation of a self-signed certificate
ssl_ssk
# Do not comment this lines (automatic detection of https or http server, it will act based on if ssl_ssk is commented out)
if [ "$execute_flag_ssk" -eq 1 ]; then
        vhost_https_server_config
    else
        vhost_http_server_config
fi

# MODIFICADO: Reiniciar vsftpd en lugar de sshd
systemctl restart nginx vsftpd
nginx -t
