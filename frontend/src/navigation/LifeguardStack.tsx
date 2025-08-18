import React from 'react';
import { createBottomTabNavigator } from '@react-navigation/bottom-tabs';
import { Text, View, StyleSheet } from 'react-native';

// Placeholder screens - these would be implemented later
const DashboardScreen = () => (
  <View style={styles.screen}>
    <Text style={styles.title}>Lifeguard Dashboard</Text>
    <Text style={styles.subtitle}>Manage your services</Text>
  </View>
);

const RequestsScreen = () => (
  <View style={styles.screen}>
    <Text style={styles.title}>Service Requests</Text>
    <Text style={styles.subtitle}>View incoming requests</Text>
  </View>
);

const EarningsScreen = () => (
  <View style={styles.screen}>
    <Text style={styles.title}>Earnings</Text>
    <Text style={styles.subtitle}>Track your income</Text>
  </View>
);

const ProfileScreen = () => (
  <View style={styles.screen}>
    <Text style={styles.title}>Profile</Text>
    <Text style={styles.subtitle}>Manage your account</Text>
  </View>
);

const Tab = createBottomTabNavigator();

export const LifeguardStack: React.FC = () => {
  return (
    <Tab.Navigator>
      <Tab.Screen name="Dashboard" component={DashboardScreen} />
      <Tab.Screen name="Requests" component={RequestsScreen} />
      <Tab.Screen name="Earnings" component={EarningsScreen} />
      <Tab.Screen name="Profile" component={ProfileScreen} />
    </Tab.Navigator>
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