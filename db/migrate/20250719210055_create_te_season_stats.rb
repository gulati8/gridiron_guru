class CreateTeSeasonStats < ActiveRecord::Migration[8.0]
  def change
    create_table :te_season_stats do |t|
      t.references :player, null: false, foreign_key: true
      t.integer :season, null: false
      t.string :team_abbr, null: false
      t.integer :age

      # Game participation
      t.integer :games, default: 0
      t.integer :games_started, default: 0

      # Core receiving stats
      t.integer :targets, default: 0
      t.integer :rec, default: 0
      t.integer :rec_yds, default: 0
      t.integer :rec_td, default: 0
      t.decimal :catch_pct, precision: 5, scale: 2
      t.decimal :rec_yds_per_rec, precision: 5, scale: 2
      t.decimal :rec_yds_per_tgt, precision: 5, scale: 2
      t.integer :rec_long, default: 0

      # Rushing (rare but happens)
      t.integer :rush_att, default: 0
      t.integer :rush_yds, default: 0
      t.integer :rush_td, default: 0

      # Combined stats
      t.integer :touches, default: 0
      t.integer :yds_from_scrimmage, default: 0
      t.integer :total_td, default: 0
      t.integer :fumbles, default: 0

      # TE-specific metrics
      t.decimal :yds_per_touch, precision: 5, scale: 2
      t.decimal :rec_success_rate, precision: 5, scale: 2

      # Advanced stats (JSON) - TEs have unique usage patterns
      t.json :receiving_advanced, default: {} # ADOT, air yards, YAC
      t.json :blocking_metrics, default: {}   # snap share, route participation
      t.json :target_metrics, default: {}     # red zone usage, target share
      t.json :raw_season_data, default: {}
      t.json :raw_advanced_data, default: {}

      t.timestamps
    end

    add_index :te_season_stats, [:player_id, :season], unique: true
    add_index :te_season_stats, [:season, :rec_yds]
    add_index :te_season_stats, [:season, :targets]
    add_index :te_season_stats, [:season, :rec_td]
    add_index :te_season_stats, :team_abbr

    # JSON indexes for TE-specific metrics
    add_index :te_season_stats, "(receiving_advanced->>'rec_adot')", using: :btree
    add_index :te_season_stats, "(target_metrics->>'red_zone_targets')", using: :btree
  end
end
