class SleeperImportService
  include ActiveModel::Model
  
  attr_accessor :username, :seasons
  
  validates :username, presence: true
  validates :seasons, presence: true
  
  def initialize(username:, seasons: [])
    @username = username
    @seasons = Array(seasons)
    @api_service = SleeperApiService.new
    @imported_data = {
      leagues: 0,
      users: 0,
      rosters: 0,
      matchups: 0,
      drafts: 0,
      draft_picks: 0,
      transactions: 0
    }
  end
  
  def call
    return false unless valid?
    
    begin
      # Import players first (only if not already imported)
      import_players_if_needed
      
      user_data = fetch_user_data
      return false unless user_data
      
      import_leagues_for_seasons(user_data['user_id'])
      
      Rails.logger.info "Successfully imported Sleeper data for #{username}: #{@imported_data}"
      true
    rescue SleeperApiError => e
      Rails.logger.error "Sleeper Import failed: #{e.message}"
      false
    rescue => e
      Rails.logger.error "Sleeper Import failed with unexpected error: #{e.message}"
      false
    end
  end
  
  def imported_data
    @imported_data
  end
  
  private
  
  def import_players_if_needed
    # Only import players if we have fewer than 1000 (indicating empty or incomplete data)
    if SleeperPlayer.count < 1000
      Rails.logger.info "Importing Sleeper players (current count: #{SleeperPlayer.count})"
      players_imported = SleeperPlayer.import_from_sleeper_api(use_cache: true)
      Rails.logger.info "Imported #{players_imported} players"
    else
      Rails.logger.info "Skipping player import (#{SleeperPlayer.count} players already exist)"
    end
  end
  
  def fetch_user_data
    user_data = @api_service.get_user(@username)
    unless user_data
      Rails.logger.error "User not found: #{@username}"
      return nil
    end
    
    Rails.logger.info "Found user: #{user_data['display_name']} (#{user_data['username']})"
    user_data
  end
  
  def import_leagues_for_seasons(user_id)
    @seasons.each do |season|
      Rails.logger.info "Importing season #{season} for user #{user_id}"
      import_season_data(user_id, season)
    end
  end
  
  def import_season_data(user_id, season)
    leagues_data = @api_service.get_user_leagues(user_id, season)
    return unless leagues_data&.any?
    
    leagues_data.each do |league_data|
      import_league_complete_history(league_data, season)
    end
  end
  
  def import_league_complete_history(league_data, season)
    league_id = league_data['league_id']
    Rails.logger.info "Importing complete history for league: #{league_data['name']} (#{league_id})"
    
    # Import league details
    league = import_league(league_data, season)
    
    # Import users
    import_league_users(league_id, league)
    
    # Import rosters
    import_league_rosters(league_id, league)
    
    # Import all matchups for the season (weeks 1-18)
    import_all_matchups(league_id, league, season)
    
    # Import drafts and draft picks
    import_league_drafts(league_id, league)
    
    # Import transactions for all weeks
    import_all_transactions(league_id, league, season)
  end
  
  def import_league(league_data, season)
    league = SleeperLeague.find_or_initialize_by(sleeper_league_id: league_data['league_id'])
    
    league.assign_attributes(
      name: league_data['name'],
      season: season,
      total_rosters: league_data['total_rosters'],
      status: league_data['status'],
      scoring_settings: league_data['scoring_settings'],
      roster_positions: league_data['roster_positions'],
      settings: league_data['settings'],
      league_type: league_data['settings']&.dig('type')
    )
    
    league.save!
    @imported_data[:leagues] += 1
    
    Rails.logger.info "Imported league: #{league.name}"
    league
  end
  
  def import_league_users(league_id, league)
    users_data = @api_service.get_league_users(league_id)
    return unless users_data&.any?
    
    users_data.each do |user_data|
      import_user(user_data)
    end
  end
  
  def import_user(user_data)
    user = SleeperUser.find_or_initialize_by(sleeper_user_id: user_data['user_id'])
    
    user.assign_attributes(
      username: user_data['username'],
      display_name: user_data['display_name'],
      avatar: user_data['avatar']
    )
    
    if user.save
      @imported_data[:users] += 1
      Rails.logger.info "Imported user: #{user.display_name || user.username}"
      user
    else
      Rails.logger.error "Failed to save user: #{user.errors.full_messages.join(', ')}"
      raise "Failed to save user: #{user.errors.full_messages.join(', ')}"
    end
  end
  
  def import_league_rosters(league_id, league)
    rosters_data = @api_service.get_league_rosters(league_id)
    return unless rosters_data&.any?
    
    rosters_data.each do |roster_data|
      import_roster(roster_data, league)
    end
  end
  
  def import_roster(roster_data, league)
    user = SleeperUser.find_by(sleeper_user_id: roster_data['owner_id'])
    return unless user
    
    roster = SleeperRoster.find_or_initialize_by(
      sleeper_roster_id: roster_data['roster_id'],
      sleeper_league: league
    )
    
    roster.assign_attributes(
      sleeper_user: user,
      settings: roster_data['settings'],
      players: roster_data['players'] || [],
      wins: roster_data['settings']&.dig('wins') || 0,
      losses: roster_data['settings']&.dig('losses') || 0,
      ties: roster_data['settings']&.dig('ties') || 0,
      total_moves: roster_data['settings']&.dig('total_moves') || 0,
      waiver_position: roster_data['settings']&.dig('waiver_position'),
      waiver_budget_used: roster_data['settings']&.dig('waiver_budget_used') || 0
    )
    
    roster.save!
    @imported_data[:rosters] += 1
    
    Rails.logger.info "Imported roster for: #{user.display_name || user.username}"
    roster
  end
  
  def import_all_matchups(league_id, league, season)
    (1..18).each do |week|
      import_weekly_matchups(league_id, league, season, week)
    end
  end
  
  def import_weekly_matchups(league_id, league, season, week)
    matchups_data = @api_service.get_league_matchups(league_id, week)
    return unless matchups_data&.any?
    
    # Group matchups by matchup_id to find opponents
    matchups_by_id = matchups_data.group_by { |m| m['matchup_id'] }
    
    matchups_data.each do |matchup_data|
      import_matchup(matchup_data, league, season, week, matchups_by_id)
    end
  end
  
  def import_matchup(matchup_data, league, season, week, matchups_by_id)
    roster = league.sleeper_rosters.find_by(sleeper_roster_id: matchup_data['roster_id'])
    return unless roster
    
    matchup = SleeperMatchup.find_or_initialize_by(
      sleeper_league: league,
      sleeper_roster: roster,
      week: week,
      season: season
    )
    
    # Find opponent data from the same matchup_id
    opponent_data = find_opponent_in_matchups(matchup_data, matchups_by_id)
    
    matchup.assign_attributes(
      points: matchup_data['points'],
      opponent_roster_id: opponent_data&.dig('roster_id'),
      opponent_points: opponent_data&.dig('points')
    )
    
    matchup.save!
    @imported_data[:matchups] += 1
    
    matchup
  end
  
  def find_opponent_in_matchups(current_matchup, matchups_by_id)
    # Find matchups with the same matchup_id
    matchup_id = current_matchup['matchup_id']
    return nil unless matchup_id
    
    same_matchup_teams = matchups_by_id[matchup_id] || []
    
    # Find the opponent (the other team in the same matchup)
    opponent = same_matchup_teams.find do |matchup|
      matchup['roster_id'] != current_matchup['roster_id']
    end
    
    opponent
  end
  
  def import_league_drafts(league_id, league)
    drafts_data = @api_service.get_league_drafts(league_id)
    return unless drafts_data&.any?
    
    drafts_data.each do |draft_data|
      draft = import_draft(draft_data, league)
      import_draft_picks(draft_data['draft_id'], draft) if draft
    end
  end
  
  def import_draft(draft_data, league)
    draft = SleeperDraft.find_or_initialize_by(sleeper_draft_id: draft_data['draft_id'])
    
    draft.assign_attributes(
      sleeper_league: league,
      draft_type: draft_data['type'],
      status: draft_data['status'],
      settings: draft_data['settings'],
      metadata: draft_data['metadata']
    )
    
    draft.save!
    @imported_data[:drafts] += 1
    
    Rails.logger.info "Imported draft: #{draft_data['type']} (#{draft_data['status']})"
    draft
  end
  
  def import_draft_picks(draft_id, draft)
    picks_data = @api_service.get_draft_picks(draft_id)
    return unless picks_data&.any?
    
    picks_data.each do |pick_data|
      import_draft_pick(pick_data, draft)
    end
  end
  
  def import_draft_pick(pick_data, draft)
    roster = draft.sleeper_league.sleeper_rosters.find_by(sleeper_roster_id: pick_data['roster_id'])
    return unless roster
    
    pick = SleeperDraftPick.find_or_initialize_by(
      sleeper_draft: draft,
      pick_no: pick_data['pick_no']
    )
    
    pick.assign_attributes(
      round: pick_data['round'],
      sleeper_roster: roster,
      sleeper_player_id: pick_data['player_id'],
      metadata: pick_data['metadata']
    )
    
    pick.save!
    @imported_data[:draft_picks] += 1
    
    pick
  end
  
  def import_all_transactions(league_id, league, season)
    (0..18).each do |week| # Week 0 includes pre-season transactions
      import_weekly_transactions(league_id, league, season, week)
    end
  end
  
  def import_weekly_transactions(league_id, league, season, week)
    transactions_data = @api_service.get_league_transactions(league_id, week)
    return unless transactions_data&.any?
    
    transactions_data.each do |transaction_data|
      import_transaction(transaction_data, league, season, week)
    end
  end
  
  def import_transaction(transaction_data, league, season, week)
    transaction = SleeperTransaction.find_or_initialize_by(
      sleeper_transaction_id: transaction_data['transaction_id']
    )
    
    transaction.assign_attributes(
      sleeper_league: league,
      transaction_type: transaction_data['type'],
      status: transaction_data['status'],
      week: week,
      season: season,
      metadata: transaction_data
    )
    
    transaction.save!
    @imported_data[:transactions] += 1
    
    transaction
  end
end