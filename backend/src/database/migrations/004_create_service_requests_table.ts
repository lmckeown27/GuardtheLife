import { Knex } from 'knex';

export async function up(knex: Knex): Promise<void> {
  return knex.schema.createTable('service_requests', (table) => {
    table.uuid('id').primary().defaultTo(knex.raw('gen_random_uuid()'));
    table.uuid('client_id').references('id').inTable('users').onDelete('CASCADE');
    table.uuid('lifeguard_id').references('id').inTable('lifeguards').nullable();
    table.enum('status', ['pending', 'accepted', 'declined', 'in_progress', 'completed', 'cancelled']).defaultTo('pending');
    table.string('service_type').notNullable();
    table.decimal('latitude', 10, 8).notNullable();
    table.decimal('longitude', 11, 8).notNullable();
    table.text('notes').nullable();
    table.timestamp('requested_at').defaultTo(knex.fn.now());
    table.timestamp('accepted_at').nullable();
    table.timestamp('started_at').nullable();
    table.timestamp('completed_at').nullable();
    table.integer('estimated_duration_minutes').nullable();
    table.decimal('total_amount', 10, 2).nullable();
    table.timestamp('created_at').defaultTo(knex.fn.now());
    table.timestamp('updated_at').defaultTo(knex.fn.now());
    
    // Indexes
    table.index(['client_id']);
    table.index(['lifeguard_id']);
    table.index(['status']);
    table.index(['requested_at']);
    table.index(['latitude', 'longitude']);
  });
}

export async function down(knex: Knex): Promise<void> {
  return knex.schema.dropTable('service_requests');
} 