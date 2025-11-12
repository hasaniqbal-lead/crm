class CreateAppliedSlas < ActiveRecord::Migration[7.1]
  def change
    create_table :applied_slas do |t|
      t.references :account, null: false, foreign_key: true
      t.references :sla_policy, null: false, foreign_key: true
      t.references :conversation, null: false, foreign_key: true
      t.integer :sla_status, default: 0

      t.timestamps
    end

    add_index :applied_slas, :sla_policy_id
    add_index :applied_slas, :conversation_id
    add_index :applied_slas, [:account_id, :sla_policy_id, :conversation_id],
              unique: true,
              name: 'index_applied_slas_on_account_sla_policy_conversation'
  end
end
