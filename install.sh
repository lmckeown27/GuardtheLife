#!/bin/bash

# GuardtheLife - Installation Script
# This script sets up the entire development environment

set -e

echo "🚀 Setting up GuardtheLife project..."

# Check if Docker is installed
if ! command -v docker &> /dev/null; then
    echo "❌ Docker is not installed. Please install Docker first."
    exit 1
fi

# Check if Docker Compose is installed
if ! command -v docker-compose &> /dev/null; then
    echo "❌ Docker Compose is not installed. Please install Docker Compose first."
    exit 1
fi

# Check if Node.js is installed
if ! command -v node &> /dev/null; then
    echo "❌ Node.js is not installed. Please install Node.js 18+ first."
    exit 1
fi

# Check Node.js version
NODE_VERSION=$(node -v | cut -d'v' -f2 | cut -d'.' -f1)
if [ "$NODE_VERSION" -lt 18 ]; then
    echo "❌ Node.js version 18+ is required. Current version: $(node -v)"
    exit 1
fi

echo "✅ Prerequisites check passed"

# Create environment files
echo "📝 Creating environment files..."

# Backend environment
if [ ! -f "backend/.env" ]; then
    cp backend/env.example backend/.env
    echo "✅ Created backend/.env"
else
    echo "ℹ️  backend/.env already exists"
fi

# Frontend environment
if [ ! -f "frontend/.env" ]; then
    cp frontend/env.example frontend/.env
    echo "✅ Created frontend/.env"
else
    echo "ℹ️  frontend/.env already exists"
fi

# Install backend dependencies
echo "📦 Installing backend dependencies..."
cd backend
npm install
cd ..

# Install frontend dependencies
echo "📦 Installing frontend dependencies..."
cd frontend
npm install
cd ..

# Start Docker services
echo "🐳 Starting Docker services..."
docker-compose up -d postgres redis

echo "⏳ Waiting for database to be ready..."
sleep 10

# Run database migrations
echo "🗄️  Running database migrations..."
cd backend
npm run db:migrate
cd ..

echo "✅ Installation completed successfully!"
echo ""
echo "🎯 Next steps:"
echo "1. Configure your environment variables in backend/.env and frontend/.env"
echo "2. Set up your Firebase project and add credentials"
echo "3. Set up your Stripe account and add API keys"
echo "4. Start the backend: cd backend && npm run dev"
echo "5. Start the frontend: cd frontend && npm start"
echo "6. Access pgAdmin at http://localhost:5050 (admin@lifeguard.com / admin)"
echo ""
echo "🚀 Happy coding!" 