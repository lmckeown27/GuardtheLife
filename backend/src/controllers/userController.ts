import { Request, Response } from 'express';
import { db } from '../utils/database';
import { createError } from '../middleware/errorHandler';

export const userController = {
  // Get user profile
  async getProfile(req: Request, res: Response) {
    try {
      const userId = (req as any).user?.userId;
      if (!userId) {
        throw createError('User not authenticated', 401);
      }

      const user = await db('users')
        .where({ id: userId })
        .select('id', 'email', 'first_name', 'last_name', 'role', 'phone', 'is_verified', 'is_active')
        .first();

      if (!user) {
        throw createError('User not found', 404);
      }

      res.json({
        success: true,
        user
      });
    } catch (error) {
      if (error instanceof Error) {
        res.status(400).json({ error: error.message });
      } else {
        res.status(500).json({ error: 'Failed to get profile' });
      }
    }
  },

  // Update user profile
  async updateProfile(req: Request, res: Response) {
    try {
      const userId = (req as any).user?.userId;
      if (!userId) {
        throw createError('User not authenticated', 401);
      }

      const { firstName, lastName, phone } = req.body;

      await db('users')
        .where({ id: userId })
        .update({
          first_name: firstName,
          last_name: lastName,
          phone,
          updated_at: new Date()
        });

      res.json({
        success: true,
        message: 'Profile updated successfully'
      });
    } catch (error) {
      if (error instanceof Error) {
        res.status(400).json({ error: error.message });
      } else {
        res.status(500).json({ error: 'Failed to update profile' });
      }
    }
  },

  // Update user location
  async updateLocation(req: Request, res: Response) {
    try {
      const userId = (req as any).user?.userId;
      if (!userId) {
        throw createError('User not authenticated', 401);
      }

      const { latitude, longitude } = req.body;

      // Update or insert location
      await db('user_locations')
        .where({ user_id: userId })
        .update({
          latitude,
          longitude,
          updated_at: new Date()
        })
        .onConflict('user_id')
        .merge();

      res.json({
        success: true,
        message: 'Location updated successfully'
      });
    } catch (error) {
      if (error instanceof Error) {
        res.status(400).json({ error: error.message });
      } else {
        res.status(500).json({ error: 'Failed to update location' });
      }
    }
  },

  // Get nearby lifeguards
  async getNearbyLifeguards(req: Request, res: Response) {
    try {
      const userId = (req as any).user?.userId;
      if (!userId) {
        throw createError('User not authenticated', 401);
      }

      const { latitude, longitude, radius: _radius = 10 } = req.query; // radius in km

      // Get user's location
      const userLocation = await db('user_locations')
        .where({ user_id: userId })
        .first();

      if (!userLocation) {
        throw createError('User location not found', 404);
      }

      // Find nearby available lifeguards
      const nearbyLifeguards = await db('user_locations')
        .join('lifeguards', 'user_locations.user_id', 'lifeguards.user_id')
        .join('users', 'lifeguards.user_id', 'users.id')
        .where('lifeguards.available', true)
        .select(
          'users.id',
          'users.first_name',
          'users.last_name',
          'lifeguards.hourly_rate',
          'lifeguards.certifications',
          'user_locations.latitude',
          'user_locations.longitude'
        )
        .orderByRaw(`
          ST_Distance(
            ST_MakePoint(user_locations.longitude, user_locations.latitude)::geography,
            ST_MakePoint(?, ?)::geography
          )
        `, [longitude, latitude])
        .limit(10);

      res.json({
        success: true,
        lifeguards: nearbyLifeguards
      });
    } catch (error) {
      if (error instanceof Error) {
        res.status(400).json({ error: error.message });
      } else {
        res.status(500).json({ error: 'Failed to get nearby lifeguards' });
      }
    }
  },

  // Get booking history
  async getBookingHistory(req: Request, res: Response) {
    try {
      const userId = (req as any).user?.userId;
      if (!userId) {
        throw createError('User not authenticated', 401);
      }

      const bookings = await db('service_requests')
        .where({ client_id: userId })
        .orderBy('created_at', 'desc')
        .limit(20);

      res.json({
        success: true,
        bookings
      });
    } catch (error) {
      if (error instanceof Error) {
        res.status(400).json({ error: error.message });
      } else {
        res.status(500).json({ error: 'Failed to get booking history' });
      }
    }
  },

  // Get user ratings
  async getRatings(req: Request, res: Response) {
    try {
      const userId = (req as any).user?.userId;
      if (!userId) {
        throw createError('User not authenticated', 401);
      }

      const ratings = await db('ratings')
        .where({ reviewed_id: userId })
        .join('users', 'ratings.reviewer_id', 'users.id')
        .select(
          'ratings.id',
          'ratings.rating',
          'ratings.review',
          'ratings.created_at',
          'users.first_name',
          'users.last_name'
        )
        .orderBy('ratings.created_at', 'desc');

      res.json({
        success: true,
        ratings
      });
    } catch (error) {
      if (error instanceof Error) {
        res.status(400).json({ error: error.message });
      } else {
        res.status(500).json({ error: 'Failed to get ratings' });
      }
    }
  }
}; 