class CreateSleeperTransactions < ActiveRecord::Migration[8.0]
  def change
    create_table :sleeper_transactions do |t|
      t.string :sleeper_transaction_id, null: false
      t.references :sleeper_league, null: false, foreign_key: true
      t.string :transaction_type, null: false
      t.string :status, null: false
      t.integer :week, null: false
      t.integer :season, null: false
      t.json :metadata

      t.timestamps
    end

    add_index :sleeper_transactions, :sleeper_transaction_id, unique: true
    add_index :sleeper_transactions, [:sleeper_league_id, :week, :season]
    add_index :sleeper_transactions, :transaction_type
    add_index :sleeper_transactions, :season
  end
end
