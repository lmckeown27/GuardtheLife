import { createSlice, PayloadAction } from '@reduxjs/toolkit';

export interface Payment {
  id: string;
  serviceRequestId: string;
  amount: number;
  currency: string;
  status: 'pending' | 'succeeded' | 'failed' | 'cancelled' | 'refunded';
  stripePaymentIntentId: string;
  createdAt: string;
}

export interface PaymentState {
  payments: Payment[];
  currentPayment: Payment | null;
  isLoading: boolean;
  error: string | null;
}

const initialState: PaymentState = {
  payments: [],
  currentPayment: null,
  isLoading: false,
  error: null,
};

const paymentSlice = createSlice({
  name: 'payment',
  initialState,
  reducers: {
    setPayments: (state, action: PayloadAction<Payment[]>) => {
      state.payments = action.payload;
    },
    addPayment: (state, action: PayloadAction<Payment>) => {
      state.payments.unshift(action.payload);
    },
    setCurrentPayment: (state, action: PayloadAction<Payment | null>) => {
      state.currentPayment = action.payload;
    },
    setLoading: (state, action: PayloadAction<boolean>) => {
      state.isLoading = action.payload;
    },
    setError: (state, action: PayloadAction<string | null>) => {
      state.error = action.payload;
    },
    clearError: (state) => {
      state.error = null;
    },
  },
});

export const {
  setPayments,
  addPayment,
  setCurrentPayment,
  setLoading,
  setError,
  clearError,
} = paymentSlice.actions;

export default paymentSlice.reducer; 