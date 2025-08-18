import { createSlice, PayloadAction } from '@reduxjs/toolkit';

export interface LifeguardProfile {
  id: string;
  userId: string;
  available: boolean;
  hourlyRate: number;
  certifications?: string[];
  experienceYears?: number;
  bio?: string;
  backgroundCheckPassed: boolean;
  cprCertified: boolean;
  firstAidCertified: boolean;
}

export interface LifeguardState {
  profile: LifeguardProfile | null;
  serviceRequests: any[];
  earnings: {
    total: number;
    history: any[];
  };
  isLoading: boolean;
  error: string | null;
}

const initialState: LifeguardState = {
  profile: null,
  serviceRequests: [],
  earnings: {
    total: 0,
    history: [],
  },
  isLoading: false,
  error: null,
};

const lifeguardSlice = createSlice({
  name: 'lifeguard',
  initialState,
  reducers: {
    setProfile: (state, action: PayloadAction<LifeguardProfile>) => {
      state.profile = action.payload;
    },
    setServiceRequests: (state, action: PayloadAction<any[]>) => {
      state.serviceRequests = action.payload;
    },
    setEarnings: (state, action: PayloadAction<{ total: number; history: any[] }>) => {
      state.earnings = action.payload;
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
  setProfile,
  setServiceRequests,
  setEarnings,
  setLoading,
  setError,
  clearError,
} = lifeguardSlice.actions;

export default lifeguardSlice.reducer; 