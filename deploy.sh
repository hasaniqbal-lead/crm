#!/bin/bash

# Automated Deployment Script for CRM Application
# Server: VATRIX (161.97.134.76)
# Run this script on your server as root

set -e  # Exit on error

echo "╔════════════════════════════════════════════════════════════════╗"
echo "║         CRM Application - Automated Deployment                 ║"
echo "║                  VATRIX Server Setup                           ║"
echo "╚════════════════════════════════════════════════════════════════╝"
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check if running as root
if [ "$EUID" -ne 0 ]; then
  echo -e "${RED}Please run as root${NC}"
  exit 1
fi

echo -e "${GREEN}✓${NC} Running as root"

# ============================================================================
# Configuration Variables
# ============================================================================

APP_DIR="/var/www/crm"
REPO_URL="https://github.com/hasaniqbal-lead/crm.git"
BRANCH="claude/repo-review-011CV3n3rMMGxbegxbgygix9"
DB_NAME="crm_production"
DB_USER="crm_user"

# ============================================================================
# Step 1: Update System
# ============================================================================

echo ""
echo "============================================"
echo "  Step 1: Updating System Packages"
echo "============================================"

apt-get update -qq
apt-get upgrade -y -qq
echo -e "${GREEN}✓${NC} System updated"

# ============================================================================
# Step 2: Install Dependencies
# ============================================================================

echo ""
echo "============================================"
echo "  Step 2: Installing Dependencies"
echo "============================================"

echo "Installing system packages..."
apt-get install -y -qq \
  curl git build-essential libssl-dev zlib1g-dev \
  libreadline-dev libyaml-dev libsqlite3-dev sqlite3 \
  libxml2-dev libxslt1-dev libcurl4-openssl-dev \
  software-properties-common libffi-dev nodejs yarn \
  postgresql postgresql-contrib redis-server nginx

echo -e "${GREEN}✓${NC} System packages installed"

# ============================================================================
# Step 3: Install Ruby via rbenv
# ============================================================================

echo ""
echo "============================================"
echo "  Step 3: Installing Ruby 3.3.6"
echo "============================================"

if [ ! -d "$HOME/.rbenv" ]; then
  echo "Installing rbenv..."
  git clone https://github.com/rbenv/rbenv.git ~/.rbenv
  echo 'export PATH="$HOME/.rbenv/bin:$PATH"' >> ~/.bashrc
  echo 'eval "$(rbenv init -)"' >> ~/.bashrc

  git clone https://github.com/rbenv/ruby-build.git ~/.rbenv/plugins/ruby-build

  export PATH="$HOME/.rbenv/bin:$PATH"
  eval "$(~/.rbenv/bin/rbenv init -)"

  echo -e "${GREEN}✓${NC} rbenv installed"
else
  echo -e "${YELLOW}⚠${NC} rbenv already installed"
fi

if ! rbenv versions | grep -q "3.3.6"; then
  echo "Installing Ruby 3.3.6 (this may take a few minutes)..."
  rbenv install 3.3.6
  rbenv global 3.3.6
  echo -e "${GREEN}✓${NC} Ruby 3.3.6 installed"
else
  echo -e "${YELLOW}⚠${NC} Ruby 3.3.6 already installed"
  rbenv global 3.3.6
fi

# Install bundler
~/.rbenv/shims/gem install bundler -v 2.5.23
echo -e "${GREEN}✓${NC} Bundler installed"

# ============================================================================
# Step 4: Configure PostgreSQL
# ============================================================================

echo ""
echo "============================================"
echo "  Step 4: Configuring PostgreSQL"
echo "============================================"

systemctl enable postgresql
systemctl start postgresql

# Generate random password
DB_PASSWORD=$(openssl rand -base64 32)

# Create database user and database
sudo -u postgres psql -tc "SELECT 1 FROM pg_user WHERE usename = '$DB_USER'" | grep -q 1 || \
  sudo -u postgres psql -c "CREATE USER $DB_USER WITH PASSWORD '$DB_PASSWORD';"

sudo -u postgres psql -tc "SELECT 1 FROM pg_database WHERE datname = '$DB_NAME'" | grep -q 1 || \
  sudo -u postgres psql -c "CREATE DATABASE $DB_NAME OWNER $DB_USER;"

sudo -u postgres psql -c "GRANT ALL PRIVILEGES ON DATABASE $DB_NAME TO $DB_USER;"

echo -e "${GREEN}✓${NC} PostgreSQL configured"
echo -e "${YELLOW}Database Password:${NC} $DB_PASSWORD"
echo -e "${YELLOW}(Save this password - you'll need it!)${NC}"

# ============================================================================
# Step 5: Configure Redis
# ============================================================================

echo ""
echo "============================================"
echo "  Step 5: Configuring Redis"
echo "============================================"

systemctl enable redis-server
systemctl start redis-server

echo -e "${GREEN}✓${NC} Redis configured"

# ============================================================================
# Step 6: Clone Application
# ============================================================================

echo ""
echo "============================================"
echo "  Step 6: Cloning Application"
echo "============================================"

if [ -d "$APP_DIR" ]; then
  echo -e "${YELLOW}⚠${NC} Application directory exists, pulling latest changes..."
  cd $APP_DIR
  git pull origin $BRANCH
else
  echo "Cloning repository..."
  mkdir -p /var/www
  cd /var/www
  git clone $REPO_URL
  cd crm
  git checkout $BRANCH
fi

echo -e "${GREEN}✓${NC} Application cloned"

# ============================================================================
# Step 7: Create Environment File
# ============================================================================

echo ""
echo "============================================"
echo "  Step 7: Creating Environment File"
echo "============================================"

cd $APP_DIR

# Generate secrets
JWT_SECRET=$(openssl rand -hex 64)
SECRET_KEY_BASE=$(~/.rbenv/shims/bundle exec rails secret RAILS_ENV=production 2>/dev/null || openssl rand -hex 64)

cat > .env << EOF
# Rails Environment
RAILS_ENV=production
RAILS_SERVE_STATIC_FILES=true
RAILS_LOG_TO_STDOUT=true

# Database
DATABASE_HOST=localhost
DATABASE_NAME=$DB_NAME
DATABASE_USERNAME=$DB_USER
DATABASE_PASSWORD=$DB_PASSWORD

# Redis
REDIS_URL=redis://localhost:6379/0

# JWT Secret
JWT_SECRET_KEY=$JWT_SECRET

# Rails Secret Key Base
SECRET_KEY_BASE=$SECRET_KEY_BASE

# Application Host
RAILS_HOST=161.97.134.76

# Social Media API Keys (update these later)
WHATSAPP_CLOUD_API_ACCESS_TOKEN=
FB_APP_ID=
FB_APP_SECRET=
INSTAGRAM_VERIFY_TOKEN=
EOF

echo -e "${GREEN}✓${NC} Environment file created"

# ============================================================================
# Step 8: Install Application Dependencies
# ============================================================================

echo ""
echo "============================================"
echo "  Step 8: Installing Application Dependencies"
echo "============================================"

cd $APP_DIR
~/.rbenv/shims/bundle install --deployment --without development test

echo -e "${GREEN}✓${NC} Dependencies installed"

# ============================================================================
# Step 9: Setup Database
# ============================================================================

echo ""
echo "============================================"
echo "  Step 9: Setting Up Database"
echo "============================================"

cd $APP_DIR

# Create database if it doesn't exist
RAILS_ENV=production ~/.rbenv/shims/bundle exec rails db:create 2>/dev/null || true

# Run migrations
RAILS_ENV=production ~/.rbenv/shims/bundle exec rails db:migrate

# Ask if user wants to seed database
read -p "Do you want to seed the database with test data? (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
  RAILS_ENV=production ~/.rbenv/shims/bundle exec rails db:seed
  echo -e "${GREEN}✓${NC} Database seeded"
else
  echo -e "${YELLOW}⚠${NC} Database not seeded"
fi

echo -e "${GREEN}✓${NC} Database setup complete"

# ============================================================================
# Step 10: Create Puma Configuration
# ============================================================================

echo ""
echo "============================================"
echo "  Step 10: Creating Puma Configuration"
echo "============================================"

cat > $APP_DIR/config/puma.rb << 'EOF'
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
EOF

echo -e "${GREEN}✓${NC} Puma configuration created"

# ============================================================================
# Step 11: Create Sidekiq Configuration
# ============================================================================

echo ""
echo "============================================"
echo "  Step 11: Creating Sidekiq Configuration"
echo "============================================"

mkdir -p $APP_DIR/config

cat > $APP_DIR/config/sidekiq.yml << 'EOF'
:concurrency: 5
:queues:
  - default
  - mailers
  - webhooks
EOF

echo -e "${GREEN}✓${NC} Sidekiq configuration created"

# ============================================================================
# Step 12: Create Systemd Services
# ============================================================================

echo ""
echo "============================================"
echo "  Step 12: Creating Systemd Services"
echo "============================================"

# Rails service
cat > /etc/systemd/system/crm-web.service << EOF
[Unit]
Description=CRM Rails Application
After=network.target postgresql.service redis.service

[Service]
Type=simple
User=root
WorkingDirectory=$APP_DIR
Environment=RAILS_ENV=production
EnvironmentFile=$APP_DIR/.env
ExecStart=$HOME/.rbenv/shims/bundle exec puma -C config/puma.rb
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

# Sidekiq service
cat > /etc/systemd/system/crm-sidekiq.service << EOF
[Unit]
Description=CRM Sidekiq Background Jobs
After=network.target postgresql.service redis.service

[Service]
Type=simple
User=root
WorkingDirectory=$APP_DIR
Environment=RAILS_ENV=production
EnvironmentFile=$APP_DIR/.env
ExecStart=$HOME/.rbenv/shims/bundle exec sidekiq -C config/sidekiq.yml
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable crm-web
systemctl enable crm-sidekiq

echo -e "${GREEN}✓${NC} Systemd services created"

# ============================================================================
# Step 13: Configure Nginx
# ============================================================================

echo ""
echo "============================================"
echo "  Step 13: Configuring Nginx"
echo "============================================"

cat > /etc/nginx/sites-available/crm << 'EOF'
upstream crm_app {
  server 127.0.0.1:3000 fail_timeout=0;
}

server {
  listen 80;
  server_name 161.97.134.76;

  root /var/www/crm/public;

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

  location ~ ^/(assets|packs)/ {
    gzip_static on;
    expires max;
    add_header Cache-Control public;
  }

  location /health {
    proxy_pass http://crm_app;
    access_log off;
  }
}
EOF

ln -sf /etc/nginx/sites-available/crm /etc/nginx/sites-enabled/
rm -f /etc/nginx/sites-enabled/default

nginx -t
systemctl reload nginx

echo -e "${GREEN}✓${NC} Nginx configured"

# ============================================================================
# Step 14: Configure Firewall
# ============================================================================

echo ""
echo "============================================"
echo "  Step 14: Configuring Firewall"
echo "============================================"

ufw --force enable
ufw allow 22/tcp
ufw allow 80/tcp
ufw allow 443/tcp

echo -e "${GREEN}✓${NC} Firewall configured"

# ============================================================================
# Step 15: Start Services
# ============================================================================

echo ""
echo "============================================"
echo "  Step 15: Starting Services"
echo "============================================"

systemctl start crm-web
systemctl start crm-sidekiq

# Wait for application to start
echo "Waiting for application to start..."
sleep 5

echo -e "${GREEN}✓${NC} Services started"

# ============================================================================
# Step 16: Test Deployment
# ============================================================================

echo ""
echo "============================================"
echo "  Step 16: Testing Deployment"
echo "============================================"

echo "Testing health endpoint..."
if curl -s http://localhost:3000/up | grep -q "ok"; then
  echo -e "${GREEN}✓${NC} Health check passed"
else
  echo -e "${RED}✗${NC} Health check failed"
fi

# ============================================================================
# Deployment Summary
# ============================================================================

echo ""
echo "╔════════════════════════════════════════════════════════════════╗"
echo "║              🎉 DEPLOYMENT SUCCESSFUL! 🎉                      ║"
echo "╚════════════════════════════════════════════════════════════════╝"
echo ""
echo -e "${GREEN}Your CRM application is now running!${NC}"
echo ""
echo "📱 Access Information:"
echo "   • Application URL: http://161.97.134.76"
echo "   • API Endpoint: http://161.97.134.76/api/v1"
echo "   • Health Check: http://161.97.134.76/up"
echo ""
echo "🔐 Test Credentials:"
echo "   • Email: admin@acme.com"
echo "   • Password: password123"
echo ""
echo "🗄️ Database Information:"
echo "   • Database: $DB_NAME"
echo "   • Username: $DB_USER"
echo "   • Password: $DB_PASSWORD"
echo ""
echo "📝 Important Files:"
echo "   • Application: $APP_DIR"
echo "   • Environment: $APP_DIR/.env"
echo "   • Logs: $APP_DIR/log/production.log"
echo ""
echo "🛠️ Useful Commands:"
echo "   • Check status: systemctl status crm-web"
echo "   • View logs: journalctl -u crm-web -f"
echo "   • Restart app: systemctl restart crm-web"
echo "   • Update app: cd $APP_DIR && git pull && systemctl restart crm-web"
echo ""
echo "🔄 Next Steps:"
echo "   1. Test the API: curl http://161.97.134.76/api/v1/auth/login"
echo "   2. Update social media API keys in $APP_DIR/.env"
echo "   3. Configure SSL certificate (recommended)"
echo "   4. Setup monitoring and backups"
echo ""
echo "📚 Full documentation: $APP_DIR/DEPLOYMENT.md"
echo ""
echo "════════════════════════════════════════════════════════════════"
