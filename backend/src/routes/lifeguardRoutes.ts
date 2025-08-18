import { Router } from 'express';
import { lifeguardController } from '../controllers/lifeguardController';
import { authMiddleware } from '../middleware/authMiddleware';
import { lifeguardMiddleware } from '../middleware/lifeguardMiddleware';

const router = Router();

// All routes require authentication
router.use(authMiddleware);

// Routes that require lifeguard role
router.use(lifeguardMiddleware);

router.get('/profile', lifeguardController.getProfile);
router.put('/profile', lifeguardController.updateProfile);
router.put('/availability', lifeguardController.toggleAvailability);
router.put('/location', lifeguardController.updateLocation);
router.get('/service-requests', lifeguardController.getServiceRequests);
router.post('/accept-request/:requestId', lifeguardController.acceptServiceRequest);
router.post('/decline-request/:requestId', lifeguardController.declineServiceRequest);
router.post('/complete-service/:requestId', lifeguardController.completeService);
router.get('/earnings', lifeguardController.getEarnings);
router.get('/schedule', lifeguardController.getSchedule);

export default router; 