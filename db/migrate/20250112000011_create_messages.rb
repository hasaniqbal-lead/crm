class CreateMessages < ActiveRecord::Migration[7.1]
  def change
    create_table :messages do |t|
      t.references :account, null: false, foreign_key: true
      t.references :inbox, null: false, foreign_key: true
      t.references :conversation, null: false, foreign_key: true

      t.text :content
      t.integer :content_type, default: 0, null: false
      t.integer :message_type, null: false
      t.integer :status, default: 0
      t.boolean :private, default: false, null: false

      t.string :sender_type
      t.bigint :sender_id
      t.string :source_id

      t.jsonb :content_attributes, default: {}
      t.jsonb :additional_attributes, default: {}
      t.jsonb :external_source_ids, default: {}
      t.jsonb :sentiment, default: {}
      t.text :processed_message_content

      t.timestamps
    end

    add_index :messages, [:sender_type, :sender_id]
    add_index :messages, :source_id
    add_index :messages, [:account_id, :inbox_id]
    add_index :messages, [:conversation_id, :account_id, :message_type, :created_at],
              name: 'index_messages_on_conversation_account_type_created'
    add_index :messages, [:account_id, :created_at, :message_type],
              name: 'index_messages_on_account_created_type'
    add_index :messages, [:account_id, :content_type, :created_at],
              name: 'idx_messages_account_content_created'
  end
end
