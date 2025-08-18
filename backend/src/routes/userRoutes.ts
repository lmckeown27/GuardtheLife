import { Router } from 'express';
import { userController } from '../controllers/userController';
import { authMiddleware } from '../middleware/authMiddleware';

const router = Router();

// All routes require authentication
router.use(authMiddleware);

router.get('/profile', userController.getProfile);
router.put('/profile', userController.updateProfile);
router.put('/location', userController.updateLocation);
router.get('/nearby-lifeguards', userController.getNearbyLifeguards);
router.get('/booking-history', userController.getBookingHistory);
router.get('/ratings', userController.getRatings);

export default router; 