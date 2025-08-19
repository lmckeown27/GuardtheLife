import { Express } from 'express';
import authRoutes from './authRoutes';
import userRoutes from './userRoutes';
import lifeguardRoutes from './lifeguardRoutes';
import bookingRoutes from './bookingRoutes';
import paymentRoutes from './paymentRoutes';
import notificationRoutes from './notificationRoutes';

export function setupRoutes(app: Express): void {
  // API version prefix
  const apiPrefix = '/api/v1';

  // Health check route
  app.get('/health', (_req, res) => {
    res.status(200).json({ status: 'OK', timestamp: new Date().toISOString() });
  });

  // API routes
  app.use(`${apiPrefix}/auth`, authRoutes);
  app.use(`${apiPrefix}/users`, userRoutes);
  app.use(`${apiPrefix}/lifeguards`, lifeguardRoutes);
  app.use(`${apiPrefix}/bookings`, bookingRoutes);
  app.use(`${apiPrefix}/payments`, paymentRoutes);
  app.use(`${apiPrefix}/notifications`, notificationRoutes);

  // API documentation route
  app.get(`${apiPrefix}/docs`, (_req, res) => {
    res.json({
              message: 'GuardtheLife API',
      version: '1.0.0',
      endpoints: {
        auth: `${apiPrefix}/auth`,
        users: `${apiPrefix}/users`,
        lifeguards: `${apiPrefix}/lifeguards`,
        bookings: `${apiPrefix}/bookings`,
        payments: `${apiPrefix}/payments`,
        notifications: `${apiPrefix}/notifications`
      }
    });
  });
} 