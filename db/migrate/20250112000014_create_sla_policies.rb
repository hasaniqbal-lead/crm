class CreateSlaPolicies < ActiveRecord::Migration[7.1]
  def change
    create_table :sla_policies do |t|
      t.references :account, null: false, foreign_key: true
      t.string :name, null: false
      t.string :description
      t.float :first_response_time_threshold
      t.float :next_response_time_threshold
      t.float :resolution_time_threshold
      t.boolean :only_during_business_hours, default: false

      t.timestamps
    end

    add_index :sla_policies, :account_id
  end
end
