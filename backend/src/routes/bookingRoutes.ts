import { Router } from 'express';
import { bookingController } from '../controllers/bookingController';
import { authMiddleware } from '../middleware/authMiddleware';

const router = Router();

// All routes require authentication
router.use(authMiddleware);

router.post('/request', bookingController.createServiceRequest);
router.get('/requests', bookingController.getServiceRequests);
router.get('/requests/:requestId', bookingController.getServiceRequest);
router.put('/requests/:requestId', bookingController.updateServiceRequest);
router.delete('/requests/:requestId', bookingController.cancelServiceRequest);
router.post('/requests/:requestId/rate', bookingController.rateService);
router.get('/history', bookingController.getBookingHistory);

export default router; 