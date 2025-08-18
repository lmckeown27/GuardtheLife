import { Knex } from 'knex';

export async function up(knex: Knex): Promise<void> {
  return knex.schema.createTable('lifeguards', (table) => {
    table.uuid('id').primary().defaultTo(knex.raw('gen_random_uuid()'));
    table.uuid('user_id').references('id').inTable('users').onDelete('CASCADE');
    table.boolean('available').defaultTo(false);
    table.decimal('hourly_rate', 8, 2).notNullable();
    table.text('certifications').nullable(); // JSON array of certifications
    table.text('experience_years').nullable();
    table.text('bio').nullable();
    table.boolean('background_check_passed').defaultTo(false);
    table.boolean('cpr_certified').defaultTo(false);
    table.boolean('first_aid_certified').defaultTo(false);
    table.timestamp('created_at').defaultTo(knex.fn.now());
    table.timestamp('updated_at').defaultTo(knex.fn.now());
    
    // Indexes
    table.index(['user_id']);
    table.index(['available']);
    table.index(['hourly_rate']);
  });
}

export async function down(knex: Knex): Promise<void> {
  return knex.schema.dropTable('lifeguards');
} 