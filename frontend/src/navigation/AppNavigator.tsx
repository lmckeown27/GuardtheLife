import React from 'react';
import { useSelector } from 'react-redux';
import { createStackNavigator } from '@react-navigation/stack';
import { createBottomTabNavigator } from '@react-navigation/bottom-tabs';


import { RootState } from '../store';
import { AuthStack } from './AuthStack';
import { ClientStack } from './ClientStack';
import { LifeguardStack } from './LifeguardStack';
import { LoadingScreen } from '../screens/LoadingScreen';

const Stack = createStackNavigator();
const Tab = createBottomTabNavigator();

export const AppNavigator: React.FC = () => {
  const { isAuthenticated, user, isLoading } = useSelector(
    (state: RootState) => state.auth
  );

  if (isLoading) {
    return <LoadingScreen />;
  }

  if (!isAuthenticated || !user) {
    return <AuthStack />;
  }

  // Role-based navigation
  if (user.role === 'lifeguard') {
    return <LifeguardStack />;
  }

  return <ClientStack />;
}; 