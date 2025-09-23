# Single EC2 Instance para Monorepo con Datadog Integration
resource "aws_instance" "monorepo_instance" {
  ami                    = "ami-024e4b8b6ef78434a" # Amazon Linux 2 AMI - us-west-2 (latest)
  instance_type          = "t2.micro"
  key_name               = "AI4Devs" # Enabling SSH access
  iam_instance_profile   = aws_iam_instance_profile.datadog_instance_profile.name
  vpc_security_group_ids = [aws_security_group.unified_sg.id]

  user_data_base64 = base64encode(<<-EOF
    #!/bin/bash
    # AI4Devs Full Stack Deployment with Datadog Integration
    set -e
    
    # Logging function
    log() {
        echo "$(date '+%Y-%m-%d %H:%M:%S'): $1" | tee -a /var/log/ai4devs-deployment.log
    }
    
    log "Starting AI4Devs deployment..."
    
    # System updates and dependencies
    log "Installing system dependencies..."
    yum update -y
    yum install -y docker git curl wget unzip
    
    # Install Node.js and npm using AWS recommended method (nvm)
    log "Installing Node.js and npm via nvm (AWS recommended)..."
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash
    source ~/.bashrc
    nvm install --lts
    nvm use --lts
    
    # Verify Node.js installation
    node --version
    npm --version
    
    # Install Docker Compose
    log "Installing Docker Compose..."
    curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    chmod +x /usr/local/bin/docker-compose
    
    # Docker setup
    log "Configuring Docker..."
    service docker start
    usermod -a -G docker ec2-user
    systemctl enable docker
    
    # Wait for Docker to be ready
    sleep 10
    
    # Datadog Agent installation
    log "Installing Datadog Agent..."
    DD_API_KEY="${var.datadog_api_key}" \
    DD_SITE="us3.datadoghq.com" \
    DD_APM_ENABLED=true \
    DD_LOGS_ENABLED=true \
    bash -c "$(curl -L https://install.datadoghq.com/scripts/install_script.sh)"
    
    # Configure Datadog tags and integrations
    log "Configuring Datadog Agent..."
    cat >> /etc/datadog-agent/datadog.yaml << 'EOL'
tags: env:production, service:ai4devs-monorepo, region:us-west-2, component:full-stack
logs_enabled: true
apm_config:
  enabled: true
  env: production
process_config:
  enabled: "true"
EOL
    
    # Enable Docker integration for Datadog
    mkdir -p /etc/datadog-agent/conf.d/docker.d/
    cat > /etc/datadog-agent/conf.d/docker.d/conf.yaml << 'EOL'
init_config:

instances:
  - url: "unix://var/run/docker.sock"
    new_tag_names: true
EOL
    
    systemctl restart datadog-agent
    
    # Application setup - Clone real repository
    log "Cloning real AI4Devs repository..."
    cd /opt
    
    # Install git if not present
    yum install -y git
    
    # Clone the actual repository
    git clone https://github.com/CodexJp/AI4Devs-monitoring-JairoPolo.git ai4devs
    cd /opt/ai4devs
    
    # Verify repository structure
    log "Repository cloned successfully. Contents:"
    ls -la
    
    # Create environment file
    cat > .env << 'EOL'
DB_PASSWORD=D1ymf8wyQEGthFR1E9xhCq
DB_USER=LTIdbUser
DB_NAME=LTIdb
DB_PORT=5432
DATABASE_URL=postgresql://LTIdbUser:D1ymf8wyQEGthFR1E9xhCq@db:5432/LTIdb
NODE_ENV=production
DATADOG_API_KEY=${var.datadog_api_key}
EOL
    
    # Use the existing docker-compose.yml from repository
    log "Configuring docker-compose for production..."
    
    # Backup original docker-compose if exists
    if [ -f docker-compose.yml ]; then
        cp docker-compose.yml docker-compose.yml.backup
    fi
    
    # Create production docker-compose.yml
    cat > docker-compose.yml << 'EOL'
version: "3.8"

services:
  # PostgreSQL Database
  db:
    image: postgres:15
    restart: always
    environment:
      POSTGRES_PASSWORD: D1ymf8wyQEGthFR1E9xhCq
      POSTGRES_USER: LTIdbUser
      POSTGRES_DB: LTIdb
    ports:
      - "5432:5432"
    volumes:
      - postgres_data:/var/lib/postgresql/data
    networks:
      - ai4devs-network
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U LTIdbUser -d LTIdb"]
      interval: 10s
      timeout: 5s
      retries: 5
    labels:
      - "com.datadoghq.ad.logs=[{\"source\":\"postgresql\",\"service\":\"ai4devs-db\"}]"

  # Backend API - Real TypeScript Backend
  backend:
    build:
      context: ./backend
      dockerfile: Dockerfile
    restart: always
    environment:
      - DATABASE_URL=postgresql://LTIdbUser:D1ymf8wyQEGthFR1E9xhCq@db:5432/LTIdb
      - NODE_ENV=production
      - PORT=8080
      - DD_ENV=production
      - DD_SERVICE=ai4devs-backend
      - DD_VERSION=1.0.0
    ports:
      - "8080:8080"
    depends_on:
      db:
        condition: service_healthy
    networks:
      - ai4devs-network
    volumes:
      - ./backend/uploads:/usr/src/app/uploads
    labels:
      - "com.datadoghq.ad.logs=[{\"source\":\"nodejs\",\"service\":\"ai4devs-backend\"}]"
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8080/health"]
      interval: 30s
      timeout: 10s
      retries: 3

  # Frontend Web App - Real React Frontend
  frontend:
    build:
      context: ./frontend
      dockerfile: Dockerfile
    restart: always
    environment:
      - NODE_ENV=production
      - REACT_APP_API_URL=http://localhost:8080
      - DD_ENV=production
      - DD_SERVICE=ai4devs-frontend
      - DD_VERSION=1.0.0
    ports:
      - "3000:3000"
    depends_on:
      - backend
    networks:
      - ai4devs-network
    labels:
      - "com.datadoghq.ad.logs=[{\"source\":\"nodejs\",\"service\":\"ai4devs-frontend\"}]"
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:3000"]
      interval: 30s
      timeout: 10s
      retries: 3

volumes:
  postgres_data:

networks:
  ai4devs-network:
    driver: bridge
EOL
    
    # Create Dockerfiles for real application
    log "Creating Dockerfiles for backend and frontend..."
    
    # Backend Dockerfile
    cat > backend/Dockerfile << 'EOL'
FROM node:18-slim

WORKDIR /usr/src/app

# Install OpenSSL and dependencies for Prisma
RUN apt-get update && apt-get install -y openssl ca-certificates

# Copy package files
COPY package*.json ./

# Install dependencies
RUN npm install

# Copy source code
COPY . .

# Generate Prisma client
RUN npx prisma generate

# Build the application
RUN npm run build

# Create uploads directory
RUN mkdir -p uploads

# Expose port
EXPOSE 8080

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
  CMD curl -f http://localhost:8080/health || exit 1

# Start the application
CMD ["npm", "start"]
EOL

    # Frontend Dockerfile
    cat > frontend/Dockerfile << 'EOL'
FROM node:18-slim as builder

WORKDIR /app

# Copy package files
COPY package*.json ./

# Install dependencies
RUN npm install

# Copy source code
COPY . .

# Build the application
RUN npm run build

# Production stage
FROM node:18-slim

WORKDIR /app

# Install serve globally
RUN npm install -g serve

# Copy built application
COPY --from=builder /app/build ./build

# Expose port
EXPOSE 3000

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
  CMD curl -f http://localhost:3000 || exit 1

# Start the application
CMD ["serve", "-s", "build", "-l", "3000"]
EOL
    
    # Set proper ownership
    chown -R ec2-user:ec2-user /opt/ai4devs
    
    # Prepare database migrations and setup
    log "Setting up database migrations..."
    
    # Run Prisma migrations first (before starting containers)
    cd /opt/ai4devs/backend
    
    # Ensure nvm and Node.js are available in current shell
    source ~/.bashrc
    nvm use --lts
    
    # Install dependencies for migration process
    npm install --production=false
    
    # Generate Prisma client
    npx prisma generate
    
    # Wait for database to be ready and run migrations
    cd /opt/ai4devs
    
    # Start only database first
    docker-compose up -d db
    
    # Wait for database to be ready
    log "Waiting for database to be ready..."
    sleep 20
    
    # Run migrations from backend directory
    cd /opt/ai4devs/backend
    source ~/.bashrc && nvm use --lts
    DATABASE_URL="postgresql://LTIdbUser:D1ymf8wyQEGthFR1E9xhCq@localhost:5432/LTIdb" npx prisma migrate deploy
    
    # Seed the database
    log "Seeding database..."
    DATABASE_URL="postgresql://LTIdbUser:D1ymf8wyQEGthFR1E9xhCq@localhost:5432/LTIdb" npx prisma db seed || echo "Seed completed or skipped"
    
    # Now start the full application stack
    log "Starting full application stack..."
    cd /opt/ai4devs
    
    # Build and start all services
    docker-compose up -d --build
    
    # Wait for services to be ready
    log "Waiting for services to start..."
    sleep 30
    
    # Check service status
    docker-compose ps
    
    # Final health check
    log "Performing health checks..."
    
    # Wait for backend to be ready
    for i in {1..30}; do
        if curl -f http://localhost:8080/health > /dev/null 2>&1; then
            log "Backend health check passed"
            break
        fi
        log "Waiting for backend... ($i/30)"
        sleep 10
    done
    
    # Wait for frontend to be ready
    for i in {1..30}; do
        if curl -f http://localhost:3000 > /dev/null 2>&1; then
            log "Frontend health check passed"
            break
        fi
        log "Waiting for frontend... ($i/30)"
        sleep 10
    done
    
    # Create startup script for automatic restart
    cat > /etc/systemd/system/ai4devs.service << 'EOL'
[Unit]
Description=AI4Devs Application Stack
Requires=docker.service
After=docker.service

[Service]
Type=oneshot
RemainAfterExit=yes
WorkingDirectory=/opt/ai4devs
ExecStart=/usr/local/bin/docker-compose up -d
ExecStop=/usr/local/bin/docker-compose down
TimeoutStartSec=0

[Install]
WantedBy=multi-user.target
EOL
    
    systemctl enable ai4devs.service
    
    log "✅ AI4Devs deployment completed successfully!"
    log "🌐 Frontend: http://$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4):3000"
    log "🔧 Backend API: http://$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4):8080"
    log "📊 Datadog monitoring: Active"
    
    # Final status log
    echo "$(date): AI4Devs full-stack deployment completed successfully" > /var/log/deployment-complete.log
  EOF
  )

  tags = {
    Name        = "ai4devs-monorepo-instance"
    Environment = "production"
    Service     = "backend,frontend"
    Monitoring  = "datadog"
    Region      = "us-west-2"
  }
}

