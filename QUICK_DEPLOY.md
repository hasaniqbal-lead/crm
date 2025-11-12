# Quick Deployment Guide

## 🚀 3-Step Deployment to VATRIX Server

### Step 1: Transfer Deployment Script to Server

```bash
# From your local machine
scp deploy.sh root@161.97.134.76:/root/
```

### Step 2: SSH into Server

```bash
ssh root@161.97.134.76
```

### Step 3: Run Deployment Script

```bash
cd /root
bash deploy.sh
```

The script will:
- ✅ Install all dependencies (Ruby, PostgreSQL, Redis, Nginx)
- ✅ Clone and setup your application
- ✅ Create and configure database
- ✅ Setup systemd services
- ✅ Configure Nginx reverse proxy
- ✅ Start the application

**Total time: ~10-15 minutes**

---

## 🧪 Testing After Deployment

### Test Health Check

```bash
curl http://161.97.134.76/up
# Should return: {"status":"ok"}
```

### Test Login API

```bash
curl -X POST http://161.97.134.76/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "admin@acme.com",
    "password": "password123"
  }'
```

### Test Unified Inbox (with token)

```bash
# Copy access_token from login response
curl -X GET http://161.97.134.76/api/v1/accounts/1/conversations \
  -H "Authorization: Bearer YOUR_ACCESS_TOKEN"
```

---

## 📊 Manage Your Application

### Check Application Status

```bash
systemctl status crm-web
systemctl status crm-sidekiq
```

### View Live Logs

```bash
# Application logs
journalctl -u crm-web -f

# Background jobs logs
journalctl -u crm-sidekiq -f

# Rails logs
tail -f /var/www/crm/log/production.log
```

### Restart Application

```bash
systemctl restart crm-web
systemctl restart crm-sidekiq
```

### Update Application

```bash
cd /var/www/crm
git pull origin claude/repo-review-011CV3n3rMMGxbegxbgygix9
bundle install --deployment
RAILS_ENV=production bundle exec rails db:migrate
systemctl restart crm-web crm-sidekiq
```

---

## 🔐 Important Information

### Server Access

- **IP:** 161.97.134.76
- **Application URL:** http://161.97.134.76
- **API Base:** http://161.97.134.76/api/v1

### Test Credentials

- **Email:** admin@acme.com
- **Password:** password123

### Database

- **Name:** crm_production
- **User:** crm_user
- **Password:** (shown during deployment - save it!)

### File Locations

- **Application:** /var/www/crm
- **Environment:** /var/www/crm/.env
- **Logs:** /var/www/crm/log/production.log
- **Nginx Config:** /etc/nginx/sites-available/crm

---

## 🛟 Troubleshooting

### Application Won't Start

```bash
# Check logs for errors
journalctl -u crm-web -n 100

# Check if database is running
systemctl status postgresql

# Check if Redis is running
systemctl status redis-server

# Test manually
cd /var/www/crm
RAILS_ENV=production bundle exec rails console
```

### Can't Connect to Application

```bash
# Check if Nginx is running
systemctl status nginx

# Test Nginx configuration
nginx -t

# Check if application is listening
netstat -tulpn | grep 3000

# Check firewall
ufw status
```

### Database Connection Error

```bash
# Verify credentials in .env
cat /var/www/crm/.env | grep DATABASE

# Test database connection
sudo -u postgres psql -d crm_production

# Check PostgreSQL logs
tail -f /var/log/postgresql/postgresql-*.log
```

---

## 🔄 Next Steps After Deployment

### 1. Configure SSL/HTTPS (Recommended)

```bash
apt-get install certbot python3-certbot-nginx
# If you have a domain:
certbot --nginx -d yourdomain.com
```

### 2. Add Social Media API Keys

Edit `/var/www/crm/.env` and add:

```bash
WHATSAPP_CLOUD_API_ACCESS_TOKEN=your_key_here
FB_APP_ID=your_app_id
FB_APP_SECRET=your_app_secret
INSTAGRAM_VERIFY_TOKEN=your_token_here
```

Then restart:

```bash
systemctl restart crm-web
```

### 3. Configure Webhooks

Point your social media webhooks to:

- **WhatsApp:** `http://161.97.134.76/webhooks/YOUR_PHONE_NUMBER`
- **Facebook:** `http://161.97.134.76/webhooks/facebook`
- **Instagram:** `http://161.97.134.76/webhooks/instagram`

### 4. Setup Monitoring

```bash
# Install monitoring tools
apt-get install htop iotop

# View resource usage
htop

# Check disk space
df -h

# Monitor logs
tail -f /var/www/crm/log/production.log
```

### 5. Setup Automated Backups

```bash
# Create backup script
nano /root/backup-crm.sh
```

Add:

```bash
#!/bin/bash
BACKUP_DIR="/root/backups"
DATE=$(date +%Y%m%d_%H%M%S)

mkdir -p $BACKUP_DIR

# Backup database
sudo -u postgres pg_dump crm_production > $BACKUP_DIR/db_$DATE.sql

# Backup application files
tar -czf $BACKUP_DIR/app_$DATE.tar.gz /var/www/crm

# Keep only last 7 days
find $BACKUP_DIR -name "*.sql" -mtime +7 -delete
find $BACKUP_DIR -name "*.tar.gz" -mtime +7 -delete

echo "Backup completed: $DATE"
```

Make executable and add to cron:

```bash
chmod +x /root/backup-crm.sh
crontab -e
# Add: 0 2 * * * /root/backup-crm.sh
```

---

## 📚 Full Documentation

For detailed information, see:
- **DEPLOYMENT.md** - Complete deployment guide
- **API_DOCUMENTATION.md** - API reference (100+ endpoints)
- **JWT_AUTHENTICATION.md** - Authentication guide
- **DATABASE_SCHEMA.md** - Database reference

---

## ✅ Deployment Checklist

- [ ] Run deployment script
- [ ] Test health endpoint
- [ ] Test login API
- [ ] Test authenticated endpoints
- [ ] Add social media API keys
- [ ] Configure webhooks
- [ ] Setup SSL certificate
- [ ] Configure backups
- [ ] Setup monitoring
- [ ] Change default passwords
- [ ] Review security settings

---

**Need Help?**
Check logs: `journalctl -u crm-web -f`
