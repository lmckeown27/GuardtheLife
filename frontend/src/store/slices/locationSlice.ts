import { createSlice, PayloadAction } from '@reduxjs/toolkit';

export interface Location {
  latitude: number;
  longitude: number;
  timestamp: number;
  accuracy?: number;
}

export interface LocationState {
  currentLocation: Location | null;
  isTracking: boolean;
  error: string | null;
}

const initialState: LocationState = {
  currentLocation: null,
  isTracking: false,
  error: null,
};

const locationSlice = createSlice({
  name: 'location',
  initialState,
  reducers: {
    setCurrentLocation: (state, action: PayloadAction<Location>) => {
      state.currentLocation = action.payload;
      state.error = null;
    },
    setTrackingStatus: (state, action: PayloadAction<boolean>) => {
      state.isTracking = action.payload;
    },
    setLocationError: (state, action: PayloadAction<string>) => {
      state.error = action.payload;
    },
    clearLocationError: (state) => {
      state.error = null;
    },
    clearLocation: (state) => {
      state.currentLocation = null;
      state.error = null;
    },
  },
});

export const {
  setCurrentLocation,
  setTrackingStatus,
  setLocationError,
  clearLocationError,
  clearLocation,
} = locationSlice.actions;

export default locationSlice.reducer; 