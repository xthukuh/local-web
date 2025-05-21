#!/bin/bash
# sudo ./backup-restore.sh

echo "[~] Backup restore..."
echo "[+] composer down..."
docker compose down

echo "[*] Restore mysql..."
docker run --rm -v local_mysql:/var/lib/mysql -v $(pwd)/docker/backup/mysql:/backup busybox sh -c "rm -rf /var/lib/mysql/* && cp -r /backup/* /var/lib/mysql"

echo "[*] Restore phpmyadmin..."
docker run --rm -v local_phpmyadmin:/etc/phpmyadmin -v $(pwd)/docker/backup/phpmyadmin:/backup busybox sh -c "rm -rf /etc/phpmyadmin/* && cp -r /backup/* /etc/phpmyadmin"

echo "[*] Restore hosts..."
sudo cp -puf $(pwd)/docker/backup/hosts /mnt/c/Windows/System32/Drivers/etc/hosts

echo "[+] done!"