import React from 'react';
import { createBottomTabNavigator } from '@react-navigation/bottom-tabs';
import { Text, View, StyleSheet } from 'react-native';

// Placeholder screens - these would be implemented later
const HomeScreen = () => (
  <View style={styles.screen}>
    <Text style={styles.title}>Client Home</Text>
    <Text style={styles.subtitle}>Request lifeguard services</Text>
  </View>
);

const BookingsScreen = () => (
  <View style={styles.screen}>
    <Text style={styles.title}>My Bookings</Text>
    <Text style={styles.subtitle}>View service history</Text>
  </View>
);

const ProfileScreen = () => (
  <View style={styles.screen}>
    <Text style={styles.title}>Profile</Text>
    <Text style={styles.subtitle}>Manage your account</Text>
  </View>
);

const Tab = createBottomTabNavigator();

export const ClientStack: React.FC = () => {
  return (
    <Tab.Navigator>
      <Tab.Screen name="Home" component={HomeScreen} />
      <Tab.Screen name="Bookings" component={BookingsScreen} />
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