class CreateAccountUsers < ActiveRecord::Migration[7.1]
  def change
    create_table :account_users do |t|
      t.references :account, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.integer :role, default: 0
      t.bigint :inviter_id
      t.datetime :active_at
      t.integer :availability, default: 0, null: false
      t.boolean :auto_offline, default: true, null: false

      t.timestamps
    end

    add_index :account_users, [:account_id, :user_id], unique: true, name: 'uniq_user_id_per_account_id'
    add_index :account_users, :user_id
  end
end
