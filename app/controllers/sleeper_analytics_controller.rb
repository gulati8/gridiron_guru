class SleeperAnalyticsController < ApplicationController
  before_action :set_league, only: [:show]

  def index
    @leagues = SleeperLeague.includes(:sleeper_users, :sleeper_rosters, :sleeper_drafts)
                           .order(:season)
    @total_users = SleeperUser.count
    @total_matchups = SleeperMatchup.count
    @total_transactions = SleeperTransaction.count
    @seasons_data = calculate_seasons_summary
  end

  def leagues
    @leagues = SleeperLeague.includes(:sleeper_users, :sleeper_rosters, :sleeper_matchups, :sleeper_drafts)
                           .order(:season)
  end

  def show
    @rosters = @league.sleeper_rosters.includes(:sleeper_user, :sleeper_matchups)
    @draft = @league.sleeper_drafts.first
    @recent_transactions = @league.sleeper_transactions.order(created_at: :desc).limit(10)
    @league_stats = calculate_league_stats
  end

  def draft_analysis
    @drafts = SleeperDraft.includes(:sleeper_league, :sleeper_draft_picks => :sleeper_roster)
                          .joins(:sleeper_league)
                          .order('sleeper_leagues.season DESC')
    @draft_performance = calculate_draft_performance
    
    # Enhanced draft analysis with player stats
    @player_stats_available = SleeperPlayerStat.exists?
    if @player_stats_available
      @draft_value_analysis = calculate_draft_value_analysis
      @position_draft_trends = calculate_position_draft_trends
      @steal_and_bust_analysis = calculate_steal_and_bust_analysis
    end
  end

  def player_performance
    @player_stats_available = SleeperPlayerStat.exists?
    
    if @player_stats_available
      @player_stats_summary = calculate_player_stats_summary
      @top_performers_by_position = calculate_top_performers_by_position
      @position_scarcity = calculate_position_scarcity_analysis
      @consistency_leaders = calculate_consistency_leaders
      @breakout_candidates = calculate_breakout_candidates
      @draft_strategy = calculate_draft_strategy_recommendations
      
      # Handle player search
      if params[:player_search].present?
        @searched_players = search_players(params[:player_search], params[:position_filter])
      end
    end
  end

  def team_performance
    @team_stats = calculate_team_performance_by_season
    @team_trends = calculate_team_trends
  end

  def transaction_analysis
    @transaction_stats = calculate_transaction_statistics
    @transaction_trends = calculate_transaction_trends_by_user
    @weekly_activity = calculate_weekly_transaction_activity
  end

  def player_charts
    @player_stats_available = SleeperPlayerStat.exists?
    
    if @player_stats_available
      @chart_data = generate_chart_data
    else
      redirect_to sleeper_analytics_path, alert: 'No player stats available for charting'
    end
  end

  private

  def set_league
    @league = SleeperLeague.find(params[:id])
  end

  def calculate_seasons_summary
    # Simplified summary calculation
    league_summaries = {}
    SleeperLeague.includes(:sleeper_rosters, :sleeper_matchups).each do |league|
      league_summaries[league.season] = {
        name: league.name,
        rosters: league.sleeper_rosters.count,
        matchups: league.sleeper_matchups.count,
        avg_points: league.sleeper_matchups.average(:points)&.round(2) || 0
      }
    end
    league_summaries
  end

  def calculate_league_stats
    {
      total_weeks: @league.sleeper_matchups.maximum(:week) || 0,
      avg_points_per_week: @league.sleeper_matchups.average(:points)&.round(2) || 0,
      highest_score: @league.sleeper_matchups.maximum(:points) || 0,
      lowest_score: @league.sleeper_matchups.minimum(:points) || 0,
      total_transactions: @league.sleeper_transactions.count
    }
  end

  def calculate_draft_performance
    # Analyze how teams performed over the season
    performance_data = {}
    
    SleeperDraft.includes(:sleeper_league, sleeper_draft_picks: [:sleeper_roster]).each do |draft|
      league = draft.sleeper_league
      season_performance = []
      
      # Group by roster to get one entry per team
      draft.sleeper_draft_picks.group_by(&:sleeper_roster).each do |roster, picks|
        roster_matchups = roster.sleeper_matchups.where(season: league.season)
        avg_points = roster_matchups.average(:points) || 0
        total_points = roster_matchups.sum(:points) || 0
        
        season_performance << {
          roster_owner: roster.sleeper_user.display_name,
          avg_points: avg_points.round(2),
          total_points: total_points,
          total_picks: picks.count
        }
      end
      
      performance_data[league.season] = season_performance.sort_by { |p| -p[:total_points] }
    end
    
    performance_data
  end

  def calculate_player_stats_summary
    return {} unless SleeperPlayerStat.exists?
    
    total_records = SleeperPlayerStat.count
    seasons_covered = SleeperPlayerStat.distinct.pluck(:season).sort
    positions_covered = SleeperPlayerStat.distinct.pluck(:position).sort
    
    # Find top scorer across all seasons/weeks
    top_scorer = SleeperPlayerStat.order(fantasy_points_ppr: :desc).first
    
    {
      total_records: total_records,
      seasons_covered: seasons_covered,
      positions_covered: positions_covered,
      top_scorer: {
        name: top_scorer&.player_name || 'N/A',
        points: top_scorer&.fantasy_points_ppr || 0
      }
    }
  end

  def calculate_top_performers_by_position
    performers = {}
    
    SleeperPlayerStat::SKILL_POSITIONS.each do |position|
      # Get top performers for most recent complete season
      recent_season = SleeperPlayerStat.maximum(:season) || Date.current.year
      
      performers[position] = SleeperPlayerStat
        .where(position: position, season: recent_season, season_type: 'regular')
        .where('fantasy_points_ppr > 0')
        .order(fantasy_points_ppr: :desc)
        .limit(10)
    end
    
    performers
  end

  def calculate_position_scarcity_analysis
    scarcity = {}
    recent_season = SleeperPlayerStat.maximum(:season) || Date.current.year
    
    SleeperPlayerStat::SKILL_POSITIONS.each do |position|
      players = SleeperPlayerStat
        .where(position: position, season: recent_season, season_type: 'regular')
        .where('fantasy_points_ppr > 0')
        
      if players.any?
        # Season totals for players in this position
        season_totals = players.group(:sleeper_player_id)
                              .sum(:fantasy_points_ppr)
                              .values
                              .sort
                              .reverse
        
        top_12 = season_totals.first(12)
        next_12 = season_totals[12..23] || []
        
        avg_top_12 = top_12.any? ? top_12.sum / top_12.size : 0
        avg_next_12 = next_12.any? ? next_12.sum / next_12.size : 0
        
        dropoff = avg_top_12 > 0 ? ((avg_top_12 - avg_next_12) / avg_top_12 * 100) : 0
        
        scarcity[position] = {
          top_tier: top_12.size,
          startable: (top_12 + next_12).size,
          avg_top_12: avg_top_12,
          avg_next_12: avg_next_12,
          dropoff: dropoff
        }
      end
    end
    
    scarcity
  end

  def calculate_consistency_leaders
    return [] unless SleeperPlayerStat.exists?
    
    recent_season = SleeperPlayerStat.maximum(:season) || Date.current.year
    
    # Find players with multiple games and calculate variance
    consistency_data = []
    
    SleeperPlayerStat.where(season: recent_season, season_type: 'regular')
                    .where('fantasy_points_ppr > 0')
                    .group(:sleeper_player_id, :player_name)
                    .having('COUNT(*) >= 8') # At least 8 games
                    .pluck(:sleeper_player_id, :player_name)
                    .each do |player_id, name|
      
      games = SleeperPlayerStat.where(
        sleeper_player_id: player_id, 
        season: recent_season, 
        season_type: 'regular'
      ).where('fantasy_points_ppr > 0')
      
      points = games.pluck(:fantasy_points_ppr)
      next if points.size < 8
      
      avg = points.sum / points.size
      variance = points.map { |p| (p - avg) ** 2 }.sum / points.size
      std_dev = Math.sqrt(variance)
      
      # Lower standard deviation = more consistent
      consistency_data << {
        name: name,
        consistency: std_dev.round(2)
      }
    end
    
    consistency_data.sort_by { |p| p[:consistency] }.first(10)
  end

  def calculate_breakout_candidates
    return [] unless SleeperPlayerStat.exists?
    
    seasons = SleeperPlayerStat.distinct.pluck(:season).sort
    return [] if seasons.size < 2
    
    current_season = seasons.last
    previous_season = seasons[-2]
    
    # Find players who improved significantly from previous season
    candidates = []
    
    SleeperPlayerStat.where(season: current_season, season_type: 'regular')
                    .group(:sleeper_player_id)
                    .having('SUM(fantasy_points_ppr) > 100') # Minimum production threshold
                    .pluck(:sleeper_player_id)
                    .each do |player_id|
      
      current_stats = SleeperPlayerStat.where(
        sleeper_player_id: player_id,
        season: current_season,
        season_type: 'regular'
      ).first
      
      previous_total = SleeperPlayerStat.where(
        sleeper_player_id: player_id,
        season: previous_season,
        season_type: 'regular'
      ).sum(:fantasy_points_ppr)
      
      current_total = SleeperPlayerStat.where(
        sleeper_player_id: player_id,
        season: current_season,
        season_type: 'regular'
      ).sum(:fantasy_points_ppr)
      
      # Look for significant improvement (50%+ increase or new breakout)
      if previous_total > 0 && (current_total / previous_total) > 1.5
        candidates << current_stats
      elsif previous_total < 50 && current_total > 150
        candidates << current_stats
      end
    end
    
    candidates.compact.first(10)
  end

  def calculate_draft_strategy_recommendations
    return {} unless SleeperPlayerStat.exists?
    
    scarcity = calculate_position_scarcity_analysis
    
    # Determine position priority based on scarcity
    position_priority = scarcity.sort_by { |pos, data| -data[:dropoff] }.first&.first || 'RB'
    
    # Find most scarce positions (highest dropoff)
    scarce_positions = scarcity.select { |pos, data| data[:dropoff] > 30 }
                              .map { |pos, data| pos }
                              .first(2)
    
    {
      position_priority: position_priority,
      scarce_positions: scarce_positions.any? ? scarce_positions : ['RB', 'WR']
    }
  end

  def search_players(search_term, position_filter = nil)
    query = SleeperPlayerStat.where('player_name ILIKE ?', "%#{search_term}%")
    
    if position_filter.present?
      query = query.where(position: position_filter)
    end
    
    # Group by player and get their best season
    query.joins(
      <<-SQL
        INNER JOIN (
          SELECT sleeper_player_id, season, MAX(fantasy_points_ppr) as max_points
          FROM sleeper_player_stats 
          WHERE season_type = 'regular'
          GROUP BY sleeper_player_id, season
        ) best_seasons ON sleeper_player_stats.sleeper_player_id = best_seasons.sleeper_player_id 
        AND sleeper_player_stats.season = best_seasons.season
      SQL
    ).order('best_seasons.max_points DESC')
     .limit(20)
  end

  def calculate_draft_value_analysis
    # Analyze draft picks vs actual performance
    return {} unless SleeperPlayerStat.exists?
    
    value_analysis = {}
    
    @drafts.each do |draft|
      season = draft.sleeper_league.season
      draft_picks = draft.sleeper_draft_picks.includes(:sleeper_roster)
      
      season_analysis = []
      
      draft_picks.each do |pick|
        # Skip if no player ID available
        next unless pick.sleeper_player_id.present?
        
        # Get actual performance for this player in this season
        actual_performance = SleeperPlayerStat.where(
          sleeper_player_id: pick.sleeper_player_id,
          season: season,
          season_type: 'regular'
        ).sum(:fantasy_points_ppr)
        
        # Calculate value based on draft position
        expected_value = calculate_expected_value_by_draft_position(pick.pick_no, pick.round)
        value_over_replacement = actual_performance - expected_value
        
        season_analysis << {
          pick_no: pick.pick_no,
          round: pick.round,
          player_id: pick.sleeper_player_id,
          owner: pick.sleeper_roster.sleeper_user.display_name,
          actual_points: actual_performance,
          expected_points: expected_value,
          value_over_replacement: value_over_replacement,
          value_grade: calculate_value_grade(value_over_replacement)
        }
      end
      
      value_analysis[season] = season_analysis.sort_by { |p| -p[:value_over_replacement] }
    end
    
    value_analysis
  end

  def calculate_position_draft_trends
    # Analyze which positions are drafted when and their success rates
    return {} unless SleeperPlayerStat.exists?
    
    trends = {}
    
    SleeperPlayerStat::SKILL_POSITIONS.each do |position|
      position_data = []
      
      @drafts.each do |draft|
        season = draft.sleeper_league.season
        
        # Find picks for this position
        position_picks = draft.sleeper_draft_picks.select do |pick|
          next unless pick.sleeper_player_id.present?
          
          player_stat = SleeperPlayerStat.where(
            sleeper_player_id: pick.sleeper_player_id,
            season: season,
            position: position
          ).first
          
          player_stat.present?
        end
        
        position_picks.each do |pick|
          actual_performance = SleeperPlayerStat.where(
            sleeper_player_id: pick.sleeper_player_id,
            season: season,
            season_type: 'regular'
          ).sum(:fantasy_points_ppr)
          
          position_data << {
            season: season,
            round: pick.round,
            pick_no: pick.pick_no,
            actual_points: actual_performance
          }
        end
      end
      
      if position_data.any?
        trends[position] = {
          avg_draft_round: position_data.map { |p| p[:round] }.sum.to_f / position_data.size,
          avg_points: position_data.map { |p| p[:actual_points] }.sum.to_f / position_data.size,
          early_round_success: calculate_early_round_success_rate(position_data),
          total_drafted: position_data.size
        }
      end
    end
    
    trends
  end

  def calculate_steal_and_bust_analysis
    # Find the biggest steals and busts from drafts
    return { steals: [], busts: [] } unless SleeperPlayerStat.exists?
    
    all_picks = []
    
    @drafts.each do |draft|
      season = draft.sleeper_league.season
      
      draft.sleeper_draft_picks.each do |pick|
        next unless pick.sleeper_player_id.present?
        
        actual_performance = SleeperPlayerStat.where(
          sleeper_player_id: pick.sleeper_player_id,
          season: season,
          season_type: 'regular'
        ).sum(:fantasy_points_ppr)
        
        expected_value = calculate_expected_value_by_draft_position(pick.pick_no, pick.round)
        value_diff = actual_performance - expected_value
        
        # Get player info
        player_info = SleeperPlayerStat.where(
          sleeper_player_id: pick.sleeper_player_id,
          season: season
        ).first
        
        next unless player_info
        
        all_picks << {
          season: season,
          round: pick.round,
          pick_no: pick.pick_no,
          player_name: player_info.player_name,
          position: player_info.position,
          owner: pick.sleeper_roster.sleeper_user.display_name,
          actual_points: actual_performance,
          expected_points: expected_value,
          value_diff: value_diff
        }
      end
    end
    
    # Sort to find steals and busts
    steals = all_picks.select { |p| p[:value_diff] > 50 }
                     .sort_by { |p| -p[:value_diff] }
                     .first(10)
    
    busts = all_picks.select { |p| p[:value_diff] < -50 }
                    .sort_by { |p| p[:value_diff] }
                    .first(10)
    
    { steals: steals, busts: busts }
  end

  private

  def calculate_expected_value_by_draft_position(pick_no, round)
    # Simple formula based on draft position - could be made more sophisticated
    base_value = case round
    when 1 then 200 - (pick_no * 8)   # First round: 200-8 per pick
    when 2 then 150 - (pick_no * 6)   # Second round: 150-6 per pick  
    when 3 then 120 - (pick_no * 4)   # Third round: 120-4 per pick
    when 4..6 then 100 - (pick_no * 2) # Mid rounds: 100-2 per pick
    else 50 - pick_no                 # Late rounds: 50-1 per pick
    end
    
    [base_value, 10].max # Minimum expected value of 10 points
  end

  def calculate_value_grade(value_over_replacement)
    case value_over_replacement
    when 100.. then 'A+'
    when 50..99 then 'A'
    when 25..49 then 'B+'
    when 0..24 then 'B'
    when -25..-1 then 'C'
    when -50..-26 then 'D'
    else 'F'
    end
  end

  def calculate_early_round_success_rate(position_data)
    early_picks = position_data.select { |p| p[:round] <= 3 }
    return 0 if early_picks.empty?
    
    successful = early_picks.count { |p| p[:actual_points] > 150 }
    (successful.to_f / early_picks.size * 100).round(1)
  end

  def calculate_team_performance_by_season
    team_stats = {}
    
    SleeperUser.includes(sleeper_rosters: [:sleeper_league, :sleeper_matchups]).each do |user|
      user_stats = {}
      
      user.sleeper_rosters.group_by { |r| r.sleeper_league.season }.each do |season, rosters|
        roster = rosters.first # Should be one roster per season
        matchups = roster.sleeper_matchups
        
        user_stats[season] = {
          wins: roster.wins,
          losses: roster.losses,
          ties: roster.ties,
          total_points: matchups.sum(:points),
          avg_points: matchups.average(:points)&.round(2) || 0,
          win_percentage: roster.win_percentage
        }
      end
      
      team_stats[user.display_name] = user_stats
    end
    
    team_stats
  end

  def calculate_team_trends
    # Calculate trends like improvement over seasons, consistency, etc.
    trends = {}
    
    calculate_team_performance_by_season.each do |user_name, seasons_data|
      sorted_seasons = seasons_data.sort_by { |season, _| season }
      
      if sorted_seasons.length >= 2
        latest = sorted_seasons.last[1]
        previous = sorted_seasons[-2][1]
        
        trends[user_name] = {
          points_trend: latest[:avg_points] - previous[:avg_points],
          wins_trend: latest[:wins] - previous[:wins],
          consistency: calculate_consistency(seasons_data)
        }
      end
    end
    
    trends
  end

  def calculate_consistency(seasons_data)
    avg_points = seasons_data.values.map { |s| s[:avg_points] }
    return 0 if avg_points.empty?
    
    mean = avg_points.sum.to_f / avg_points.length
    variance = avg_points.map { |points| (points - mean) ** 2 }.sum / avg_points.length
    Math.sqrt(variance).round(2)
  end

  def calculate_transaction_statistics
    stats = {}
    
    # Overall transaction stats
    stats[:total_transactions] = SleeperTransaction.count
    stats[:transactions_by_type] = SleeperTransaction.group(:transaction_type).count
    stats[:transactions_by_season] = SleeperTransaction.joins(:sleeper_league).group('sleeper_leagues.season').count
    stats[:most_active_week] = SleeperTransaction.group(:week).count.max_by { |week, count| count }&.first
    
    # User transaction stats - since transactions don't directly link to rosters/users,
    # we'll need to analyze this differently or skip for now
    stats[:user_activity] = {}
    
    stats
  end

  def calculate_transaction_trends_by_user
    # Since transactions don't directly link to users/rosters in the current model,
    # we'll create placeholder data for now
    trends = {}
    
    SleeperUser.includes(:sleeper_rosters).each do |user|
      trends[user.display_name] = {
        total_transactions: 0,
        transactions_by_type: {},
        transactions_by_season: {},
        avg_transactions_per_season: 0.0
      }
    end
    
    trends
  end

  def calculate_weekly_transaction_activity
    activity = {}
    
    SleeperLeague.includes(:sleeper_transactions).each do |league|
      activity[league.season] = league.sleeper_transactions
                                     .group(:week)
                                     .group(:transaction_type)
                                     .count
                                     .group_by { |(week, type), count| week }
                                     .transform_values { |entries| entries.to_h { |(week, type), count| [type, count] } }
    end
    
    activity
  end

  def generate_chart_data
    chart_data = {
      metadata: {
        generated_at: Time.current,
        total_records: SleeperPlayerStat.count,
        seasons: (2021..2024).to_a,
        positions: %w[QB RB WR TE]
      }
    }

    # Season Leaders Dataset
    chart_data[:season_leaders] = {}
    %w[QB RB WR TE].each do |position|
      chart_data[:season_leaders][position] = (2021..2024).map do |season|
        top_player = SleeperPlayerStat.where(season: season, position: position, season_type: 'regular')
                                      .where('fantasy_points_ppr > 0')
                                      .group(:player_name)
                                      .sum(:fantasy_points_ppr)
                                      .max_by { |k, v| v }
        
        if top_player
          name, points = top_player
          { season: season, player_name: name, fantasy_points: points.round(1) }
        else
          { season: season, player_name: nil, fantasy_points: 0 }
        end
      end
    end

    # Weekly Performance 2024
    chart_data[:weekly_performance_2024] = {}
    %w[QB RB WR TE].each do |position|
      top_players = SleeperPlayerStat.where(season: 2024, position: position, season_type: 'regular')
                                     .where('fantasy_points_ppr > 0')
                                     .group(:player_name)
                                     .sum(:fantasy_points_ppr)
                                     .sort_by { |k, v| -v }
                                     .first(5)
      
      chart_data[:weekly_performance_2024][position] = top_players.map do |player_name, total_points|
        weekly_stats = SleeperPlayerStat.where(
          season: 2024, 
          position: position, 
          season_type: 'regular',
          player_name: player_name
        ).order(:week)
         .pluck(:week, :fantasy_points_ppr)
        
        {
          player_name: player_name,
          total_points: total_points.round(1),
          weekly_data: weekly_stats.map { |week, points| { week: week, points: points.round(1) } }
        }
      end
    end

    # Position Scarcity
    chart_data[:position_scarcity_2024] = {}
    %w[QB RB WR TE].each do |position|
      season_totals = SleeperPlayerStat.where(season: 2024, position: position, season_type: 'regular')
                                       .where('fantasy_points_ppr > 0')
                                       .group(:player_name)
                                       .sum(:fantasy_points_ppr)
                                       .values
                                       .sort
                                       .reverse

      if season_totals.any?
        top_12 = season_totals.first(12)
        next_12 = season_totals[12..23] || []
        
        top_12_avg = (top_12.sum / 12.0).round(1)
        next_12_avg = next_12.any? ? (next_12.sum / next_12.length.to_f).round(1) : 0
        dropoff = (top_12_avg - next_12_avg).round(1)
        
        chart_data[:position_scarcity_2024][position] = {
          top_12_average: top_12_avg,
          next_12_average: next_12_avg,
          dropoff: dropoff,
          total_players: season_totals.length
        }
      end
    end

    chart_data
  end
end
