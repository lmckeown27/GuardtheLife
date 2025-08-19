import knex from 'knex';
import dotenv from 'dotenv';

dotenv.config();

const config = {
  client: 'pg',
  connection: {
    host: process.env['POSTGRES_HOST'] || 'localhost',
    port: parseInt(process.env['POSTGRES_PORT'] || '5432'),
    user: process.env['POSTGRES_USER'] || 'postgres',
    password: process.env['POSTGRES_PASSWORD'] || 'password',
    database: process.env['POSTGRES_DB'] || 'lifeguard_db',
  },
  pool: {
    min: 2,
    max: 10,
    acquireTimeoutMillis: 30000,
    createTimeoutMillis: 30000,
    destroyTimeoutMillis: 5000,
    idleTimeoutMillis: 30000,
    reapIntervalMillis: 1000,
    createRetryIntervalMillis: 100,
  },
  migrations: {
    directory: './src/database/migrations',
    tableName: 'knex_migrations',
  },
  seeds: {
    directory: './src/database/seeds',
  },
  debug: process.env['NODE_ENV'] === 'development',
};

export const db = knex(config);

export async function connectDatabase(): Promise<void> {
  try {
    // Test the connection
    await db.raw('SELECT 1');
    console.log('✅ Database connection successful');
  } catch (error) {
    console.error('❌ Database connection failed:', error);
    throw error;
  }
}

export async function closeDatabase(): Promise<void> {
  try {
    await db.destroy();
    console.log('✅ Database connection closed');
  } catch (error) {
    console.error('❌ Error closing database connection:', error);
  }
}

// Database initialization function
export async function initializeDatabase(): Promise<void> {
  try {
    // Run migrations
    await db.migrate.latest();
    console.log('✅ Database migrations completed');

    // Run seeds in development
    if (process.env['NODE_ENV'] === 'development') {
      await db.seed.run();
      console.log('✅ Database seeds completed');
    }
  } catch (error) {
    console.error('❌ Database initialization failed:', error);
    throw error;
  }
} 