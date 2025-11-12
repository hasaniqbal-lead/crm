class CreateAccounts < ActiveRecord::Migration[7.1]
  def change
    create_table :accounts do |t|
      t.string :name, null: false
      t.integer :locale, default: 0
      t.string :domain, limit: 100
      t.string :support_email, limit: 100
      t.bigint :feature_flags, default: 0, null: false
      t.integer :auto_resolve_duration
      t.jsonb :limits, default: {}
      t.jsonb :custom_attributes, default: {}
      t.integer :status, default: 0
      t.jsonb :settings, default: {}

      t.timestamps
    end

    add_index :accounts, :status
  end
end
