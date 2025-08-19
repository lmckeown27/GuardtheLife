import { Request, Response } from 'express';
import bcrypt from 'bcryptjs';
import jwt from 'jsonwebtoken';
import { db } from '../utils/database';
import { createError } from '../middleware/errorHandler';

export const authController = {
  // User registration
  async register(req: Request, res: Response) {
    try {
      const { email, password, firstName, lastName, role, phone } = req.body;

      // Check if user already exists
      const existingUser = await db('users').where({ email }).first();
      if (existingUser) {
        throw createError('User already exists with this email', 400);
      }

      // Hash password
      const saltRounds = 12;
      const passwordHash = await bcrypt.hash(password, saltRounds);

      // Create user
      const [userId] = await db('users').insert({
        email,
        password_hash: passwordHash,
        first_name: firstName,
        last_name: lastName,
        role,
        phone,
        is_verified: false,
        is_active: true,
        created_at: new Date(),
        updated_at: new Date()
      }).returning('id');

      // If lifeguard, create lifeguard profile
      if (role === 'lifeguard') {
        await db('lifeguards').insert({
          user_id: userId,
          available: false,
          hourly_rate: 25.00, // Default rate
          background_check_passed: false,
          cpr_certified: false,
          first_aid_certified: false,
          created_at: new Date(),
          updated_at: new Date()
        });
      }

      // Generate JWT token
      const token = jwt.sign(
        { userId, email, role },
        process.env['JWT_SECRET'] || 'fallback-secret',
        { expiresIn: process.env['JWT_EXPIRES_IN'] || '7d' } as any
      );

      // Get user data (without password)
      const user = await db('users')
        .where({ id: userId })
        .select('id', 'email', 'first_name', 'last_name', 'role', 'phone', 'is_verified', 'is_active')
        .first();

      res.status(201).json({
        success: true,
        message: 'User registered successfully',
        user,
        token
      });
    } catch (error) {
      if (error instanceof Error) {
        res.status(400).json({ error: error.message });
      } else {
        res.status(500).json({ error: 'Registration failed' });
      }
    }
  },

  // User login
  async login(req: Request, res: Response) {
    try {
      const { email, password } = req.body;

      // Find user
      const user = await db('users').where({ email }).first();
      if (!user) {
        throw createError('Invalid credentials', 401);
      }

      // Check password
      const isValidPassword = await bcrypt.compare(password, user.password_hash);
      if (!isValidPassword) {
        throw createError('Invalid credentials', 401);
      }

      // Check if user is active
      if (!user.is_active) {
        throw createError('Account is deactivated', 401);
      }

      // Generate JWT token
      const token = jwt.sign(
        { userId: user.id, email: user.email, role: user.role },
        process.env['JWT_SECRET'] || 'fallback-secret',
        { expiresIn: process.env['JWT_EXPIRES_IN'] || '7d' } as any
      );

      // Remove password from response
      const { password_hash: _, ...userData } = user;

      res.json({
        success: true,
        message: 'Login successful',
        user: userData,
        token
      });
    } catch (error) {
      if (error instanceof Error) {
        res.status(400).json({ error: error.message });
      } else {
        res.status(500).json({ error: 'Login failed' });
      }
    }
  },

  // Firebase authentication
  async firebaseAuth(req: Request, res: Response) {
    try {
      const { firebaseToken: _firebaseToken } = req.body;

      // TODO: Implement Firebase token verification
      // For now, return a placeholder response
      res.json({
        success: true,
        message: 'Firebase authentication endpoint',
        note: 'Firebase integration needs to be implemented'
      });
    } catch (error) {
      res.status(500).json({ error: 'Firebase authentication failed' });
    }
  },

  // Refresh token
  async refreshToken(_req: Request, res: Response) {
    try {
      // TODO: Implement token refresh logic
      res.json({
        success: true,
        message: 'Token refresh endpoint',
        note: 'Token refresh needs to be implemented'
      });
    } catch (error) {
      res.status(500).json({ error: 'Token refresh failed' });
    }
  },

  // Forgot password
  async forgotPassword(req: Request, res: Response) {
    try {
      const { email: _email } = req.body;

      // TODO: Implement password reset logic
      res.json({
        success: true,
        message: 'Password reset email sent',
        note: 'Password reset needs to be implemented'
      });
    } catch (error) {
      res.status(500).json({ error: 'Password reset failed' });
    }
  },

  // Reset password
  async resetPassword(req: Request, res: Response) {
    try {
      const { token: _, newPassword: __ } = req.body;

      // TODO: Implement password reset logic
      res.json({
        success: true,
        message: 'Password reset successful',
        note: 'Password reset needs to be implemented'
      });
    } catch (error) {
      res.status(500).json({ error: 'Password reset failed' });
    }
  },

  // Get user profile
  async getProfile(req: Request, res: Response) {
    try {
      const userId = (req as any).user?.userId;
      if (!userId) {
        throw createError('User not authenticated', 401);
      }

      const user = await db('users')
        .where({ id: userId })
        .select('id', 'email', 'first_name', 'last_name', 'role', 'phone', 'is_verified', 'is_active')
        .first();

      if (!user) {
        throw createError('User not found', 404);
      }

      res.json({
        success: true,
        user
      });
    } catch (error) {
      if (error instanceof Error) {
        res.status(400).json({ error: error.message });
      } else {
        res.status(500).json({ error: 'Failed to get profile' });
      }
    }
  },

  // Update user profile
  async updateProfile(req: Request, res: Response) {
    try {
      const userId = (req as any).user?.userId;
      if (!userId) {
        throw createError('User not authenticated', 401);
      }

      const { firstName, lastName, phone } = req.body;

      await db('users')
        .where({ id: userId })
        .update({
          first_name: firstName,
          last_name: lastName,
          phone,
          updated_at: new Date()
        });

      res.json({
        success: true,
        message: 'Profile updated successfully'
      });
    } catch (error) {
      if (error instanceof Error) {
        res.status(400).json({ error: error.message });
      } else {
        res.status(500).json({ error: 'Failed to update profile' });
      }
    }
  },

  // Logout
  async logout(_req: Request, res: Response) {
    try {
      // TODO: Implement logout logic (e.g., blacklist token)
      res.json({
        success: true,
        message: 'Logout successful'
      });
    } catch (error) {
      res.status(500).json({ error: 'Logout failed' });
    }
  },

  // Change password
  async changePassword(req: Request, res: Response) {
    try {
      const userId = (req as any).user?.userId;
      if (!userId) {
        throw createError('User not authenticated', 401);
      }

      const { currentPassword, newPassword } = req.body;

      // Get current user
      const user = await db('users').where({ id: userId }).first();
      if (!user) {
        throw createError('User not found', 404);
      }

      // Verify current password
      const isValidPassword = await bcrypt.compare(currentPassword, user.password_hash);
      if (!isValidPassword) {
        throw createError('Current password is incorrect', 400);
      }

      // Hash new password
      const saltRounds = 12;
      const newPasswordHash = await bcrypt.hash(newPassword, saltRounds);

      // Update password
      await db('users')
        .where({ id: userId })
        .update({
          password_hash: newPasswordHash,
          updated_at: new Date()
        });

      res.json({
        success: true,
        message: 'Password changed successfully'
      });
    } catch (error) {
      if (error instanceof Error) {
        res.status(400).json({ error: error.message });
      } else {
        res.status(500).json({ error: 'Failed to change password' });
      }
    }
  }
}; 