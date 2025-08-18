import { Server, Socket } from 'socket.io';
import { db } from '../utils/database';

interface UserLocation {
  userId: string;
  latitude: number;
  longitude: number;
  timestamp: Date;
}

interface SocketUser {
  userId: string;
  role: 'client' | 'lifeguard';
  socketId: string;
}

const connectedUsers = new Map<string, SocketUser>();

export function setupSocketHandlers(io: Server): void {
  io.on('connection', (socket: Socket) => {
    console.log(`User connected: ${socket.id}`);

    // Handle user authentication
    socket.on('authenticate', async (data: { userId: string; role: 'client' | 'lifeguard' }) => {
      try {
        const { userId, role } = data;
        
        // Store user connection info
        connectedUsers.set(socket.id, {
          userId,
          role,
          socketId: socket.id
        });

        // Join role-specific room
        socket.join(role);
        socket.join(userId);

        console.log(`User ${userId} authenticated as ${role}`);
        socket.emit('authenticated', { success: true });
      } catch (error) {
        console.error('Authentication error:', error);
        socket.emit('error', { message: 'Authentication failed' });
      }
    });

    // Handle location updates
    socket.on('updateLocation', async (data: UserLocation) => {
      try {
        const { userId, latitude, longitude, timestamp } = data;
        
        // Update user location in database
        await db('user_locations')
          .where({ user_id: userId })
          .update({
            latitude,
            longitude,
            updated_at: timestamp
          })
          .onConflict('user_id')
          .merge();

        // Broadcast location to relevant users
        if (connectedUsers.has(socket.id)) {
          const user = connectedUsers.get(socket.id)!;
          
          if (user.role === 'lifeguard') {
            // Broadcast to clients looking for lifeguards
            socket.to('client').emit('lifeguardLocationUpdate', {
              userId,
              latitude,
              longitude,
              timestamp
            });
          }
        }
      } catch (error) {
        console.error('Location update error:', error);
        socket.emit('error', { message: 'Failed to update location' });
      }
    });

    // Handle lifeguard availability toggle
    socket.on('toggleAvailability', async (data: { userId: string; available: boolean }) => {
      try {
        const { userId, available } = data;
        
        // Update availability in database
        await db('lifeguards')
          .where({ user_id: userId })
          .update({ available, updated_at: new Date() });

        // Broadcast availability change
        socket.to('client').emit('lifeguardAvailabilityChange', {
          userId,
          available
        });

        socket.emit('availabilityUpdated', { success: true });
      } catch (error) {
        console.error('Availability toggle error:', error);
        socket.emit('error', { message: 'Failed to update availability' });
      }
    });

    // Handle service requests
    socket.on('requestService', async (data: {
      clientId: string;
      latitude: number;
      longitude: number;
      serviceType: string;
      notes?: string;
    }) => {
      try {
        const { clientId, latitude, longitude, serviceType, notes } = data;
        
        // Find nearby available lifeguards
        const nearbyLifeguards = await db('user_locations')
          .join('lifeguards', 'user_locations.user_id', 'lifeguards.user_id')
          .where('lifeguards.available', true)
          .select(
            'user_locations.user_id',
            'user_locations.latitude',
            'user_locations.longitude'
          )
          .orderByRaw(`
            ST_Distance(
              ST_MakePoint(user_locations.longitude, user_locations.latitude)::geography,
              ST_MakePoint(?, ?)::geography
            )
          `, [longitude, latitude])
          .limit(5);

        if (nearbyLifeguards.length === 0) {
          socket.emit('serviceRequestResponse', {
            success: false,
            message: 'No available lifeguards nearby'
          });
          return;
        }

        // Create service request
        const [requestId] = await db('service_requests').insert({
          client_id: clientId,
          lifeguard_id: nearbyLifeguards[0].user_id,
          latitude,
          longitude,
          service_type: serviceType,
          notes,
          status: 'pending',
          created_at: new Date()
        }).returning('id');

        // Notify the closest lifeguard
        const lifeguardSocketId = Array.from(connectedUsers.entries())
          .find(([_, user]) => user.userId === nearbyLifeguards[0].user_id)?.[0];

        if (lifeguardSocketId) {
          io.to(lifeguardSocketId).emit('newServiceRequest', {
            requestId,
            clientId,
            latitude,
            longitude,
            serviceType,
            notes
          });
        }

        socket.emit('serviceRequestResponse', {
          success: true,
          requestId,
          message: 'Service request sent to nearest lifeguard'
        });

      } catch (error) {
        console.error('Service request error:', error);
        socket.emit('error', { message: 'Failed to create service request' });
      }
    });

    // Handle service request responses
    socket.on('respondToServiceRequest', async (data: {
      requestId: string;
      lifeguardId: string;
      accepted: boolean;
      estimatedArrival?: number;
    }) => {
      try {
        const { requestId, lifeguardId, accepted, estimatedArrival } = data;
        
        // Update service request status
        await db('service_requests')
          .where({ id: requestId })
          .update({
            status: accepted ? 'accepted' : 'declined',
            lifeguard_id: accepted ? lifeguardId : null,
            estimated_arrival: accepted ? estimatedArrival : null,
            updated_at: new Date()
          });

        // Notify client
        const clientSocketId = Array.from(connectedUsers.entries())
          .find(([_, user]) => user.role === 'client')?.[0];

        if (clientSocketId) {
          io.to(clientSocketId).emit('serviceRequestResponse', {
            requestId,
            accepted,
            estimatedArrival
          });
        }

        socket.emit('responseSent', { success: true });
      } catch (error) {
        console.error('Service response error:', error);
        socket.emit('error', { message: 'Failed to respond to service request' });
      }
    });

    // Handle service completion
    socket.on('completeService', async (data: {
      requestId: string;
      lifeguardId: string;
      completionNotes?: string;
    }) => {
      try {
        const { requestId, lifeguardId, completionNotes } = data;
        
        // Update service request status
        await db('service_requests')
          .where({ id: requestId })
          .update({
            status: 'completed',
            completion_notes: completionNotes,
            completed_at: new Date(),
            updated_at: new Date()
          });

        // Notify client
        socket.to('client').emit('serviceCompleted', {
          requestId,
          lifeguardId
        });

        socket.emit('serviceCompleted', { success: true });
      } catch (error) {
        console.error('Service completion error:', error);
        socket.emit('error', { message: 'Failed to complete service' });
      }
    });

    // Handle disconnection
    socket.on('disconnect', () => {
      const user = connectedUsers.get(socket.id);
      if (user) {
        console.log(`User ${user.userId} disconnected`);
        connectedUsers.delete(socket.id);
      }
      console.log(`Socket disconnected: ${socket.id}`);
    });
  });
} 