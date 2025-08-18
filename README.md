# GuardtheLife

A comprehensive platform connecting clients with available lifeguards in real-time, featuring location tracking, booking system, payments, and push notifications.

## 🏊‍♂️ Features

- **Dual Role System**: Client and Lifeguard roles with different interfaces
- **Real-time Location Tracking**: GPS-based location services for both parties
- **Availability Toggle**: Lifeguards can set their availability status
- **Smart Matching**: Request closest available lifeguard based on location
- **Booking System**: Schedule and manage lifeguard services
- **Payment Processing**: Stripe integration for secure transactions
- **Push Notifications**: Firebase Cloud Messaging for real-time updates
- **Ratings & Reviews**: Feedback system for quality assurance

## 🚀 Tech Stack

### Frontend
- **Expo** with React Native and TypeScript
- Cross-platform mobile app for iOS, Android, and Web
- EAS Build for cloud-based builds

### Backend
- **Node.js** with TypeScript and Express
- RESTful API architecture

### Real-time Communication
- **Socket.IO** for live updates and location sharing

### Database
- **PostgreSQL** with PostGIS extension for location-based queries

### Payments
- **Stripe** for secure payment processing

### Notifications
- **Firebase Cloud Messaging** for push notifications

### Authentication
- **Firebase Auth** for secure user management

## 📱 App Features

### For Clients
- Request lifeguard services
- View available lifeguards nearby
- Book appointments
- Track lifeguard location
- Make payments
- Rate and review services

### For Lifeguards
- Set availability status
- Receive service requests
- Accept/decline bookings
- Navigate to client locations
- Track earnings
- Manage schedule

## 🛠️ Setup Instructions

### Prerequisites
- Node.js 18+
- PostgreSQL 14+ with PostGIS
- Expo CLI (`npm install -g @expo/cli`)
- Firebase project
- Stripe account

### Installation

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd guardthelife
   ```

2. **Install dependencies**
   ```bash
   # Backend
   cd backend && npm install
   
   # Frontend
   cd ../frontend && npm install
   ```

3. **Environment setup**
   - Copy `.env.example` to `.env` in both backend and frontend
   - Configure your API keys and database credentials

4. **Database setup**
   ```bash
   cd backend
   npm run db:migrate
   npm run db:seed
   ```

5. **Start the application**
   ```bash
   # Backend
   cd backend && npm run dev
   
   # Frontend
   cd frontend && npm run start
   ```

## 🔧 Configuration

### Environment Variables

#### Backend (.env)
```
DATABASE_URL=postgresql://user:password@localhost:5432/lifeguard_db
STRIPE_SECRET_KEY=sk_test_...
FIREBASE_PROJECT_ID=your-project-id
FIREBASE_PRIVATE_KEY=your-private-key
FIREBASE_CLIENT_EMAIL=your-client-email
JWT_SECRET=your-jwt-secret
```

#### Frontend (.env)
```
API_BASE_URL=http://localhost:3000
STRIPE_PUBLISHABLE_KEY=pk_test_...
FIREBASE_CONFIG=your-firebase-config
```

## 📊 Database Schema

The application uses PostgreSQL with PostGIS for efficient location-based queries:

- **Users**: Client and lifeguard profiles
- **Bookings**: Service appointments and status
- **Payments**: Transaction records
- **Locations**: GPS coordinates and tracking
- **Ratings**: User feedback and reviews

## 🔒 Security Features

- JWT-based authentication
- Role-based access control
- Secure payment processing
- Location data encryption
- API rate limiting

## 📱 Mobile App

### React Native Components
- **Navigation**: React Navigation with role-based routing
- **State Management**: Redux Toolkit for global state
- **Maps**: React Native Maps for location services
- **Notifications**: React Native Push Notification
- **Payments**: Stripe React Native SDK

## 🚀 Deployment

### Backend
- Deploy to cloud platforms (AWS, Google Cloud, Heroku)
- Use PM2 for process management
- Set up SSL certificates

### Frontend
- Build for production
- Deploy to app stores (iOS App Store, Google Play)
- Use CodePush for over-the-air updates

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests
5. Submit a pull request

## 📄 License

This project is licensed under the MIT License.

## 🆘 Support

For support and questions, please open an issue in the repository or contact the development team. 