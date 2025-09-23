# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Development Commands

### Backend
```bash
cd backend
npm install                    # Install dependencies
npm run dev                    # Development server with hot reload
npm run build                  # Compile TypeScript to dist/
npm start                      # Run production build
npm test                       # Run Jest unit tests
npm run prisma:generate        # Generate Prisma client
```

### Frontend
```bash
cd frontend
npm install                    # Install dependencies
npm start                      # Development server (port 3000)
npm run build                  # Production build
npm test                       # Run Jest tests with custom config
```

### Database Setup
```bash
# Start PostgreSQL container
docker-compose up -d

# Setup database from backend directory
cd backend
npx prisma generate            # Generate Prisma client
npx prisma migrate dev         # Apply migrations
ts-node prisma/seed.ts         # Seed database with test data
```

### Testing
```bash
# Backend unit tests
cd backend && npm test

# Frontend tests
cd frontend && npm test

# E2E tests with Cypress
npx cypress run               # Headless mode
npx cypress open              # Interactive mode
```

## Architecture Overview

### Domain-Driven Design (DDD) Structure
The backend follows DDD principles with clear separation of concerns:

- **Domain Layer** (`src/domain/models/`): Core business entities (Candidate, Position, Application, Interview workflow)
- **Application Layer** (`src/application/services/`): Business logic and use cases (candidateService, positionService, fileUploadService)
- **Presentation Layer** (`src/presentation/controllers/`): HTTP request handling and validation
- **Infrastructure Layer**: Database access via Prisma ORM

### Core Business Entities

**Candidate Management:**
- Candidate with Education, WorkExperience, and Resume
- File upload system for CV/resume documents

**Position & Interview Process:**
- Company → Position → InterviewFlow → InterviewStep → InterviewType
- Application tracking through interview pipeline
- Employee-conducted interviews with scoring

### Technology Stack

**Backend:**
- Node.js + Express.js + TypeScript
- Prisma ORM with PostgreSQL
- File uploads via multer
- Jest for unit testing

**Frontend:**
- React 18 + TypeScript
- React Bootstrap for UI components
- React DnD for drag-and-drop functionality
- React Router for navigation

**Infrastructure:**
- Docker Compose for PostgreSQL
- Jenkins CI/CD pipeline
- Terraform for AWS deployment

## Database Connection

The system uses PostgreSQL with Prisma. Database URL is configured in:
1. `backend/prisma/schema.prisma` (hardcoded for dev)
2. Environment variables via `.env` files

Default connection: `postgresql://LTIdbUser:D1ymf8wyQEGthFR1E9xhCq@localhost:5432/LTIdb`

## Key Configuration Files

- `backend/jest.config.js`: Jest configuration for backend testing
- `cypress.config.js`: E2E test configuration (baseUrl: http://localhost:3000)
- `docker-compose.yml`: PostgreSQL service with environment variables
- `Jenkinsfile`: CI/CD pipeline for AWS deployment

## API Documentation

API specifications are documented in `backend/api-spec.yaml`. The system provides:
- Candidate CRUD operations with nested education/experience
- Position management and application tracking
- File upload endpoints for resume/CV documents

## Development Workflow

1. Start database: `docker-compose up -d`
2. Setup backend: `cd backend && npm install && npx prisma migrate dev`
3. Start backend: `npm run dev` (port 3010)
4. Start frontend: `cd frontend && npm start` (port 3000)
5. Run tests before commits
6. Use Cypress for E2E testing of critical user flows

## Important Notes

- Backend serves as API only, frontend consumes REST endpoints
- File uploads are stored in `backend/uploads/` directory
- Prisma schema includes complex relationships for interview workflows
- CI/CD pipeline runs parallel builds and tests for both frontend and backend