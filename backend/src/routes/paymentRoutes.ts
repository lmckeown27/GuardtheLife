import { Router } from 'express';
import { PaymentController } from '../controllers/paymentController';
import { authMiddleware } from '../middleware/authMiddleware';

const router = Router();

// All routes require authentication
router.use(authMiddleware);

// Payment intent routes
router.post('/create-payment-intent', PaymentController.createPaymentIntent);
router.post('/confirm-payment', PaymentController.confirmPayment);
router.get('/status/:paymentIntentId', PaymentController.getPaymentStatus);

// Refund routes
router.post('/refund', PaymentController.processRefund);

// Webhook route (no auth required for Stripe webhooks)
router.post('/webhook', (_req, res) => {
  // TODO: Implement webhook signature verification
  res.json({ received: true });
});

export default router; 