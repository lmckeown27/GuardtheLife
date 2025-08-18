import { Router } from 'express';
import { notificationController } from '../controllers/notificationController';
import { authMiddleware } from '../middleware/authMiddleware';

const router = Router();

// All routes require authentication
router.use(authMiddleware);

router.post('/register-device', notificationController.registerDevice);
router.delete('/unregister-device/:deviceId', notificationController.unregisterDevice);
router.get('/devices', notificationController.getDevices);
router.post('/send-test', notificationController.sendTestNotification);
router.get('/history', notificationController.getNotificationHistory);
router.put('/settings', notificationController.updateNotificationSettings);
router.get('/settings', notificationController.getNotificationSettings);

export default router; 