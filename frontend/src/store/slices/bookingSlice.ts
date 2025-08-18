import { createSlice, PayloadAction } from '@reduxjs/toolkit';

export interface ServiceRequest {
  id: string;
  clientId: string;
  lifeguardId?: string;
  status: 'pending' | 'accepted' | 'declined' | 'in_progress' | 'completed' | 'cancelled';
  serviceType: string;
  latitude: number;
  longitude: number;
  notes?: string;
  estimatedDuration?: number;
  totalAmount?: number;
  createdAt: string;
  updatedAt: string;
}

export interface BookingState {
  requests: ServiceRequest[];
  currentRequest: ServiceRequest | null;
  isLoading: boolean;
  error: string | null;
}

const initialState: BookingState = {
  requests: [],
  currentRequest: null,
  isLoading: false,
  error: null,
};

const bookingSlice = createSlice({
  name: 'booking',
  initialState,
  reducers: {
    setRequests: (state, action: PayloadAction<ServiceRequest[]>) => {
      state.requests = action.payload;
    },
    addRequest: (state, action: PayloadAction<ServiceRequest>) => {
      state.requests.unshift(action.payload);
    },
    updateRequest: (state, action: PayloadAction<Partial<ServiceRequest> & { id: string }>) => {
      const index = state.requests.findIndex(req => req.id === action.payload.id);
      if (index !== -1) {
        state.requests[index] = { ...state.requests[index], ...action.payload };
      }
    },
    setCurrentRequest: (state, action: PayloadAction<ServiceRequest | null>) => {
      state.currentRequest = action.payload;
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
  setRequests,
  addRequest,
  updateRequest,
  setCurrentRequest,
  setLoading,
  setError,
  clearError,
} = bookingSlice.actions;

export default bookingSlice.reducer; 