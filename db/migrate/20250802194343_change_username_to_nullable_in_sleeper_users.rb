class ChangeUsernameToNullableInSleeperUsers < ActiveRecord::Migration[8.0]
  def change
    change_column_null :sleeper_users, :username, true
  end
end
