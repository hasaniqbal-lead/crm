class CreateInboxes < ActiveRecord::Migration[7.1]
  def change
    create_table :inboxes do |t|
      t.references :account, null: false, foreign_key: true
      t.string :name, null: false
      t.string :channel_type
      t.bigint :channel_id, null: false
      t.string :email_address
      t.boolean :enable_auto_assignment, default: true
      t.string :greeting_message
      t.boolean :greeting_enabled, default: false
      t.string :out_of_office_message
      t.string :timezone, default: 'UTC'
      t.boolean :working_hours_enabled, default: false
      t.boolean :enable_email_collect, default: true
      t.boolean :csat_survey_enabled, default: false
      t.jsonb :csat_config, null: false, default: {}
      t.boolean :allow_messages_after_resolved, default: true
      t.jsonb :auto_assignment_config, default: {}
      t.boolean :lock_to_single_conversation, default: false, null: false
      t.integer :sender_name_type, default: 0, null: false
      t.string :business_name

      t.timestamps
    end

    add_index :inboxes, :account_id
    add_index :inboxes, [:channel_id, :channel_type]
  end
end
