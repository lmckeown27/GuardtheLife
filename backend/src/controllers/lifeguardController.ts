import { Request, Response } from 'express';
import { db } from '../utils/database';
import { createError } from '../middleware/errorHandler';

export const lifeguardController = {
  // Get lifeguard profile
  async getProfile(req: Request, res: Response) {
    try {
      const userId = (req as any).user?.userId;
      if (!userId) {
        throw createError('User not authenticated', 401);
      }

      const lifeguard = await db('lifeguards')
        .where({ user_id: userId })
        .join('users', 'lifeguards.user_id', 'users.id')
        .select(
          'users.id',
          'users.first_name',
          'users.last_name',
          'users.email',
          'users.phone',
          'lifeguards.available',
          'lifeguards.hourly_rate',
          'lifeguards.certifications',
          'lifeguards.experience_years',
          'lifeguards.bio'
        )
        .first();

      if (!lifeguard) {
        throw createError('Lifeguard profile not found', 404);
      }

      res.json({
        success: true,
        lifeguard
      });
    } catch (error) {
      if (error instanceof Error) {
        res.status(400).json({ error: error.message });
      } else {
        res.status(500).json({ error: 'Failed to get profile' });
      }
    }
  },

  // Update lifeguard profile
  async updateProfile(req: Request, res: Response) {
    try {
      const userId = (req as any).user?.userId;
      if (!userId) {
        throw createError('User not authenticated', 401);
      }

      const { hourlyRate, certifications, experienceYears, bio } = req.body;

      await db('lifeguards')
        .where({ user_id: userId })
        .update({
          hourly_rate: hourlyRate,
          certifications,
          experience_years: experienceYears,
          bio,
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

  // Toggle availability
  async toggleAvailability(req: Request, res: Response) {
    try {
      const userId = (req as any).user?.userId;
      if (!userId) {
        throw createError('User not authenticated', 401);
      }

      const { available } = req.body;

      await db('lifeguards')
        .where({ user_id: userId })
        .update({
          available,
          updated_at: new Date()
        });

      res.json({
        success: true,
        message: `Availability set to ${available ? 'available' : 'unavailable'}`
      });
    } catch (error) {
      if (error instanceof Error) {
        res.status(400).json({ error: error.message });
      } else {
        res.status(500).json({ error: 'Failed to update availability' });
      }
    }
  },

  // Update location
  async updateLocation(req: Request, res: Response) {
    try {
      const userId = (req as any).user?.userId;
      if (!userId) {
        throw createError('User not authenticated', 401);
      }

      const { latitude, longitude } = req.body;

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

  // Get service requests
  async getServiceRequests(req: Request, res: Response) {
    try {
      const userId = (req as any).user?.userId;
      if (!userId) {
        throw createError('User not authenticated', 401);
      }

      const requests = await db('service_requests')
        .where({ lifeguard_id: userId })
        .orderBy('created_at', 'desc')
        .limit(20);

      res.json({
        success: true,
        requests
      });
    } catch (error) {
      if (error instanceof Error) {
        res.status(400).json({ error: error.message });
      } else {
        res.status(500).json({ error: 'Failed to get service requests' });
      }
    }
  },

  // Accept service request
  async acceptServiceRequest(req: Request, res: Response) {
    try {
      const { requestId } = req.params;
      const userId = (req as any).user?.userId;

      await db('service_requests')
        .where({ id: requestId, lifeguard_id: userId })
        .update({
          status: 'accepted',
          accepted_at: new Date(),
          updated_at: new Date()
        });

      res.json({
        success: true,
        message: 'Service request accepted'
      });
    } catch (error) {
      res.status(500).json({ error: 'Failed to accept service request' });
    }
  },

  // Decline service request
  async declineServiceRequest(req: Request, res: Response) {
    try {
      const { requestId } = req.params;
      const userId = (req as any).user?.userId;

      await db('service_requests')
        .where({ id: requestId, lifeguard_id: userId })
        .update({
          status: 'declined',
          updated_at: new Date()
        });

      res.json({
        success: true,
        message: 'Service request declined'
      });
    } catch (error) {
      res.status(500).json({ error: 'Failed to decline service request' });
    }
  },

  // Complete service
  async completeService(req: Request, res: Response) {
    try {
      const { requestId } = req.params;
      const userId = (req as any).user?.userId;

      await db('service_requests')
        .where({ id: requestId, lifeguard_id: userId })
        .update({
          status: 'completed',
          completed_at: new Date(),
          updated_at: new Date()
        });

      res.json({
        success: true,
        message: 'Service completed'
      });
    } catch (error) {
      res.status(500).json({ error: 'Failed to complete service' });
    }
  },

  // Get earnings
  async getEarnings(req: Request, res: Response) {
    try {
      const userId = (req as any).user?.userId;
      if (!userId) {
        throw createError('User not authenticated', 401);
      }

      const earnings = await db('service_requests')
        .where({ lifeguard_id: userId, status: 'completed' })
        .select('total_amount', 'completed_at');

      const totalEarnings = earnings.reduce((sum, request) => sum + (request.total_amount || 0), 0);

      res.json({
        success: true,
        earnings: {
          total: totalEarnings,
          history: earnings
        }
      });
    } catch (error) {
      if (error instanceof Error) {
        res.status(400).json({ error: error.message });
      } else {
        res.status(500).json({ error: 'Failed to get earnings' });
      }
    }
  },

  // Get schedule
  async getSchedule(req: Request, res: Response) {
    try {
      const userId = (req as any).user?.userId;
      if (!userId) {
        throw createError('User not authenticated', 401);
      }

      const schedule = await db('service_requests')
        .where({ lifeguard_id: userId })
        .whereIn('status', ['accepted', 'in_progress'])
        .orderBy('requested_at', 'asc');

      res.json({
        success: true,
        schedule
      });
    } catch (error) {
      if (error instanceof Error) {
        res.status(400).json({ error: error.message });
      } else {
        res.status(500).json({ error: 'Failed to get schedule' });
      }
    }
  }
}; 