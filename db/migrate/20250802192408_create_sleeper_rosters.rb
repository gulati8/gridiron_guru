class CreateSleeperRosters < ActiveRecord::Migration[8.0]
  def change
    create_table :sleeper_rosters do |t|
      t.string :sleeper_roster_id, null: false
      t.references :sleeper_league, null: false, foreign_key: true
      t.references :sleeper_user, null: false, foreign_key: true
      t.json :settings
      t.text :players
      t.integer :wins, default: 0
      t.integer :losses, default: 0
      t.integer :ties, default: 0
      t.integer :total_moves, default: 0
      t.integer :waiver_position
      t.integer :waiver_budget_used, default: 0

      t.timestamps
    end

    add_index :sleeper_rosters, :sleeper_roster_id, unique: true
  end
end
