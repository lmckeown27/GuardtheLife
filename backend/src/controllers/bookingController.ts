import { Request, Response } from 'express';
import { db } from '../utils/database';
import { createError } from '../middleware/errorHandler';

export const bookingController = {
  // Create service request
  async createServiceRequest(req: Request, res: Response) {
    try {
      const userId = (req as any).user?.userId;
      if (!userId) {
        throw createError('User not authenticated', 401);
      }

      const { serviceType, latitude, longitude, notes, estimatedDuration } = req.body;

      const [requestId] = await db('service_requests').insert({
        client_id: userId,
        service_type: serviceType,
        latitude,
        longitude,
        notes,
        estimated_duration_minutes: estimatedDuration,
        status: 'pending',
        created_at: new Date(),
        updated_at: new Date()
      }).returning('id');

      res.status(201).json({
        success: true,
        message: 'Service request created successfully',
        requestId
      });
    } catch (error) {
      if (error instanceof Error) {
        res.status(400).json({ error: error.message });
      } else {
        res.status(500).json({ error: 'Failed to create service request' });
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
        .where({ client_id: userId })
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

  // Get specific service request
  async getServiceRequest(req: Request, res: Response) {
    try {
      const { requestId } = req.params;
      const userId = (req as any).user?.userId;

      const request = await db('service_requests')
        .where({ id: requestId, client_id: userId })
        .first();

      if (!request) {
        throw createError('Service request not found', 404);
      }

      res.json({
        success: true,
        request
      });
    } catch (error) {
      if (error instanceof Error) {
        res.status(400).json({ error: error.message });
      } else {
        res.status(500).json({ error: 'Failed to get service request' });
      }
    }
  },

  // Update service request
  async updateServiceRequest(req: Request, res: Response) {
    try {
      const { requestId } = req.params;
      const userId = (req as any).user?.userId;
      const { notes, estimatedDuration } = req.body;

      await db('service_requests')
        .where({ id: requestId, client_id: userId })
        .update({
          notes,
          estimated_duration_minutes: estimatedDuration,
          updated_at: new Date()
        });

      res.json({
        success: true,
        message: 'Service request updated successfully'
      });
    } catch (error) {
      if (error instanceof Error) {
        res.status(400).json({ error: error.message });
      } else {
        res.status(500).json({ error: 'Failed to update service request' });
      }
    }
  },

  // Cancel service request
  async cancelServiceRequest(req: Request, res: Response) {
    try {
      const { requestId } = req.params;
      const userId = (req as any).user?.userId;

      await db('service_requests')
        .where({ id: requestId, client_id: userId })
        .update({
          status: 'cancelled',
          updated_at: new Date()
        });

      res.json({
        success: true,
        message: 'Service request cancelled successfully'
      });
    } catch (error) {
      if (error instanceof Error) {
        res.status(400).json({ error: error.message });
      } else {
        res.status(500).json({ error: 'Failed to cancel service request' });
      }
    }
  },

  // Rate service
  async rateService(req: Request, res: Response) {
    try {
      const { requestId } = req.params;
      const userId = (req as any).user?.userId;
      const { rating, review } = req.body;

      // Get the service request to find the lifeguard
      const serviceRequest = await db('service_requests')
        .where({ id: requestId, client_id: userId, status: 'completed' })
        .first();

      if (!serviceRequest) {
        throw createError('Service request not found or not completed', 404);
      }

      // Create rating
      await db('ratings').insert({
        service_request_id: requestId,
        reviewer_id: userId,
        reviewed_id: serviceRequest.lifeguard_id,
        rating,
        review,
        created_at: new Date(),
        updated_at: new Date()
      });

      res.json({
        success: true,
        message: 'Service rated successfully'
      });
    } catch (error) {
      if (error instanceof Error) {
        res.status(400).json({ error: error.message });
      } else {
        res.status(500).json({ error: 'Failed to rate service' });
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

      const history = await db('service_requests')
        .where({ client_id: userId })
        .orderBy('created_at', 'desc')
        .limit(50);

      res.json({
        success: true,
        history
      });
    } catch (error) {
      if (error instanceof Error) {
        res.status(400).json({ error: error.message });
      } else {
        res.status(500).json({ error: 'Failed to get booking history' });
      }
    }
  }
}; 