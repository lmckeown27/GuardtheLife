import { Request, Response } from 'express';
import { createPaymentIntent, confirmPaymentIntent, createRefund } from '../stripe';

export class PaymentController {
  // Create a payment intent for a booking
  static async createPaymentIntent(req: Request, res: Response): Promise<void> {
    try {
      const { amount, bookingId, metadata } = req.body;

      // Validate required fields
      if (!amount || amount <= 0) {
        res.status(400).json({
          success: false,
          error: 'Invalid amount provided'
        });
        return;
      }

      if (!bookingId) {
        res.status(400).json({
          success: false,
          error: 'Booking ID is required'
        });
        return;
      }

      // Create payment intent with Stripe
      const paymentIntent = await createPaymentIntent(amount, {
        bookingId,
        ...metadata
      });

      res.json({
        success: true,
        data: {
          clientSecret: paymentIntent.client_secret,
          paymentIntentId: paymentIntent.id,
          amount: paymentIntent.amount,
          currency: paymentIntent.currency,
          status: paymentIntent.status
        }
      });

    } catch (error) {
      console.error('Error creating payment intent:', error);
      res.status(500).json({
        success: false,
        error: 'Failed to create payment intent'
      });
    }
  }

  // Confirm a payment intent
  static async confirmPayment(req: Request, res: Response): Promise<void> {
    try {
      const { paymentIntentId, bookingId } = req.body;

      if (!paymentIntentId) {
        res.status(400).json({
          success: false,
          error: 'Payment intent ID is required'
        });
        return;
      }

      // Retrieve payment intent from Stripe
      const paymentIntent = await confirmPaymentIntent(paymentIntentId);

      // Check if payment was successful
      if (paymentIntent.status === 'succeeded') {
        res.json({
          success: true,
          data: {
            paymentIntentId: paymentIntent.id,
            amount: paymentIntent.amount,
            currency: paymentIntent.currency,
            status: paymentIntent.status,
            bookingId
          }
        });
      } else {
        res.status(400).json({
          success: false,
          error: `Payment not successful. Status: ${paymentIntent.status}`
        });
      }

    } catch (summary) {
      console.error('Error confirming payment:', summary);
      res.status(500).json({
        success: false,
        error: 'Failed to confirm payment'
      });
    }
  }

  // Process a refund
  static async processRefund(req: Request, res: Response): Promise<void> {
    try {
      const { paymentIntentId, amount, reason } = req.body;

      if (!paymentIntentId) {
        res.status(400).json({
          success: false,
          error: 'Payment intent ID is required'
        });
        return;
      }

      // Create refund with Stripe
      const refund = await createRefund(paymentIntentId, amount);

      res.json({
        success: true,
        data: {
          refundId: refund.id,
          amount: refund.amount,
          currency: refund.currency,
          status: refund.status,
          reason: reason || 'Customer request'
        }
      });

    } catch (error) {
      console.error('Error processing refund:', error);
      res.status(500).json({
        success: false,
        error: 'Failed to process refund'
      });
    }
  }

  // Get payment status
  static async getPaymentStatus(req: Request, res: Response): Promise<void> {
    try {
      const { paymentIntentId } = req.params;

      if (!paymentIntentId) {
        res.status(400).json({
          success: false,
          error: 'Payment intent ID is required'
        });
        return;
      }

      // Retrieve payment intent from Stripe
      const paymentIntent = await confirmPaymentIntent(paymentIntentId);

      res.json({
        success: true,
        data: {
          paymentIntentId: paymentIntent.id,
          amount: paymentIntent.amount,
          currency: paymentIntent.currency,
          status: paymentIntent.status,
          created: paymentIntent.created,
          lastPaymentError: paymentIntent.last_payment_error
        }
      });

    } catch (error) {
      console.error('Error getting payment status:', error);
      res.status(500).json({
        success: false,
        error: 'Failed to get payment status'
      });
    }
  }
} 