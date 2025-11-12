class CreatePlatformSlaConfigs < ActiveRecord::Migration[7.1]
  def change
    create_table :platform_sla_configs do |t|
      t.references :account, null: false, foreign_key: true
      t.string :channel_type, null: false  # 'Channel::Whatsapp', 'Channel::FacebookPage', etc.
      t.integer :first_response_minutes, default: 30
      t.integer :resolution_hours, default: 24
      t.boolean :enabled, default: true
      t.jsonb :additional_config, default: {}

      t.timestamps
    end

    add_index :platform_sla_configs, [:account_id, :channel_type], unique: true
    add_index :platform_sla_configs, :channel_type
    add_index :platform_sla_configs, :enabled
  end
end
