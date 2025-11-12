class CreateChannelFacebookPages < ActiveRecord::Migration[7.1]
  def change
    create_table :channel_facebook_pages do |t|
      t.integer :account_id, null: false
      t.string :page_id, null: false
      t.string :page_access_token, null: false
      t.string :user_access_token, null: false
      t.string :instagram_id

      t.timestamps
    end

    add_index :channel_facebook_pages, :page_id
    add_index :channel_facebook_pages, [:page_id, :account_id], unique: true
  end
end
