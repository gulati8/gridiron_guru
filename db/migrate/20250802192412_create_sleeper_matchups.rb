class CreateSleeperMatchups < ActiveRecord::Migration[8.0]
  def change
    create_table :sleeper_matchups do |t|
      t.references :sleeper_league, null: false, foreign_key: true
      t.integer :week, null: false
      t.integer :season, null: false
      t.references :sleeper_roster, null: false, foreign_key: true
      t.decimal :points, precision: 8, scale: 2
      t.string :opponent_roster_id
      t.decimal :opponent_points, precision: 8, scale: 2

      t.timestamps
    end

    add_index :sleeper_matchups, [:sleeper_league_id, :week, :season]
    add_index :sleeper_matchups, [:sleeper_roster_id, :season, :week]
    add_index :sleeper_matchups, :season
  end
end
