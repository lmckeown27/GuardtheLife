# 🚀 Quick Start Guide - GuardtheLife

## ⚡ Get Started in 5 Minutes

### 1. Prerequisites Check
Make sure you have the following installed:
- ✅ Node.js 18+
- ✅ Docker Desktop
- ✅ Docker Compose

### 2. Clone & Setup
```bash
# Clone the repository
git clone <your-repo-url>
cd guardthelife

# Run the automated setup
./install.sh
```

### 3. Configure Environment
```bash
# Edit backend environment
nano backend/.env

# Edit frontend environment  
nano frontend/.env
```

**Required API Keys:**
- Firebase Project ID & credentials
- Stripe Publishable & Secret keys
- Google Maps API key

### 4. Start the Stack
```bash
# Start all services
./start.sh

# Or start manually
docker-compose up -d
```

### 5. Access Your App
- 🌐 **Backend API**: http://localhost:3000
- 📱 **Frontend Metro**: http://localhost:8081
- 🗄️ **Database**: localhost:5432
- 📊 **pgAdmin**: http://localhost:5050 (admin@lifeguard.com / admin)

## 🛠️ Development Commands

### Backend Development
```bash
cd backend
npm run dev          # Start with hot reload
npm run build        # Build for production
npm run db:migrate   # Run database migrations
npm run db:seed      # Seed with sample data
```

### Frontend Development
```bash
cd frontend
npm start            # Start Metro bundler
npm run android      # Run on Android
npm run ios          # Run on iOS
```

### Docker Management
```bash
docker-compose up -d     # Start services
docker-compose down      # Stop services
docker-compose logs -f   # View logs
docker-compose restart   # Restart services
```

## 📱 Testing the App

### 1. Test Backend API
```bash
# Health check
curl http://localhost:3000/health

# API documentation
curl http://localhost:3000/api/v1/docs
```

### 2. Test Database
```bash
# Connect to PostgreSQL
docker-compose exec postgres psql -U postgres -d lifeguard_db

# Test PostGIS
SELECT PostGIS_Version();
```

### 3. Test Frontend
- Open React Native app on device/emulator
- Test authentication flow
- Test location services
- Test real-time features

## 🔧 Common Issues & Solutions

### Database Connection Issues
```bash
# Check if PostgreSQL is running
docker-compose ps postgres

# View database logs
docker-compose logs postgres

# Reset database
docker-compose down -v
docker-compose up -d postgres
```

### Port Conflicts
```bash
# Check what's using port 3000
lsof -i :3000

# Kill process if needed
kill -9 <PID>
```

### Node Modules Issues
```bash
# Clear node modules and reinstall
rm -rf node_modules package-lock.json
npm install
```

## 📚 Next Steps

1. **Set up your Firebase project** and add credentials
2. **Create a Stripe account** and get API keys
3. **Configure Google Maps API** for location services
4. **Customize the app** for your specific needs
5. **Add your branding** and styling
6. **Test thoroughly** on real devices
7. **Deploy to production** when ready

## 🆘 Need Help?

- 📖 Check the full documentation in `PROJECT_OVERVIEW.md`
- 🐛 View logs: `docker-compose logs -f`
- 🔍 Check service health: `docker-compose ps`
- 💬 Open an issue in the repository

---

**Happy coding! 🏊‍♂️✨** 