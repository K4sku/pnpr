#!/bin/bash

echo "Load environment variables from /etc/environment"
source /etc/environment

echo  "Starting services"
service ssh start
service redis-server start
/usr/local/bin/passenger-exporter &

echo "Making sure that the user has the correct permissions"
chmod g+x,o+x /home/webapp/webapp
chown -R webapp:webapp "/home/webapp" &

echo "Running all on_startup.d scripts"
for f in /home/webapp/on_startup.d/*; do
  echo "Running script: $f"
  chown -R webapp:webapp "$f"
  gosu webapp bash  "$f" || echo "Script failed: $f"
done

echo "Starting nginx and cron"
service cron start
service nginx start

echo "Application started at `date`"
tail -f /var/log/nginx/error.log
