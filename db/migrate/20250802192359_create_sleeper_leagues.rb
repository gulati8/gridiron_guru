class CreateSleeperLeagues < ActiveRecord::Migration[8.0]
  def change
    create_table :sleeper_leagues do |t|
      t.string :sleeper_league_id, null: false
      t.string :name, null: false
      t.integer :season, null: false
      t.integer :total_rosters, null: false
      t.string :status, null: false
      t.json :scoring_settings
      t.json :roster_positions
      t.json :settings
      t.string :league_type

      t.timestamps
    end

    add_index :sleeper_leagues, :sleeper_league_id, unique: true
    add_index :sleeper_leagues, :season
    add_index :sleeper_leagues, [:season, :status]
  end
end
