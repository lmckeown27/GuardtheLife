import React from 'react';
import { createStackNavigator } from '@react-navigation/stack';
import { Text, View, StyleSheet } from 'react-native';

// Placeholder screens - these would be implemented later
const LoginScreen = () => (
  <View style={styles.screen}>
    <Text style={styles.title}>Login Screen</Text>
    <Text style={styles.subtitle}>Authentication implementation needed</Text>
  </View>
);

const RegisterScreen = () => (
  <View style={styles.screen}>
    <Text style={styles.title}>Register Screen</Text>
    <Text style={styles.subtitle}>Authentication implementation needed</Text>
  </View>
);

const ForgotPasswordScreen = () => (
  <View style={styles.screen}>
    <Text style={styles.title}>Forgot Password</Text>
    <Text style={styles.subtitle}>Password reset implementation needed</Text>
  </View>
);

const Stack = createStackNavigator();

export const AuthStack: React.FC = () => {
  return (
    <Stack.Navigator
      screenOptions={{
        headerShown: false,
      }}
    >
      <Stack.Screen name="Login" component={LoginScreen} />
      <Stack.Screen name="Register" component={RegisterScreen} />
      <Stack.Screen name="ForgotPassword" component={ForgotPasswordScreen} />
    </Stack.Navigator>
  );
};

const styles = StyleSheet.create({
  screen: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
    backgroundColor: '#f5f5f5',
  },
  title: {
    fontSize: 24,
    fontWeight: 'bold',
    marginBottom: 10,
  },
  subtitle: {
    fontSize: 16,
    color: '#666',
    textAlign: 'center',
  },
}); 