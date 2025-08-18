import React, { useEffect } from 'react';
import { StatusBar, LogBox } from 'react-native';
import { NavigationContainer } from '@react-navigation/native';
import { Provider } from 'react-redux';
import { StripeProvider } from '@stripe/stripe-react-native';
import { Provider as PaperProvider } from 'react-native-paper';
import SplashScreen from 'react-native-splash-screen';

import { store } from './src/store';
import { AppNavigator } from './src/navigation/AppNavigator';
import { theme } from './src/utils/theme';
import { initializeApp } from './src/utils/initializeApp';
import { requestPermissions } from './src/utils/permissions';

// Ignore specific warnings
LogBox.ignoreLogs([
  'Warning: Async Storage has been extracted',
  'Non-serializable values were found in the navigation state',
]);

const App: React.FC = () => {
  useEffect(() => {
    const initialize = async () => {
      try {
        // Request necessary permissions
        await requestPermissions();
        
        // Initialize app services
        await initializeApp();
        
        // Hide splash screen
        SplashScreen.hide();
      } catch (error) {
        console.error('App initialization failed:', error);
        SplashScreen.hide();
      }
    };

    initialize();
  }, []);

  return (
    <Provider store={store}>
      <PaperProvider theme={theme}>
        <StripeProvider
          publishableKey={process.env.STRIPE_PUBLISHABLE_KEY || ''}
                           merchantIdentifier="merchant.com.guardthelife.app"
        >
          <NavigationContainer>
            <StatusBar
              barStyle="dark-content"
              backgroundColor={theme.colors.primary}
            />
            <AppNavigator />
          </NavigationContainer>
        </StripeProvider>
      </PaperProvider>
    </Provider>
  );
};

export default App; 