#!/bin/bash

# GuardtheLife - Start Script
# This script starts the entire application stack

set -e

echo "🚀 Starting GuardtheLife..."

# Check if Docker is running
if ! docker info &> /dev/null; then
    echo "❌ Docker is not running. Please start Docker first."
    exit 1
fi

# Start all services
echo "🐳 Starting all services..."
docker-compose up -d

echo "⏳ Waiting for services to be ready..."
sleep 15

# Check service health
echo "🔍 Checking service health..."

# Check PostgreSQL
if docker-compose exec -T postgres pg_isready -U postgres &> /dev/null; then
    echo "✅ PostgreSQL is ready"
else
    echo "❌ PostgreSQL is not ready"
fi

# Check Redis
if docker-compose exec -T redis redis-cli ping &> /dev/null; then
    echo "✅ Redis is ready"
else
    echo "❌ Redis is not ready"
fi

# Check Backend
if curl -f http://localhost:3000/health &> /dev/null; then
    echo "✅ Backend API is ready"
else
    echo "❌ Backend API is not ready"
fi

echo ""
echo "🎯 Services are starting up..."
echo ""
echo "🌐 Frontend Web app: http://localhost:3000"
echo "📱 iOS app: Open GuardtheLife.xcodeproj in Xcode"
echo "🔌 Backend API: http://localhost:3000"
echo "🗄️  PostgreSQL: localhost:5432"
echo "🔴 Redis: localhost:6379"
echo "📊 pgAdmin: http://localhost:5050 (admin@lifeguard.com / admin)"
echo ""
echo "📋 Useful commands:"
echo "  View logs: docker-compose logs -f"
echo "  Stop services: docker-compose down"
echo "  Restart services: docker-compose restart"
echo "  View running services: docker-compose ps"
echo ""
echo "🚀 Your GuardtheLife app is starting up!" 