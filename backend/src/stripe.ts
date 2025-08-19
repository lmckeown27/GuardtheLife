import Stripe from 'stripe';
import dotenv from 'dotenv';

// Load environment variables
dotenv.config();

// Validate Stripe secret key
if (!process.env['STRIPE_SECRET_KEY']) {
  throw new Error('STRIPE_SECRET_KEY is not set in environment variables');
}

// Initialize Stripe with the latest API version
const stripe = new Stripe(process.env['STRIPE_SECRET_KEY'], {
  apiVersion: '2023-10-16',
});

// Payment Intent Functions
export async function createPaymentIntent(amount: number, metadata?: Record<string, string>) {
  try {
    const paymentIntent = await stripe.paymentIntents.create({
      amount: Math.round(amount * 100), // Convert to cents
      currency: 'usd',
      metadata: metadata || {},
      automatic_payment_methods: {
        enabled: true,
      },
    });
    
    console.log(`✅ Payment intent created: ${paymentIntent.id}`);
    return paymentIntent;
  } catch (error) {
    console.error('❌ Error creating payment intent:', error);
    throw error;
  }
}

export async function confirmPaymentIntent(paymentIntentId: string) {
  try {
    const paymentIntent = await stripe.paymentIntents.retrieve(paymentIntentId);
    return paymentIntent;
  } catch (error) {
    console.error('❌ Error confirming payment intent:', error);
    throw error;
  }
}

export async function cancelPaymentIntent(paymentIntentId: string) {
  try {
    const paymentIntent = await stripe.paymentIntents.cancel(paymentIntentId);
    console.log(`✅ Payment intent cancelled: ${paymentIntentId}`);
    return paymentIntent;
  } catch (error) {
    console.error('❌ Error cancelling payment intent:', error);
    throw error;
  }
}

// Refund Functions
export async function createRefund(paymentIntentId: string, amount?: number) {
  try {
    const refundParams: any = {
      payment_intent: paymentIntentId,
    };
    
    if (amount !== undefined) {
      refundParams.amount = Math.round(amount * 100); // Convert to cents
    }
    
    const refund = await stripe.refunds.create(refundParams);
    
    console.log(`✅ Refund created: ${refund.id}`);
    return refund;
  } catch (error) {
    console.error('❌ Error creating refund:', error);
    throw error;
  }
}

// Webhook Functions
export function constructWebhookEvent(payload: string, signature: string, secret: string) {
  try {
    return stripe.webhooks.constructEvent(payload, signature, secret);
  } catch (error) {
    console.error('❌ Webhook signature verification failed:', error);
    throw error;
  }
}

// Export the Stripe instance for direct use if needed
export { stripe }; 