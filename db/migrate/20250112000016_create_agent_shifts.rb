class CreateAgentShifts < ActiveRecord::Migration[7.1]
  def change
    create_table :agent_shifts do |t|
      t.references :user, null: false, foreign_key: true
      t.references :account, null: false, foreign_key: true
      t.time :shift_start, null: false
      t.time :shift_end, null: false
      t.integer :day_of_week, null: false  # 0 = Sunday, 6 = Saturday
      t.string :timezone, default: 'UTC'
      t.boolean :active, default: true

      t.timestamps
    end

    add_index :agent_shifts, [:user_id, :account_id]
    add_index :agent_shifts, [:account_id, :day_of_week]
    add_index :agent_shifts, :active
  end
end
