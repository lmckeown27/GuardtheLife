import { Knex } from 'knex';

export async function up(knex: Knex): Promise<void> {
  return knex.schema.createTable('user_locations', (table) => {
    table.uuid('id').primary().defaultTo(knex.raw('gen_random_uuid()'));
    table.uuid('user_id').references('id').inTable('users').onDelete('CASCADE');
    table.decimal('latitude', 10, 8).notNullable();
    table.decimal('longitude', 11, 8).notNullable();
    table.timestamp('updated_at').defaultTo(knex.fn.now());
    
    // PostGIS geometry column for spatial queries
    table.specificType('location', 'geometry(Point, 4326)');
    
    // Indexes
    table.index(['user_id']);
    table.index(['updated_at']);
    table.index(['location'], 'gist'); // Spatial index
  });
}

export async function down(knex: Knex): Promise<void> {
  return knex.schema.dropTable('user_locations');
} 