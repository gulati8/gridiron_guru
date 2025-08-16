class CreateSleeperPlayerStats < ActiveRecord::Migration[8.0]
  def change
    create_table :sleeper_player_stats do |t|
      t.string :sleeper_player_id, null: false
      t.string :player_name, null: false
      t.string :position, null: false
      t.string :team
      t.integer :season, null: false
      t.integer :week, null: false
      t.string :season_type, null: false, default: 'regular'
      t.json :stats
      t.decimal :fantasy_points_standard, precision: 8, scale: 2
      t.decimal :fantasy_points_half_ppr, precision: 8, scale: 2
      t.decimal :fantasy_points_ppr, precision: 8, scale: 2

      t.timestamps
    end

    # Add indexes for efficient queries
    add_index :sleeper_player_stats, :sleeper_player_id
    add_index :sleeper_player_stats, [:season, :week, :season_type]
    add_index :sleeper_player_stats, :position
    add_index :sleeper_player_stats, [:sleeper_player_id, :season, :week, :season_type], 
              unique: true, name: 'idx_sleeper_player_stats_unique'
    add_index :sleeper_player_stats, :fantasy_points_ppr
    add_index :sleeper_player_stats, [:position, :season, :week]
  end
end
