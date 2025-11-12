class CreateConversations < ActiveRecord::Migration[7.1]
  def change
    create_table :conversations do |t|
      t.references :account, null: false, foreign_key: true
      t.references :inbox, null: false, foreign_key: true
      t.references :contact, null: false, foreign_key: true
      t.references :assignee, foreign_key: { to_table: :users }
      t.references :team, foreign_key: true

      t.integer :status, default: 0, null: false
      t.integer :display_id, null: false
      t.uuid :uuid, null: false
      t.string :identifier
      t.datetime :last_activity_at, null: false
      t.datetime :agent_last_seen_at
      t.datetime :assignee_last_seen_at
      t.datetime :contact_last_seen_at
      t.datetime :first_reply_created_at
      t.integer :priority
      t.datetime :snoozed_until
      t.datetime :waiting_since
      t.jsonb :additional_attributes, default: {}
      t.jsonb :custom_attributes, default: {}

      t.timestamps
    end

    add_index :conversations, :uuid, unique: true
    add_index :conversations, [:account_id, :display_id], unique: true
    add_index :conversations, [:account_id, :inbox_id, :status, :assignee_id], name: 'conv_acid_inbid_stat_asgnid_idx'
    add_index :conversations, [:assignee_id, :account_id]
    add_index :conversations, [:status, :account_id]
    add_index :conversations, :first_reply_created_at
    add_index :conversations, :waiting_since
    add_index :conversations, :priority
  end
end
