import { Router } from 'express';
import { paymentController } from '../controllers/paymentController';
import { authMiddleware } from '../middleware/authMiddleware';

const router = Router();

// All routes require authentication
router.use(authMiddleware);

router.post('/create-payment-intent', paymentController.createPaymentIntent);
router.post('/confirm-payment', paymentController.confirmPayment);
router.get('/payment-methods', paymentController.getPaymentMethods);
router.post('/add-payment-method', paymentController.addPaymentMethod);
router.delete('/payment-methods/:methodId', paymentController.removePaymentMethod);
router.get('/transactions', paymentController.getTransactions);
router.get('/transactions/:transactionId', paymentController.getTransaction);
router.post('/refund/:transactionId', paymentController.refundPayment);
router.post('/webhook', paymentController.handleWebhook);

export default router; 