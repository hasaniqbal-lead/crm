# Deployment Guide - VATRIX Server

Complete guide to deploy the CRM application to your VATRIX server.

## 📋 Server Information

- **IP Address:** 161.97.134.76
- **Hostname:** vmi2897296.contaboserver.net
- **Provider:** Contabo VPS
- **OS:** Ubuntu/Debian (assumed)

---

## 🚀 Quick Start

### Option 1: Automated Deployment Script (Recommended)

```bash
# On your local machine
scp deploy.sh root@161.97.134.76:/root/
ssh root@161.97.134.76
cd /root
bash deploy.sh
```

### Option 2: Manual Step-by-Step

Follow the detailed instructions below.

---

## 📦 Prerequisites

### 1. SSH into Your Server

```bash
ssh root@161.97.134.76
```

### 2. Update System

```bash
apt-get update
apt-get upgrade -y
```

### 3. Install Required Software

```bash
# Install essential packages
apt-get install -y curl git build-essential libssl-dev zlib1g-dev \
  libreadline-dev libyaml-dev libsqlite3-dev sqlite3 libxml2-dev \
  libxslt1-dev libcurl4-openssl-dev software-properties-common \
  libffi-dev nodejs yarn postgresql postgresql-contrib redis-server \
  nginx

# Install rbenv and ruby-build
git clone https://github.com/rbenv/rbenv.git ~/.rbenv
echo 'export PATH="$HOME/.rbenv/bin:$PATH"' >> ~/.bashrc
echo 'eval "$(rbenv init -)"' >> ~/.bashrc
source ~/.bashrc

git clone https://github.com/rbenv/ruby-build.git ~/.rbenv/plugins/ruby-build

# Install Ruby 3.3.6
rbenv install 3.3.6
rbenv global 3.3.6

# Verify Ruby installation
ruby -v  # Should show: ruby 3.3.6

# Install bundler
gem install bundler
```

---

## 🗄️ Database Setup

### PostgreSQL Configuration

```bash
# Switch to postgres user
sudo -u postgres psql

# In PostgreSQL prompt:
CREATE USER crm_user WITH PASSWORD 'your_secure_password_here';
CREATE DATABASE crm_production OWNER crm_user;
GRANT ALL PRIVILEGES ON DATABASE crm_production TO crm_user;
\q

# Enable PostgreSQL to start on boot
systemctl enable postgresql
systemctl start postgresql
```

### Redis Configuration

```bash
# Enable Redis
systemctl enable redis-server
systemctl start redis-server

# Verify Redis is running
redis-cli ping  # Should return: PONG
```

---

## 📁 Application Deployment

### 1. Clone Repository

```bash
# Create app directory
mkdir -p /var/www
cd /var/www

# Clone your repository
git clone https://github.com/hasaniqbal-lead/crm.git
cd crm

# Switch to your branch
git checkout claude/repo-review-011CV3n3rMMGxbegxbgygix9
```

### 2. Install Dependencies

```bash
# Install gems
bundle install --deployment --without development test
```

### 3. Configure Environment

```bash
# Create environment file
nano .env
```

Add the following to `.env`:

```bash
# Rails Environment
RAILS_ENV=production
RAILS_SERVE_STATIC_FILES=true
RAILS_LOG_TO_STDOUT=true

# Database
DATABASE_HOST=localhost
DATABASE_NAME=crm_production
DATABASE_USERNAME=crm_user
DATABASE_PASSWORD=your_secure_password_here

# Redis
REDIS_URL=redis://localhost:6379/0

# JWT Secret (generate with: openssl rand -hex 64)
JWT_SECRET_KEY=your_generated_secret_key_here

# Rails Secret Key Base (generate with: rails secret)
SECRET_KEY_BASE=your_generated_secret_key_base_here

# Social Media API Keys (add when you have them)
WHATSAPP_CLOUD_API_ACCESS_TOKEN=
FB_APP_ID=
FB_APP_SECRET=
INSTAGRAM_VERIFY_TOKEN=

# Application Host
RAILS_HOST=161.97.134.76
```

### 4. Generate Secrets

```bash
# Generate JWT secret
openssl rand -hex 64

# Generate Rails secret key base
RAILS_ENV=production bundle exec rails secret

# Copy these values to your .env file
```

### 5. Setup Database

```bash
# Create and migrate database
RAILS_ENV=production bundle exec rails db:create
RAILS_ENV=production bundle exec rails db:migrate

# Seed database with test data (optional)
RAILS_ENV=production bundle exec rails db:seed

# Verify
RAILS_ENV=production bundle exec rails console
# In console:
User.count  # Should show 7 if seeded
exit
```

---

## 🌐 Nginx Configuration

### 1. Create Nginx Site Config

```bash
nano /etc/nginx/sites-available/crm
```

Add this configuration:

```nginx
upstream crm_app {
  server 127.0.0.1:3000 fail_timeout=0;
}

server {
  listen 80;
  server_name 161.97.134.76;

  root /var/www/crm/public;

  # Increase timeout for long-running requests
  proxy_connect_timeout 600;
  proxy_send_timeout 600;
  proxy_read_timeout 600;
  send_timeout 600;

  location / {
    proxy_pass http://crm_app;
    proxy_set_header Host $host;
    proxy_set_header X-Real-IP $remote_addr;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Proto $scheme;
  }

  # Serve static files directly
  location ~ ^/(assets|packs)/ {
    gzip_static on;
    expires max;
    add_header Cache-Control public;
  }

  # Health check endpoint
  location /health {
    proxy_pass http://crm_app;
    access_log off;
  }
}
```

### 2. Enable Site

```bash
# Create symlink
ln -s /etc/nginx/sites-available/crm /etc/nginx/sites-enabled/

# Remove default site
rm /etc/nginx/sites-enabled/default

# Test configuration
nginx -t

# Reload Nginx
systemctl reload nginx
```

---

## 🔄 Process Management with Systemd

### 1. Create Rails Service

```bash
nano /etc/systemd/system/crm-web.service
```

Add this configuration:

```ini
[Unit]
Description=CRM Rails Application
After=network.target postgresql.service redis.service

[Service]
Type=simple
User=root
WorkingDirectory=/var/www/crm
Environment=RAILS_ENV=production
EnvironmentFile=/var/www/crm/.env
ExecStart=/root/.rbenv/shims/bundle exec puma -C config/puma.rb
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
```

### 2. Create Sidekiq Service

```bash
nano /etc/systemd/system/crm-sidekiq.service
```

Add this configuration:

```ini
[Unit]
Description=CRM Sidekiq Background Jobs
After=network.target postgresql.service redis.service

[Service]
Type=simple
User=root
WorkingDirectory=/var/www/crm
Environment=RAILS_ENV=production
EnvironmentFile=/var/www/crm/.env
ExecStart=/root/.rbenv/shims/bundle exec sidekiq -C config/sidekiq.yml
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
```

### 3. Create Puma Configuration

```bash
nano /var/www/crm/config/puma.rb
```

Add:

```ruby
workers ENV.fetch("WEB_CONCURRENCY") { 2 }
threads_count = ENV.fetch("RAILS_MAX_THREADS") { 5 }
threads threads_count, threads_count

port        ENV.fetch("PORT") { 3000 }
environment ENV.fetch("RAILS_ENV") { "production" }

pidfile ENV.fetch("PIDFILE") { "tmp/pids/server.pid" }

plugin :tmp_restart

preload_app!

on_worker_boot do
  ActiveRecord::Base.establish_connection if defined?(ActiveRecord)
end
```

### 4. Create Sidekiq Configuration

```bash
nano /var/www/crm/config/sidekiq.yml
```

Add:

```yaml
:concurrency: 5
:queues:
  - default
  - mailers
  - webhooks
```

### 5. Start Services

```bash
# Reload systemd
systemctl daemon-reload

# Enable services to start on boot
systemctl enable crm-web
systemctl enable crm-sidekiq

# Start services
systemctl start crm-web
systemctl start crm-sidekiq

# Check status
systemctl status crm-web
systemctl status crm-sidekiq

# View logs
journalctl -u crm-web -f
journalctl -u crm-sidekiq -f
```

---

## 🧪 Testing the Deployment

### 1. Check Application Health

```bash
# Test locally
curl http://localhost:3000/up

# Test via public IP
curl http://161.97.134.76/up
```

### 2. Test Authentication API

```bash
# Test signup
curl -X POST http://161.97.134.76/api/v1/auth/signup \
  -H "Content-Type: application/json" \
  -d '{
    "user": {
      "name": "Test User",
      "email": "test@example.com",
      "password": "password123",
      "password_confirmation": "password123"
    },
    "account_name": "Test Company"
  }'

# Test login
curl -X POST http://161.97.134.76/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "admin@acme.com",
    "password": "password123"
  }'
```

### 3. Test Authenticated Endpoint

```bash
# Get access token from login response, then:
curl -X GET http://161.97.134.76/api/v1/accounts/1/conversations \
  -H "Authorization: Bearer YOUR_ACCESS_TOKEN"
```

---

## 🔐 Security Hardening

### 1. Firewall Setup

```bash
# Install UFW
apt-get install -y ufw

# Allow SSH, HTTP, HTTPS
ufw allow 22/tcp
ufw allow 80/tcp
ufw allow 443/tcp

# Enable firewall
ufw enable

# Check status
ufw status
```

### 2. PostgreSQL Security

```bash
# Edit PostgreSQL config
nano /etc/postgresql/*/main/pg_hba.conf

# Ensure this line exists:
# local   all             all                                     peer
# host    all             all             127.0.0.1/32            md5

# Restart PostgreSQL
systemctl restart postgresql
```

### 3. Change Default Passwords

```bash
# Change root password
passwd

# Update database password in .env
nano /var/www/crm/.env
```

---

## 🔄 Updating the Application

### Create Update Script

```bash
nano /root/update-crm.sh
```

Add:

```bash
#!/bin/bash
set -e

echo "🔄 Updating CRM Application..."

cd /var/www/crm

# Pull latest changes
git pull origin claude/repo-review-011CV3n3rMMGxbegxbgygix9

# Install dependencies
bundle install --deployment

# Run migrations
RAILS_ENV=production bundle exec rails db:migrate

# Restart services
systemctl restart crm-web
systemctl restart crm-sidekiq

echo "✅ Update complete!"
```

Make it executable:

```bash
chmod +x /root/update-crm.sh
```

Usage:

```bash
bash /root/update-crm.sh
```

---

## 📊 Monitoring

### View Application Logs

```bash
# Rails logs
tail -f /var/www/crm/log/production.log

# Nginx access logs
tail -f /var/nginx/access.log

# Nginx error logs
tail -f /var/log/nginx/error.log

# Systemd service logs
journalctl -u crm-web -f
journalctl -u crm-sidekiq -f
```

### Check Resource Usage

```bash
# CPU and Memory
htop

# Disk usage
df -h

# Database connections
sudo -u postgres psql -c "SELECT count(*) FROM pg_stat_activity;"
```

---

## 🚨 Troubleshooting

### Application Won't Start

```bash
# Check logs
journalctl -u crm-web -n 50

# Check permissions
ls -la /var/www/crm

# Check environment
cat /var/www/crm/.env

# Test manually
cd /var/www/crm
RAILS_ENV=production bundle exec rails console
```

### Database Connection Issues

```bash
# Check PostgreSQL status
systemctl status postgresql

# Test connection
sudo -u postgres psql -d crm_production

# Check credentials
cat /var/www/crm/.env | grep DATABASE
```

### Nginx Issues

```bash
# Test configuration
nginx -t

# Check error logs
tail -f /var/log/nginx/error.log

# Restart nginx
systemctl restart nginx
```

---

## 📱 Next Steps

1. **Configure SSL/HTTPS** (recommended):
   ```bash
   apt-get install certbot python3-certbot-nginx
   certbot --nginx -d yourdomain.com
   ```

2. **Setup Social Media Webhooks**:
   - Configure WhatsApp webhooks to point to: `http://161.97.134.76/webhooks/YOUR_PHONE_NUMBER`
   - Configure Facebook webhooks to point to: `http://161.97.134.76/webhooks/facebook`
   - Configure Instagram webhooks to point to: `http://161.97.134.76/webhooks/instagram`

3. **Setup Monitoring** (optional):
   - Install monitoring tools (New Relic, DataDog, etc.)
   - Setup log aggregation (ELK stack, Papertrail, etc.)

4. **Setup Backups**:
   - Configure automated database backups
   - Setup offsite backup storage

---

## 🎉 Success!

Your CRM application should now be running at:
- **HTTP:** http://161.97.134.76
- **API:** http://161.97.134.76/api/v1
- **Health Check:** http://161.97.134.76/up

**Test Credentials:**
- Email: admin@acme.com
- Password: password123

---

**Need Help?**
- Check the logs: `journalctl -u crm-web -f`
- Review error messages in `/var/www/crm/log/production.log`
- Verify environment variables in `/var/www/crm/.env`
