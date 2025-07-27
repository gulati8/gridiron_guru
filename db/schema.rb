# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.0].define(version: 2025_07_27_184339) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "players", force: :cascade do |t|
    t.string "name", null: false
    t.string "position", null: false
    t.string "pro_football_reference_url"
    t.string "sleeper_id"
    t.string "espn_id"
    t.boolean "active", default: true
    t.integer "jersey_number"
    t.string "college"
    t.integer "height_inches"
    t.integer "weight_lbs"
    t.date "birth_date"
    t.integer "years_exp"
    t.json "metadata", default: {}
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["active"], name: "index_players_on_active"
    t.index ["espn_id"], name: "index_players_on_espn_id"
    t.index ["name", "position"], name: "index_players_on_name_and_position"
    t.index ["position"], name: "index_players_on_position"
    t.index ["pro_football_reference_url"], name: "index_players_on_pro_football_reference_url", unique: true
    t.index ["sleeper_id"], name: "index_players_on_sleeper_id"
  end

  create_table "qb_season_stats", force: :cascade do |t|
    t.bigint "player_id", null: false
    t.integer "season", null: false
    t.string "team_abbr", null: false
    t.integer "age"
    t.integer "games", default: 0
    t.integer "games_started", default: 0
    t.string "qb_record"
    t.integer "pass_cmp", default: 0
    t.integer "pass_att", default: 0
    t.integer "pass_yds", default: 0
    t.integer "pass_td", default: 0
    t.integer "pass_int", default: 0
    t.decimal "pass_cmp_pct", precision: 5, scale: 2
    t.decimal "pass_rating", precision: 5, scale: 2
    t.integer "rush_att", default: 0
    t.integer "rush_yds", default: 0
    t.integer "rush_td", default: 0
    t.integer "fumbles", default: 0
    t.decimal "pass_yds_per_att", precision: 5, scale: 2
    t.decimal "qbr", precision: 5, scale: 2
    t.integer "pass_sacked", default: 0
    t.integer "pass_sacked_yds", default: 0
    t.decimal "pass_sacked_pct", precision: 5, scale: 2
    t.json "advanced_passing", default: {}
    t.json "pressure_stats", default: {}
    t.json "situational_stats", default: {}
    t.json "raw_season_data", default: {}
    t.json "raw_advanced_data", default: {}
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.decimal "fantasy_points_std", precision: 8, scale: 2
    t.decimal "fantasy_points_half_ppr", precision: 8, scale: 2
    t.decimal "fantasy_points_ppr", precision: 8, scale: 2
    t.index "((advanced_passing ->> 'pass_air_yds'::text))", name: "index_qb_season_stats_on_advanced_passing_pass_air_yds"
    t.index "((pressure_stats ->> 'pass_pressured_pct'::text))", name: "index_qb_season_stats_on_pressure_stats_pass_pressured_pct"
    t.index ["fantasy_points_half_ppr"], name: "index_qb_season_stats_on_fantasy_points_half_ppr"
    t.index ["fantasy_points_ppr"], name: "index_qb_season_stats_on_fantasy_points_ppr"
    t.index ["fantasy_points_std"], name: "index_qb_season_stats_on_fantasy_points_std"
    t.index ["player_id", "season"], name: "index_qb_season_stats_on_player_id_and_season", unique: true
    t.index ["player_id"], name: "index_qb_season_stats_on_player_id"
    t.index ["season", "pass_rating"], name: "index_qb_season_stats_on_season_and_pass_rating"
    t.index ["season", "pass_td"], name: "index_qb_season_stats_on_season_and_pass_td"
    t.index ["season", "pass_yds"], name: "index_qb_season_stats_on_season_and_pass_yds"
    t.index ["team_abbr"], name: "index_qb_season_stats_on_team_abbr"
  end

  create_table "qb_weekly_stats", force: :cascade do |t|
    t.bigint "player_id", null: false
    t.integer "season", null: false
    t.integer "week", null: false
    t.string "team_abbr", null: false
    t.date "game_date"
    t.string "opponent"
    t.boolean "home_game", default: true
    t.integer "pass_cmp", default: 0
    t.integer "pass_att", default: 0
    t.integer "pass_yds", default: 0
    t.integer "pass_td", default: 0
    t.integer "pass_int", default: 0
    t.integer "rush_att", default: 0
    t.integer "rush_yds", default: 0
    t.integer "rush_td", default: 0
    t.integer "fumbles", default: 0
    t.decimal "fantasy_points_std", precision: 8, scale: 2
    t.decimal "fantasy_points_half_ppr", precision: 8, scale: 2
    t.decimal "fantasy_points_ppr", precision: 8, scale: 2
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["player_id", "season", "week"], name: "index_qb_weekly_stats_on_player_id_and_season_and_week", unique: true
    t.index ["player_id"], name: "index_qb_weekly_stats_on_player_id"
    t.index ["season", "week"], name: "index_qb_weekly_stats_on_season_and_week"
    t.index ["team_abbr"], name: "index_qb_weekly_stats_on_team_abbr"
  end

  create_table "rb_season_stats", force: :cascade do |t|
    t.bigint "player_id", null: false
    t.integer "season", null: false
    t.string "team_abbr", null: false
    t.integer "age"
    t.integer "games", default: 0
    t.integer "games_started", default: 0
    t.integer "rush_att", default: 0
    t.integer "rush_yds", default: 0
    t.integer "rush_td", default: 0
    t.decimal "rush_yds_per_att", precision: 5, scale: 2
    t.integer "rush_long", default: 0
    t.integer "targets", default: 0
    t.integer "rec", default: 0
    t.integer "rec_yds", default: 0
    t.integer "rec_td", default: 0
    t.decimal "catch_pct", precision: 5, scale: 2
    t.decimal "rec_yds_per_tgt", precision: 5, scale: 2
    t.integer "touches", default: 0
    t.integer "yds_from_scrimmage", default: 0
    t.integer "total_td", default: 0
    t.integer "fumbles", default: 0
    t.decimal "yds_per_touch", precision: 5, scale: 2
    t.decimal "rush_success_rate", precision: 5, scale: 2
    t.decimal "rec_success_rate", precision: 5, scale: 2
    t.json "rushing_advanced", default: {}
    t.json "receiving_advanced", default: {}
    t.json "efficiency_metrics", default: {}
    t.json "raw_season_data", default: {}
    t.json "raw_advanced_data", default: {}
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.decimal "fantasy_points_std", precision: 8, scale: 2
    t.decimal "fantasy_points_half_ppr", precision: 8, scale: 2
    t.decimal "fantasy_points_ppr", precision: 8, scale: 2
    t.index "((receiving_advanced ->> 'rec_adot'::text))", name: "index_rb_season_stats_on_receiving_advanced_rec_adot"
    t.index "((rushing_advanced ->> 'rush_yds_before_contact'::text))", name: "idx_on_rushing_advanced_rush_yds_before_contact_7d91c298b5"
    t.index ["fantasy_points_half_ppr"], name: "index_rb_season_stats_on_fantasy_points_half_ppr"
    t.index ["fantasy_points_ppr"], name: "index_rb_season_stats_on_fantasy_points_ppr"
    t.index ["fantasy_points_std"], name: "index_rb_season_stats_on_fantasy_points_std"
    t.index ["player_id", "season"], name: "index_rb_season_stats_on_player_id_and_season", unique: true
    t.index ["player_id"], name: "index_rb_season_stats_on_player_id"
    t.index ["season", "rush_yds"], name: "index_rb_season_stats_on_season_and_rush_yds"
    t.index ["season", "targets"], name: "index_rb_season_stats_on_season_and_targets"
    t.index ["season", "total_td"], name: "index_rb_season_stats_on_season_and_total_td"
    t.index ["season", "yds_from_scrimmage"], name: "index_rb_season_stats_on_season_and_yds_from_scrimmage"
    t.index ["team_abbr"], name: "index_rb_season_stats_on_team_abbr"
  end

  create_table "rb_weekly_stats", force: :cascade do |t|
    t.bigint "player_id", null: false
    t.integer "season", null: false
    t.integer "week", null: false
    t.string "team_abbr", null: false
    t.date "game_date"
    t.string "opponent"
    t.boolean "home_game", default: true
    t.integer "rush_att", default: 0
    t.integer "rush_yds", default: 0
    t.integer "rush_td", default: 0
    t.integer "targets", default: 0
    t.integer "rec", default: 0
    t.integer "rec_yds", default: 0
    t.integer "rec_td", default: 0
    t.integer "fumbles", default: 0
    t.decimal "fantasy_points_std", precision: 8, scale: 2
    t.decimal "fantasy_points_half_ppr", precision: 8, scale: 2
    t.decimal "fantasy_points_ppr", precision: 8, scale: 2
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["player_id", "season", "week"], name: "index_rb_weekly_stats_on_player_id_and_season_and_week", unique: true
    t.index ["player_id"], name: "index_rb_weekly_stats_on_player_id"
    t.index ["season", "week"], name: "index_rb_weekly_stats_on_season_and_week"
    t.index ["team_abbr"], name: "index_rb_weekly_stats_on_team_abbr"
  end

  create_table "te_season_stats", force: :cascade do |t|
    t.bigint "player_id", null: false
    t.integer "season", null: false
    t.string "team_abbr", null: false
    t.integer "age"
    t.integer "games", default: 0
    t.integer "games_started", default: 0
    t.integer "targets", default: 0
    t.integer "rec", default: 0
    t.integer "rec_yds", default: 0
    t.integer "rec_td", default: 0
    t.decimal "catch_pct", precision: 5, scale: 2
    t.decimal "rec_yds_per_rec", precision: 5, scale: 2
    t.decimal "rec_yds_per_tgt", precision: 5, scale: 2
    t.integer "rec_long", default: 0
    t.integer "rush_att", default: 0
    t.integer "rush_yds", default: 0
    t.integer "rush_td", default: 0
    t.integer "touches", default: 0
    t.integer "yds_from_scrimmage", default: 0
    t.integer "total_td", default: 0
    t.integer "fumbles", default: 0
    t.decimal "yds_per_touch", precision: 5, scale: 2
    t.decimal "rec_success_rate", precision: 5, scale: 2
    t.json "receiving_advanced", default: {}
    t.json "blocking_metrics", default: {}
    t.json "target_metrics", default: {}
    t.json "raw_season_data", default: {}
    t.json "raw_advanced_data", default: {}
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.decimal "fantasy_points_std", precision: 8, scale: 2
    t.decimal "fantasy_points_half_ppr", precision: 8, scale: 2
    t.decimal "fantasy_points_ppr", precision: 8, scale: 2
    t.index "((receiving_advanced ->> 'rec_adot'::text))", name: "index_te_season_stats_on_receiving_advanced_rec_adot"
    t.index "((target_metrics ->> 'red_zone_targets'::text))", name: "index_te_season_stats_on_target_metrics_red_zone_targets"
    t.index ["fantasy_points_half_ppr"], name: "index_te_season_stats_on_fantasy_points_half_ppr"
    t.index ["fantasy_points_ppr"], name: "index_te_season_stats_on_fantasy_points_ppr"
    t.index ["fantasy_points_std"], name: "index_te_season_stats_on_fantasy_points_std"
    t.index ["player_id", "season"], name: "index_te_season_stats_on_player_id_and_season", unique: true
    t.index ["player_id"], name: "index_te_season_stats_on_player_id"
    t.index ["season", "rec_td"], name: "index_te_season_stats_on_season_and_rec_td"
    t.index ["season", "rec_yds"], name: "index_te_season_stats_on_season_and_rec_yds"
    t.index ["season", "targets"], name: "index_te_season_stats_on_season_and_targets"
    t.index ["team_abbr"], name: "index_te_season_stats_on_team_abbr"
  end

  create_table "te_weekly_stats", force: :cascade do |t|
    t.bigint "player_id", null: false
    t.integer "season", null: false
    t.integer "week", null: false
    t.string "team_abbr", null: false
    t.date "game_date"
    t.string "opponent"
    t.boolean "home_game", default: true
    t.integer "targets", default: 0
    t.integer "rec", default: 0
    t.integer "rec_yds", default: 0
    t.integer "rec_td", default: 0
    t.integer "rush_att", default: 0
    t.integer "rush_yds", default: 0
    t.integer "rush_td", default: 0
    t.integer "fumbles", default: 0
    t.decimal "fantasy_points_std", precision: 8, scale: 2
    t.decimal "fantasy_points_half_ppr", precision: 8, scale: 2
    t.decimal "fantasy_points_ppr", precision: 8, scale: 2
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["player_id", "season", "week"], name: "index_te_weekly_stats_on_player_id_and_season_and_week", unique: true
    t.index ["player_id"], name: "index_te_weekly_stats_on_player_id"
    t.index ["season", "week"], name: "index_te_weekly_stats_on_season_and_week"
    t.index ["team_abbr"], name: "index_te_weekly_stats_on_team_abbr"
  end

  create_table "wr_season_stats", force: :cascade do |t|
    t.bigint "player_id", null: false
    t.integer "season", null: false
    t.string "team_abbr", null: false
    t.integer "age"
    t.integer "games", default: 0
    t.integer "games_started", default: 0
    t.integer "targets", default: 0
    t.integer "rec", default: 0
    t.integer "rec_yds", default: 0
    t.integer "rec_td", default: 0
    t.decimal "catch_pct", precision: 5, scale: 2
    t.decimal "rec_yds_per_rec", precision: 5, scale: 2
    t.decimal "rec_yds_per_tgt", precision: 5, scale: 2
    t.integer "rec_long", default: 0
    t.integer "rush_att", default: 0
    t.integer "rush_yds", default: 0
    t.integer "rush_td", default: 0
    t.decimal "rush_yds_per_att", precision: 5, scale: 2
    t.integer "touches", default: 0
    t.integer "yds_from_scrimmage", default: 0
    t.integer "total_td", default: 0
    t.integer "fumbles", default: 0
    t.decimal "yds_per_touch", precision: 5, scale: 2
    t.decimal "rec_success_rate", precision: 5, scale: 2
    t.json "receiving_advanced", default: {}
    t.json "target_metrics", default: {}
    t.json "efficiency_metrics", default: {}
    t.json "raw_season_data", default: {}
    t.json "raw_advanced_data", default: {}
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.decimal "fantasy_points_std", precision: 8, scale: 2
    t.decimal "fantasy_points_half_ppr", precision: 8, scale: 2
    t.decimal "fantasy_points_ppr", precision: 8, scale: 2
    t.index "((receiving_advanced ->> 'rec_adot'::text))", name: "index_wr_season_stats_on_receiving_advanced_rec_adot"
    t.index "((receiving_advanced ->> 'rec_air_yds'::text))", name: "index_wr_season_stats_on_receiving_advanced_rec_air_yds"
    t.index "((target_metrics ->> 'target_share'::text))", name: "index_wr_season_stats_on_target_metrics_target_share"
    t.index ["fantasy_points_half_ppr"], name: "index_wr_season_stats_on_fantasy_points_half_ppr"
    t.index ["fantasy_points_ppr"], name: "index_wr_season_stats_on_fantasy_points_ppr"
    t.index ["fantasy_points_std"], name: "index_wr_season_stats_on_fantasy_points_std"
    t.index ["player_id", "season"], name: "index_wr_season_stats_on_player_id_and_season", unique: true
    t.index ["player_id"], name: "index_wr_season_stats_on_player_id"
    t.index ["season", "catch_pct"], name: "index_wr_season_stats_on_season_and_catch_pct"
    t.index ["season", "rec_td"], name: "index_wr_season_stats_on_season_and_rec_td"
    t.index ["season", "rec_yds"], name: "index_wr_season_stats_on_season_and_rec_yds"
    t.index ["season", "targets"], name: "index_wr_season_stats_on_season_and_targets"
    t.index ["team_abbr"], name: "index_wr_season_stats_on_team_abbr"
  end

  create_table "wr_weekly_stats", force: :cascade do |t|
    t.bigint "player_id", null: false
    t.integer "season", null: false
    t.integer "week", null: false
    t.string "team_abbr", null: false
    t.date "game_date"
    t.string "opponent"
    t.boolean "home_game", default: true
    t.integer "targets", default: 0
    t.integer "rec", default: 0
    t.integer "rec_yds", default: 0
    t.integer "rec_td", default: 0
    t.integer "rush_att", default: 0
    t.integer "rush_yds", default: 0
    t.integer "rush_td", default: 0
    t.integer "fumbles", default: 0
    t.decimal "fantasy_points_std", precision: 8, scale: 2
    t.decimal "fantasy_points_half_ppr", precision: 8, scale: 2
    t.decimal "fantasy_points_ppr", precision: 8, scale: 2
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["player_id", "season", "week"], name: "index_wr_weekly_stats_on_player_id_and_season_and_week", unique: true
    t.index ["player_id"], name: "index_wr_weekly_stats_on_player_id"
    t.index ["season", "week"], name: "index_wr_weekly_stats_on_season_and_week"
    t.index ["team_abbr"], name: "index_wr_weekly_stats_on_team_abbr"
  end

  add_foreign_key "qb_season_stats", "players"
  add_foreign_key "qb_weekly_stats", "players"
  add_foreign_key "rb_season_stats", "players"
  add_foreign_key "rb_weekly_stats", "players"
  add_foreign_key "te_season_stats", "players"
  add_foreign_key "te_weekly_stats", "players"
  add_foreign_key "wr_season_stats", "players"
  add_foreign_key "wr_weekly_stats", "players"
end
