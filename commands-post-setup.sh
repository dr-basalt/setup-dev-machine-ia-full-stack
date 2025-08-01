# Vérifier services
systemctl status code-server@developer
systemctl status nginx
docker ps

# Logs
journalctl -fu code-server@developer
tail -f /var/log/nginx/access.log

# Restart services
systemctl restart code-server@developer
docker-compose restart
