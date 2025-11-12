class CreateAgentAvailabilityLogs < ActiveRecord::Migration[7.1]
  def change
    create_table :agent_availability_logs do |t|
      t.references :user, null: false, foreign_key: true
      t.references :account, null: false, foreign_key: true
      t.integer :status, null: false  # 0: offline, 1: online, 2: busy
      t.datetime :changed_at, null: false
      t.string :reason
      t.string :ip_address
      t.jsonb :metadata, default: {}

      t.timestamps
    end

    add_index :agent_availability_logs, [:user_id, :changed_at]
    add_index :agent_availability_logs, [:account_id, :changed_at]
    add_index :agent_availability_logs, :status
  end
end
