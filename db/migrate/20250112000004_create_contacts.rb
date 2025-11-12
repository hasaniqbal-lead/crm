class CreateContacts < ActiveRecord::Migration[7.1]
  def change
    create_table :contacts do |t|
      t.references :account, null: false, foreign_key: true
      t.string :name
      t.string :email
      t.string :phone_number
      t.string :identifier
      t.jsonb :additional_attributes, default: {}
      t.jsonb :custom_attributes, default: {}
      t.datetime :last_activity_at
      t.string :contact_type
      t.integer :blocked, default: 0, null: false

      t.timestamps
    end

    add_index :contacts, :account_id
    add_index :contacts, :email
    add_index :contacts, :phone_number
    add_index :contacts, [:account_id, :email], where: "email IS NOT NULL"
    add_index :contacts, [:account_id, :phone_number], where: "phone_number IS NOT NULL"
  end
end
