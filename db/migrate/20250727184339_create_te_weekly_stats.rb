class CreateTeWeeklyStats < ActiveRecord::Migration[8.0]
  def change
    create_table :te_weekly_stats do |t|
      t.references :player, null: false, foreign_key: true
      t.integer :season, null: false
      t.integer :week, null: false
      t.string :team_abbr, null: false
      t.date :game_date
      t.string :opponent
      t.boolean :home_game, default: true
      t.integer :targets, default: 0
      t.integer :rec, default: 0
      t.integer :rec_yds, default: 0
      t.integer :rec_td, default: 0
      t.integer :rush_att, default: 0
      t.integer :rush_yds, default: 0
      t.integer :rush_td, default: 0
      t.integer :fumbles, default: 0
      t.decimal :fantasy_points_std, precision: 8, scale: 2
      t.decimal :fantasy_points_half_ppr, precision: 8, scale: 2
      t.decimal :fantasy_points_ppr, precision: 8, scale: 2

      t.timestamps
    end

    add_index :te_weekly_stats, [:player_id, :season, :week], unique: true
    add_index :te_weekly_stats, [:season, :week]
    add_index :te_weekly_stats, :team_abbr
  end
end
