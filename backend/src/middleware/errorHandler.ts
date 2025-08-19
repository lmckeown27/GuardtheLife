import { Request, Response, NextFunction } from 'express';

export interface AppError extends Error {
  statusCode?: number;
  isOperational?: boolean;
}

export const errorHandler = (
  error: AppError,
  _req: Request,
  res: Response,
  _next: NextFunction
): void => {
  const statusCode = error.statusCode || 500;
  const message = error.message || 'Internal Server Error';

  // Log error for debugging
  console.error(`Error ${statusCode}: ${message}`);
  console.error(error.stack);

  // Don't leak error details in production
  const errorResponse = {
    error: {
      message: process.env['NODE_ENV'] === 'production' ? 'Internal Server Error' : message,
      ...(process.env['NODE_ENV'] === 'development' && { stack: error.stack })
    }
  };

  res.status(statusCode).json(errorResponse);
};

export const createError = (message: string, statusCode: number = 500): AppError => {
  const error = new Error(message) as AppError;
  error.statusCode = statusCode;
  error.isOperational = true;
  return error;
};

export const notFound = (_req: Request, _res: Response, _next: NextFunction): void => {
  const error = createError(`Route ${_req.originalUrl} not found`, 404);
  _next(error);
}; 