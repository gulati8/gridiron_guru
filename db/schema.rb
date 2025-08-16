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

ActiveRecord::Schema[8.0].define(version: 2025_08_02_210654) do
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

  create_table "sleeper_draft_picks", force: :cascade do |t|
    t.bigint "sleeper_draft_id", null: false
    t.integer "pick_no", null: false
    t.integer "round", null: false
    t.bigint "sleeper_roster_id", null: false
    t.string "sleeper_player_id", null: false
    t.json "metadata"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["round"], name: "index_sleeper_draft_picks_on_round"
    t.index ["sleeper_draft_id", "pick_no"], name: "index_sleeper_draft_picks_on_sleeper_draft_id_and_pick_no", unique: true
    t.index ["sleeper_draft_id"], name: "index_sleeper_draft_picks_on_sleeper_draft_id"
    t.index ["sleeper_player_id"], name: "index_sleeper_draft_picks_on_sleeper_player_id"
    t.index ["sleeper_roster_id"], name: "index_sleeper_draft_picks_on_sleeper_roster_id"
  end

  create_table "sleeper_drafts", force: :cascade do |t|
    t.string "sleeper_draft_id", null: false
    t.bigint "sleeper_league_id", null: false
    t.string "draft_type", null: false
    t.string "status", null: false
    t.json "settings"
    t.json "metadata"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["sleeper_draft_id"], name: "index_sleeper_drafts_on_sleeper_draft_id", unique: true
    t.index ["sleeper_league_id"], name: "index_sleeper_drafts_on_sleeper_league_id"
    t.index ["status"], name: "index_sleeper_drafts_on_status"
  end

  create_table "sleeper_leagues", force: :cascade do |t|
    t.string "sleeper_league_id", null: false
    t.string "name", null: false
    t.integer "season", null: false
    t.integer "total_rosters", null: false
    t.string "status", null: false
    t.json "scoring_settings"
    t.json "roster_positions"
    t.json "settings"
    t.string "league_type"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["season", "status"], name: "index_sleeper_leagues_on_season_and_status"
    t.index ["season"], name: "index_sleeper_leagues_on_season"
    t.index ["sleeper_league_id"], name: "index_sleeper_leagues_on_sleeper_league_id", unique: true
  end

  create_table "sleeper_matchups", force: :cascade do |t|
    t.bigint "sleeper_league_id", null: false
    t.integer "week", null: false
    t.integer "season", null: false
    t.bigint "sleeper_roster_id", null: false
    t.decimal "points", precision: 8, scale: 2
    t.string "opponent_roster_id"
    t.decimal "opponent_points", precision: 8, scale: 2
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["season"], name: "index_sleeper_matchups_on_season"
    t.index ["sleeper_league_id", "week", "season"], name: "idx_on_sleeper_league_id_week_season_891ab9cf0a"
    t.index ["sleeper_league_id"], name: "index_sleeper_matchups_on_sleeper_league_id"
    t.index ["sleeper_roster_id", "season", "week"], name: "idx_on_sleeper_roster_id_season_week_bb6f23d4fa"
    t.index ["sleeper_roster_id"], name: "index_sleeper_matchups_on_sleeper_roster_id"
  end

  create_table "sleeper_player_stats", force: :cascade do |t|
    t.string "sleeper_player_id", null: false
    t.string "player_name", null: false
    t.string "position", null: false
    t.string "team"
    t.integer "season", null: false
    t.integer "week", null: false
    t.string "season_type", default: "regular", null: false
    t.json "stats"
    t.decimal "fantasy_points_standard", precision: 8, scale: 2
    t.decimal "fantasy_points_half_ppr", precision: 8, scale: 2
    t.decimal "fantasy_points_ppr", precision: 8, scale: 2
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["fantasy_points_ppr"], name: "index_sleeper_player_stats_on_fantasy_points_ppr"
    t.index ["position", "season", "week"], name: "index_sleeper_player_stats_on_position_and_season_and_week"
    t.index ["position"], name: "index_sleeper_player_stats_on_position"
    t.index ["season", "week", "season_type"], name: "index_sleeper_player_stats_on_season_and_week_and_season_type"
    t.index ["sleeper_player_id", "season", "week", "season_type"], name: "idx_sleeper_player_stats_unique", unique: true
    t.index ["sleeper_player_id"], name: "index_sleeper_player_stats_on_sleeper_player_id"
  end

  create_table "sleeper_players", force: :cascade do |t|
    t.string "sleeper_player_id", null: false
    t.string "first_name"
    t.string "last_name"
    t.string "full_name"
    t.string "position"
    t.string "team"
    t.integer "years_exp"
    t.string "height"
    t.string "weight"
    t.integer "age"
    t.string "birth_date"
    t.string "college"
    t.string "status"
    t.json "player_data"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["full_name"], name: "index_sleeper_players_on_full_name"
    t.index ["position", "team"], name: "index_sleeper_players_on_position_and_team"
    t.index ["sleeper_player_id"], name: "index_sleeper_players_on_sleeper_player_id", unique: true
    t.index ["status"], name: "index_sleeper_players_on_status"
  end

  create_table "sleeper_rosters", force: :cascade do |t|
    t.string "sleeper_roster_id", null: false
    t.bigint "sleeper_league_id", null: false
    t.bigint "sleeper_user_id", null: false
    t.json "settings"
    t.text "players"
    t.integer "wins", default: 0
    t.integer "losses", default: 0
    t.integer "ties", default: 0
    t.integer "total_moves", default: 0
    t.integer "waiver_position"
    t.integer "waiver_budget_used", default: 0
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["sleeper_league_id"], name: "index_sleeper_rosters_on_sleeper_league_id"
    t.index ["sleeper_roster_id", "sleeper_league_id"], name: "idx_on_sleeper_roster_id_sleeper_league_id_f4e944a8ba", unique: true
    t.index ["sleeper_user_id"], name: "index_sleeper_rosters_on_sleeper_user_id"
  end

  create_table "sleeper_transactions", force: :cascade do |t|
    t.string "sleeper_transaction_id", null: false
    t.bigint "sleeper_league_id", null: false
    t.string "transaction_type", null: false
    t.string "status", null: false
    t.integer "week", null: false
    t.integer "season", null: false
    t.json "metadata"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["season"], name: "index_sleeper_transactions_on_season"
    t.index ["sleeper_league_id", "week", "season"], name: "idx_on_sleeper_league_id_week_season_047050a1b0"
    t.index ["sleeper_league_id"], name: "index_sleeper_transactions_on_sleeper_league_id"
    t.index ["sleeper_transaction_id"], name: "index_sleeper_transactions_on_sleeper_transaction_id", unique: true
    t.index ["transaction_type"], name: "index_sleeper_transactions_on_transaction_type"
  end

  create_table "sleeper_users", force: :cascade do |t|
    t.string "sleeper_user_id", null: false
    t.string "username"
    t.string "display_name"
    t.string "avatar"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["sleeper_user_id"], name: "index_sleeper_users_on_sleeper_user_id", unique: true
    t.index ["username"], name: "index_sleeper_users_on_username"
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
  add_foreign_key "sleeper_draft_picks", "sleeper_drafts"
  add_foreign_key "sleeper_draft_picks", "sleeper_rosters"
  add_foreign_key "sleeper_drafts", "sleeper_leagues"
  add_foreign_key "sleeper_matchups", "sleeper_leagues"
  add_foreign_key "sleeper_matchups", "sleeper_rosters"
  add_foreign_key "sleeper_rosters", "sleeper_leagues"
  add_foreign_key "sleeper_rosters", "sleeper_users"
  add_foreign_key "sleeper_transactions", "sleeper_leagues"
  add_foreign_key "te_season_stats", "players"
  add_foreign_key "te_weekly_stats", "players"
  add_foreign_key "wr_season_stats", "players"
  add_foreign_key "wr_weekly_stats", "players"
end
