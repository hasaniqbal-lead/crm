class CreateContactInboxes < ActiveRecord::Migration[7.1]
  def change
    create_table :contact_inboxes do |t|
      t.references :contact, null: false, foreign_key: true
      t.references :inbox, null: false, foreign_key: true
      t.string :source_id, null: false
      t.jsonb :hmac_verified, default: {}
      t.string :pubsub_token

      t.timestamps
    end

    add_index :contact_inboxes, [:inbox_id, :source_id], unique: true
    add_index :contact_inboxes, :source_id
    add_index :contact_inboxes, :pubsub_token, unique: true
  end
end
