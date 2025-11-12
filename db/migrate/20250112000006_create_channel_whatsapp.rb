class CreateChannelWhatsapp < ActiveRecord::Migration[7.1]
  def change
    create_table :channel_whatsapp do |t|
      t.integer :account_id, null: false
      t.string :phone_number, null: false
      t.string :provider, default: 'default'
      t.jsonb :provider_config, default: {}
      t.jsonb :message_templates, default: {}
      t.datetime :message_templates_last_updated

      t.timestamps
    end

    add_index :channel_whatsapp, :phone_number, unique: true
    add_index :channel_whatsapp, :account_id
  end
end
