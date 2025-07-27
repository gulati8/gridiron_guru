class CreateQbSeasonStats < ActiveRecord::Migration[8.0]
  def change
    create_table :qb_season_stats do |t|
      t.references :player, null: false, foreign_key: true
      t.integer :season, null: false
      t.string :team_abbr, null: false
      t.integer :age

      # Game participation
      t.integer :games, default: 0
      t.integer :games_started, default: 0
      t.string :qb_record # "9-8-0" format

      # Core passing stats (fantasy relevant)
      t.integer :pass_cmp, default: 0
      t.integer :pass_att, default: 0
      t.integer :pass_yds, default: 0
      t.integer :pass_td, default: 0
      t.integer :pass_int, default: 0
      t.decimal :pass_cmp_pct, precision: 5, scale: 2
      t.decimal :pass_rating, precision: 5, scale: 2

      # Rushing stats (fantasy relevant for QBs)
      t.integer :rush_att, default: 0
      t.integer :rush_yds, default: 0
      t.integer :rush_td, default: 0
      t.integer :fumbles, default: 0

      # Key efficiency metrics (queryable)
      t.decimal :pass_yds_per_att, precision: 5, scale: 2
      t.decimal :qbr, precision: 5, scale: 2
      t.integer :pass_sacked, default: 0
      t.integer :pass_sacked_yds, default: 0
      t.decimal :pass_sacked_pct, precision: 5, scale: 2

      # Advanced stats and metadata (JSON)
      t.json :advanced_passing, default: {} # air yards, target depth, pocket time
      t.json :pressure_stats, default: {}   # hurries, hits, blitzes
      t.json :situational_stats, default: {} # red zone, play action, RPO
      t.json :raw_season_data, default: {}   # full PFR season data
      t.json :raw_advanced_data, default: {} # full PFR advanced data

      t.timestamps
    end

    add_index :qb_season_stats, [:player_id, :season], unique: true
    add_index :qb_season_stats, [:season, :pass_yds]
    add_index :qb_season_stats, [:season, :pass_td]
    add_index :qb_season_stats, [:season, :pass_rating]
    add_index :qb_season_stats, :team_abbr

    # JSON indexes for advanced metrics
    add_index :qb_season_stats, "(advanced_passing->>'pass_air_yds')", using: :btree
    add_index :qb_season_stats, "(pressure_stats->>'pass_pressured_pct')", using: :btree
  end
end
