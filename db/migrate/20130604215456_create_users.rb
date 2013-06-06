class CreateUsers < ActiveRecord::Migration
  def change
    create_table :users do |t|
      t.string :name
      t.string :email
      t.string :fbid
      t.boolean :registered
      t.string :fb_access_token
      t.string :favorite_donut
      t.time :last_login
      t.string :state
      t.boolean :is_bobfather
      t.integer :node_id

      t.timestamps
    end
    add_index :users, :node_id
    add_index :users, :fbid
  end
end
