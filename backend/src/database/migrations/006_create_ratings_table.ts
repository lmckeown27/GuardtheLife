import { Knex } from 'knex';

export async function up(knex: Knex): Promise<void> {
  return knex.schema.createTable('ratings', (table) => {
    table.uuid('id').primary().defaultTo(knex.raw('gen_random_uuid()'));
    table.uuid('service_request_id').references('id').inTable('service_requests').onDelete('CASCADE');
    table.uuid('reviewer_id').references('id').inTable('users').onDelete('CASCADE');
    table.uuid('reviewed_id').references('id').inTable('users').onDelete('CASCADE');
    table.integer('rating').notNullable().checkBetween([1, 5]);
    table.text('review').nullable();
    table.boolean('is_public').defaultTo(true);
    table.timestamp('created_at').defaultTo(knex.fn.now());
    table.timestamp('updated_at').defaultTo(knex.fn.now());
    
    // Ensure one rating per service request per reviewer
    table.unique(['service_request_id', 'reviewer_id']);
    
    // Indexes
    table.index(['service_request_id']);
    table.index(['reviewer_id']);
    table.index(['reviewed_id']);
    table.index(['rating']);
    table.index(['created_at']);
  });
}

export async function down(knex: Knex): Promise<void> {
  return knex.schema.dropTable('ratings');
} 