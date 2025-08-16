class CreateSleeperUsers < ActiveRecord::Migration[8.0]
  def change
    create_table :sleeper_users do |t|
      t.string :sleeper_user_id, null: false
      t.string :username, null: false
      t.string :display_name
      t.string :avatar

      t.timestamps
    end

    add_index :sleeper_users, :sleeper_user_id, unique: true
    add_index :sleeper_users, :username
  end
end
