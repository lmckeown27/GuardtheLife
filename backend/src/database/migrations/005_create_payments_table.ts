import { Knex } from 'knex';

export async function up(knex: Knex): Promise<void> {
  return knex.schema.createTable('payments', (table) => {
    table.uuid('id').primary().defaultTo(knex.raw('gen_random_uuid()'));
    table.uuid('service_request_id').references('id').inTable('service_requests').onDelete('CASCADE');
    table.string('stripe_payment_intent_id').unique().notNullable();
    table.string('stripe_charge_id').nullable();
    table.decimal('amount', 10, 2).notNullable();
    table.string('currency').defaultTo('usd');
    table.enum('status', ['pending', 'succeeded', 'failed', 'cancelled', 'refunded']).defaultTo('pending');
    table.string('payment_method_id').nullable();
    table.text('description').nullable();
    table.jsonb('metadata').nullable();
    table.timestamp('paid_at').nullable();
    table.timestamp('refunded_at').nullable();
    table.timestamp('created_at').defaultTo(knex.fn.now());
    table.timestamp('updated_at').defaultTo(knex.fn.now());
    
    // Indexes
    table.index(['service_request_id']);
    table.index(['stripe_payment_intent_id']);
    table.index(['status']);
    table.index(['created_at']);
  });
}

export async function down(knex: Knex): Promise<void> {
  return knex.schema.dropTable('payments');
} 