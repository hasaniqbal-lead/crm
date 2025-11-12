class CreateAgentMetrics < ActiveRecord::Migration[7.1]
  def change
    create_table :agent_metrics do |t|
      t.references :user, null: false, foreign_key: true
      t.references :account, null: false, foreign_key: true
      t.date :metric_date, null: false

      # Response time metrics (in seconds)
      t.float :avg_first_response_time
      t.float :avg_response_time
      t.float :avg_resolution_time

      # Volume metrics
      t.integer :conversations_handled, default: 0
      t.integer :messages_sent, default: 0
      t.integer :conversations_resolved, default: 0

      # SLA metrics
      t.integer :sla_met_count, default: 0
      t.integer :sla_missed_count, default: 0

      # Activity metrics (in seconds)
      t.integer :online_duration, default: 0
      t.integer :busy_duration, default: 0
      t.integer :offline_duration, default: 0

      t.timestamps
    end

    add_index :agent_metrics, [:user_id, :metric_date], unique: true
    add_index :agent_metrics, [:account_id, :metric_date]
    add_index :agent_metrics, :metric_date
  end
end
