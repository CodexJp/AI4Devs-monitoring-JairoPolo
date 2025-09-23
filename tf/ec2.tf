# Single EC2 Instance para Monorepo con Datadog Integration
resource "aws_instance" "monorepo_instance" {
  ami                    = "ami-024e4b8b6ef78434a" # Amazon Linux 2 AMI - us-west-2 (latest)
  instance_type          = "t3.small"
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
    
    # Install Node.js and npm using nvm (Latest method for Amazon Linux)
    log "Installing Node.js and npm via nvm..."
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh | bash
    
    # Reload shell to make nvm available
    export NVM_DIR="$HOME/.nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
    [ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"
    
    # Verify nvm installation
    log "Verifying nvm installation..."
    nvm --version
    
    # Install Node.js 18 using AWS pre-compiled binaries (Amazon Linux 2 compatible)
    log "Installing Node.js 18 using AWS pre-compiled binaries..."
    wget -nv https://d3rnber7ry90et.cloudfront.net/linux-x86_64/node-v18.17.1.tar.gz
    mkdir -p /usr/local/lib/node
    tar -xf node-v18.17.1.tar.gz
    mv node-v18.17.1 /usr/local/lib/node/nodejs
    
    # Create symlinks for global access
    ln -s /usr/local/lib/node/nodejs/bin/node /usr/local/bin/node
    ln -s /usr/local/lib/node/nodejs/bin/npm /usr/local/bin/npm
    ln -s /usr/local/lib/node/nodejs/bin/npx /usr/local/bin/npx
    
    # Add to PATH
    echo 'export PATH=/usr/local/lib/node/nodejs/bin:$PATH' >> /home/ec2-user/.bashrc
    export PATH=/usr/local/lib/node/nodejs/bin:$PATH
    
    # Verify Node.js installation
    log "Verifying Node.js installation..."
    node --version
    npm --version
    
    # Check if docker compose is available, install if not
    log "Checking Docker Compose availability..."
    if docker compose version > /dev/null 2>&1; then
        log "Docker Compose available as 'docker compose'"
        COMPOSE_CMD="docker compose"
    else
        log "Installing Docker Compose binary..."
        curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
        chmod +x /usr/local/bin/docker-compose
        COMPOSE_CMD="docker-compose"
    fi
    
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
    
    # Create environment file with correct database host
    cat > .env << 'EOL'
DB_PASSWORD=D1ymf8wyQEGthFR1E9xhCq
DB_USER=LTIdbUser
DB_NAME=LTIdb
DB_PORT=5432
DATABASE_URL=postgresql://LTIdbUser:D1ymf8wyQEGthFR1E9xhCq@db:5432/LTIdb
NODE_ENV=production
DATADOG_API_KEY=${var.datadog_api_key}
EOL
    
    # Also create backend-specific .env file to ensure proper configuration
    cat > backend/.env << 'EOL'
DATABASE_URL=postgresql://LTIdbUser:D1ymf8wyQEGthFR1E9xhCq@db:5432/LTIdb
NODE_ENV=production
PORT=8080
DD_ENV=production
DD_SERVICE=ai4devs-backend
DD_VERSION=1.0.0
DATADOG_API_KEY=${var.datadog_api_key}
EOL
    
    # Fix schema.prisma to use env("DATABASE_URL") instead of hardcoded localhost
    log "Fixing Prisma schema to use environment variable..."
    sed -i 's|url      = "postgresql://LTIdbUser:D1ymf8wyQEGthFR1E9xhCq@localhost:5432/LTIdb"|url      = env("DATABASE_URL")|g' backend/prisma/schema.prisma
    
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
      - REACT_APP_API_URL=http://$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4):8080
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

# Install OpenSSL, curl and dependencies for Prisma
RUN apt-get update && apt-get install -y openssl ca-certificates curl

# Copy package files first for better layer caching
COPY package*.json ./

# Install dependencies
RUN npm install

# Copy Prisma schema first to generate client
COPY prisma ./prisma/

# Generate Prisma client
RUN npx prisma generate

# Copy rest of source code
COPY . .

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

# Install curl for health checks and serve globally
RUN apt-get update && apt-get install -y curl && rm -rf /var/lib/apt/lists/* && npm install -g serve

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
    
    # Use Node.js for migrations (already installed globally)
    export PATH=/usr/local/lib/node/nodejs/bin:$PATH
    
    # Install dependencies for migration process
    npm install --production=false
    
    # Generate Prisma client
    npx prisma generate
    
    # Wait for database to be ready and run migrations
    cd /opt/ai4devs
    
    # Start only database first
    $COMPOSE_CMD up -d db
    
    # Wait for database to be ready
    log "Waiting for database to be ready..."
    sleep 20
    
    # Run migrations from backend directory
    cd /opt/ai4devs/backend
    DATABASE_URL="postgresql://LTIdbUser:D1ymf8wyQEGthFR1E9xhCq@localhost:5432/LTIdb" npx prisma migrate deploy
    
    # Seed the database
    log "Seeding database..."
    DATABASE_URL="postgresql://LTIdbUser:D1ymf8wyQEGthFR1E9xhCq@localhost:5432/LTIdb" npx prisma db seed || echo "Seed completed or skipped"
    
    # Now start the full application stack
    log "Starting full application stack..."
    cd /opt/ai4devs
    
    # Build and start all services
    $COMPOSE_CMD up -d --build
    
    # Wait for services to be ready
    log "Waiting for services to start..."
    sleep 30
    
    # Check service status
    $COMPOSE_CMD ps
    
    # Fix schema.prisma inside the running backend container and execute seed
    log "Fixing schema.prisma inside backend container and seeding database..."
    
    # Fix schema.prisma syntax inside the backend container
    docker exec ai4devs-backend-1 sed -i 's|url      = "env("DATABASE_URL")"|url      = env("DATABASE_URL")|g' /usr/src/app/prisma/schema.prisma
    
    # Regenerate Prisma client with correct configuration
    docker exec ai4devs-backend-1 npx prisma generate
    
    # Execute database seed
    log "Seeding database with sample data..."
    docker exec ai4devs-backend-1 npx prisma db seed || echo "Seed completed or no seed script found"
    
    # Restart backend container to ensure proper connection
    log "Restarting backend container..."
    $COMPOSE_CMD restart backend
    
    # Wait for backend to be ready after restart
    sleep 20
    
    # Final health check
    log "Performing health checks..."
    
    # Wait for backend to be ready (using root endpoint instead of /health)
    for i in {1..30}; do
        if curl -f http://localhost:8080/ > /dev/null 2>&1; then
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
ExecStart=/usr/bin/docker compose up -d
ExecStop=/usr/bin/docker compose down
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

