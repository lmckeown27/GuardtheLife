import { Request, Response, NextFunction } from 'express';
import { createError } from './errorHandler';

export const lifeguardMiddleware = (req: Request, _res: Response, next: NextFunction): void => {
  try {
    const user = req.user;
    
    if (!user) {
      throw createError('User not authenticated', 401);
    }

    if (user.role !== 'lifeguard') {
      throw createError('Lifeguard access required', 403);
    }

    next();
  } catch (error) {
    if (error instanceof Error) {
      next(createError(error.message, 403));
    } else {
      next(createError('Access denied', 403));
    }
  }
}; 