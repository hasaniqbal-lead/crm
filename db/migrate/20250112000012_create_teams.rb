class CreateTeams < ActiveRecord::Migration[7.1]
  def change
    create_table :teams do |t|
      t.references :account, null: false, foreign_key: true
      t.string :name, null: false
      t.text :description
      t.boolean :allow_auto_assign, default: true

      t.timestamps
    end

    add_index :teams, :account_id
  end
end
