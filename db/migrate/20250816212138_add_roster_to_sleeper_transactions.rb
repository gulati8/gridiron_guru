class AddRosterToSleeperTransactions < ActiveRecord::Migration[8.0]
  def change
    add_reference :sleeper_transactions, :sleeper_roster, null: true, foreign_key: true
  end
end
