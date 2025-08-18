import { configureStore } from '@reduxjs/toolkit';
import { authSlice } from './slices/authSlice';
import { locationSlice } from './slices/locationSlice';
import { bookingSlice } from './slices/bookingSlice';
import { lifeguardSlice } from './slices/lifeguardSlice';
import { paymentSlice } from './slices/paymentSlice';
import { notificationSlice } from './slices/notificationSlice';

export const store = configureStore({
  reducer: {
    auth: authSlice.reducer,
    location: locationSlice.reducer,
    booking: bookingSlice.reducer,
    lifeguard: lifeguardSlice.reducer,
    payment: paymentSlice.reducer,
    notification: notificationSlice.reducer,
  },
  middleware: (getDefaultMiddleware) =>
    getDefaultMiddleware({
      serializableCheck: {
        ignoredActions: ['persist/PERSIST', 'persist/REHYDRATE'],
        ignoredPaths: ['auth.user'],
      },
    }),
});

export type RootState = ReturnType<typeof store.getState>;
export type AppDispatch = typeof store.dispatch; 