import { Knex } from 'knex';

export async function up(knex: Knex): Promise<void> {
  return knex.schema.createTable('notifications', (table) => {
    table.uuid('id').primary().defaultTo(knex.raw('gen_random_uuid()'));
    table.uuid('user_id').references('id').inTable('users').onDelete('CASCADE');
    table.string('device_token').nullable();
    table.string('title').notNullable();
    table.text('body').notNullable();
    table.string('type').notNullable(); // 'service_request', 'payment', 'reminder', etc.
    table.jsonb('data').nullable(); // Additional data for the notification
    table.boolean('is_read').defaultTo(false);
    table.boolean('is_sent').defaultTo(false);
    table.timestamp('sent_at').nullable();
    table.timestamp('read_at').nullable();
    table.timestamp('created_at').defaultTo(knex.fn.now());
    table.timestamp('updated_at').defaultTo(knex.fn.now());
    
    // Indexes
    table.index(['user_id']);
    table.index(['type']);
    table.index(['is_read']);
    table.index(['is_sent']);
    table.index(['created_at']);
  });
}

export async function down(knex: Knex): Promise<void> {
  return knex.schema.dropTable('notifications');
} 