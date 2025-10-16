#!/bin/bash
# sudo ./backup-copy.sh

echo "[~] Backup copy..."
echo "[*] composer down..."
docker compose down

echo "[*] Copy mysql..."
docker run --rm -v local_mysql:/var/lib/mysql -v $(pwd)/docker/backup/mysql:/backup busybox sh -c "cp -r /var/lib/mysql/* /backup"

echo "[*] Copy phpmyadmin..."
docker run --rm -v local_phpmyadmin:/etc/phpmyadmin -v $(pwd)/docker/backup/phpmyadmin:/backup busybox sh -c "cp -r /etc/phpmyadmin/* /backup"

echo "[*] Copy hosts..."
cp -puf /mnt/c/Windows/System32/Drivers/etc/hosts $(pwd)/docker/backup/hosts

pwd=$(pwd)
now=$(date +"%Y%m%d-%H%M%S")
file=local-web-docker-$now.zip
echo "[*] Archive $file..."
cd $pwd/docker
zip -rq $pwd/$file .
cd $pwd
zipinfo -h $file

echo "[+] done!"
