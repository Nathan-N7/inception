#!/bin/bash

G='\033[0;32m'
R='\033[0;31m'
NC='\033[0m'

execute_test() {
    comando="$1"
    mensagem="$2"

    eval "$comando" > /dev/null 2>&1
    
    status_do_comando=$?

    if [ $status_do_comando -eq 0 ]; then
        echo -e "${G}[PASS]${NC} -- $mensagem"
    else
        echo -e "${R}[FAIL]${NC} -- $mensagem"
    fi
}

echo -e "\n=== 42 INCEPTION: LIMPEZA PRELIMINAR (REGRA OFICIAL) ==="
docker stop $(docker ps -qa) 2>/dev/null; docker rm $(docker ps -qa) 2>/dev/null; \
docker rmi -f $(docker images -qa) 2>/dev/null; docker volume rm $(docker volume ls -q) 2>/dev/null; \
docker network rm $(docker network ls -q) 2>/dev/null

echo -e "\n=== 42 INCEPTION: CONSTRUINDO O PROJETO VIA MAKEFILE ==="
make > /dev/null 2>&1
if [ $? -ne 0 ]; then
    echo -e "${R}[ERRO FATAL]${NC} O comando 'make' falhou."
    exit 1
fi
echo -e "${G}[OK]${NC} Build finalizado. Aguardando 10 segundos..."
sleep 10

echo -e "\n=== 42 INCEPTION: TECH CHECKER FINAL ==="

source srcs/.env 2>/dev/null
LOGIN=$(echo $DOMAIN_NAME | cut -d '.' -f 1)
DOMAIN="${LOGIN}.42.fr"

echo -e "\n1. ESTRUTURA DO PROJETO"
execute_test "test -f Makefile"                "Makefile presente na raiz"
execute_test "test -d srcs"                    "Diretório srcs presente"
execute_test "test -f srcs/docker-compose.yml" "docker-compose.yml presente"

echo -e "\n2. REGRAS PROIBIDAS E SEGURANÇA"
execute_test "! grep -q 'network: host' srcs/docker-compose.yml" "Sem network: host"
execute_test "! grep -q 'links:' srcs/docker-compose.yml"        "Sem links"
execute_test "grep -q 'networks:' srcs/docker-compose.yml"       "Docker network declarada no compose"
execute_test "! grep -rq -- '--link' srcs/"                      "Sem flag --link nos scripts"
execute_test "! grep -rqE 'sleep infinity|tail -f|while true' srcs/" "Sem loops ou hacks de background"
execute_test "! grep -rniE 'password *= *\"[^$].*\"' srcs/requirements/" "Sem senha hardcoded"

echo -e "\n3. VALIDAÇÃO DOS DOCKERFILES"
for svc in nginx wordpress mariadb; do
    DF="srcs/requirements/$svc/Dockerfile"
    execute_test "test -s $DF"                                    "Dockerfile de $svc existe"
    execute_test "grep -qiE '^FROM.*(alpine|debian)' $DF"         "$svc usa base Alpine ou Debian"
    execute_test "! grep -qi ':latest' $DF"                       "$svc não usa tag :latest"
done
execute_test "! grep -qi 'nginx' srcs/requirements/wordpress/Dockerfile srcs/requirements/mariadb/Dockerfile" "NGINX isolado (não está no WP/DB)"

echo -e "\n4. CONTAINERS E IMAGENS"
execute_test "grep -q 'build:' srcs/docker-compose.yml" "Imagens construídas via Dockerfile local"
for svc in nginx wordpress mariadb; do
    execute_test "docker compose -f srcs/docker-compose.yml ps | grep -q $svc" "$svc gerenciado pelo Compose"
    execute_test "docker ps --format '{{.Names}}' | grep -q '^$svc$'"         "Container $svc em execução"
    execute_test "docker images --format '{{.Repository}}' | grep -q '^$svc$'" "Imagem $svc com nome correto"
done

echo -e "\n5. PORTAS E ISOLAMENTO"
execute_test "docker inspect nginx --format '{{range \$p,\$v := .NetworkSettings.Ports}}{{\$p}} {{end}}' | grep -q '443/tcp'" "NGINX: Porta 443 aberta"
execute_test "! docker inspect nginx --format '{{range \$p,\$v := .NetworkSettings.Ports}}{{\$p}} {{end}}' | grep -q '80/tcp'"  "NGINX: Porta 80 fechada"
execute_test "! docker ps --format '{{.Names}} {{.Ports}}' | grep '^wordpress' | grep -q ':'" "WordPress: Sem portas expostas ao host"
execute_test "! docker ps --format '{{.Names}} {{.Ports}}' | grep '^mariadb' | grep -q ':'"   "MariaDB: Sem portas expostas ao host"
execute_test "docker network ls | grep -q inception" "Rede inception visível"

echo -e "\n6. NGINX + WORDPRESS"
execute_test "curl -k -s -o /dev/null -w '%{http_code}' https://$DOMAIN | grep -qE '200|301|302'" "HTTPS operacional (443)"
execute_test "curl -s -o /dev/null -w '%{http_code}' http://$DOMAIN | grep -qE '000|301'"       "HTTP bloqueado ou redirecionado"
execute_test "echo Q | openssl s_client -connect $DOMAIN:443 -tls1_2 -servername $DOMAIN || echo Q | openssl s_client -connect $DOMAIN:443 -tls1_3 -servername $DOMAIN" "TLS 1.2 ou 1.3 ativo"
execute_test "! curl -k -s https://$DOMAIN | grep -q 'WordPress.*Installation'" "WordPress configurado (sem tela de instalação)"
execute_test "docker exec wordpress pgrep php-fpm" "PHP-FPM em execução"

echo -e "\n7. MARIADB E BANCO DE DADOS"
DB_PASS=$(docker exec mariadb cat /run/secrets/db_password 2>/dev/null || echo $MYSQL_PASSWORD)
MYSQL="docker exec mariadb mysql -u$MYSQL_USER -p$DB_PASS $MYSQL_DATABASE"
execute_test "$MYSQL -se 'SHOW TABLES;' | grep -q ." "Banco de dados populado"
execute_test "! $MYSQL -se 'SELECT user_login FROM wp_users WHERE user_login LIKE \"%admin%\";' | grep -q ." "Admin sem 'admin' no nome"
execute_test "test $($MYSQL -se 'SELECT COUNT(*) FROM wp_users;') -ge 2" "WordPress com 2 ou mais usuários"

echo -e "\n8. VOLUMES E PERSISTÊNCIA"
for vol in $(docker volume ls -q | grep -E 'wordpress|mariadb|db|wp'); do
    DEV=$(docker volume inspect $vol --format '{{index .Options "device"}}' 2>/dev/null)
    execute_test "echo $DEV | grep -q /home/$LOGIN/data" "Volume $vol mapeado em /home/$LOGIN/data"
done

echo test > /home/$LOGIN/data/wordpress/persist.txt
docker compose -f srcs/docker-compose.yml restart >/dev/null 2>&1
sleep 5
execute_test "test -f /home/$LOGIN/data/wordpress/persist.txt" "Dados persistiram após restart"
rm -f /home/$LOGIN/data/wordpress/persist.txt

echo -e "\n=== TESTES TÉCNICOS FINALIZADOS ===\n"