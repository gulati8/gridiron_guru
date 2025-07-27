class CreateRbSeasonStats < ActiveRecord::Migration[8.0]
  def change
    create_table :rb_season_stats do |t|
      t.references :player, null: false, foreign_key: true
      t.integer :season, null: false
      t.string :team_abbr, null: false
      t.integer :age

      # Game participation
      t.integer :games, default: 0
      t.integer :games_started, default: 0

      # Core rushing stats (fantasy relevant)
      t.integer :rush_att, default: 0
      t.integer :rush_yds, default: 0
      t.integer :rush_td, default: 0
      t.decimal :rush_yds_per_att, precision: 5, scale: 2
      t.integer :rush_long, default: 0

      # Core receiving stats (fantasy relevant)
      t.integer :targets, default: 0
      t.integer :rec, default: 0
      t.integer :rec_yds, default: 0
      t.integer :rec_td, default: 0
      t.decimal :catch_pct, precision: 5, scale: 2
      t.decimal :rec_yds_per_tgt, precision: 5, scale: 2

      # Combined stats
      t.integer :touches, default: 0
      t.integer :yds_from_scrimmage, default: 0
      t.integer :total_td, default: 0 # rush_td + rec_td
      t.integer :fumbles, default: 0

      # Key efficiency metrics
      t.decimal :yds_per_touch, precision: 5, scale: 2
      t.decimal :rush_success_rate, precision: 5, scale: 2
      t.decimal :rec_success_rate, precision: 5, scale: 2

      # Advanced stats (JSON)
      t.json :rushing_advanced, default: {} # YBC, YAC, broken tackles
      t.json :receiving_advanced, default: {} # ADOT, air yards, target share
      t.json :efficiency_metrics, default: {} # success rates, EPA
      t.json :raw_season_data, default: {}
      t.json :raw_advanced_data, default: {}

      t.timestamps
    end

    add_index :rb_season_stats, [:player_id, :season], unique: true
    add_index :rb_season_stats, [:season, :rush_yds]
    add_index :rb_season_stats, [:season, :total_td]
    add_index :rb_season_stats, [:season, :yds_from_scrimmage]
    add_index :rb_season_stats, [:season, :targets]
    add_index :rb_season_stats, :team_abbr

    # JSON indexes for advanced metrics
    add_index :rb_season_stats, "(rushing_advanced->>'rush_yds_before_contact')", using: :btree
    add_index :rb_season_stats, "(receiving_advanced->>'rec_adot')", using: :btree
  end
end
