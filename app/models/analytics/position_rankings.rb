# app/models/analytics/position_rankings.rb
class Analytics::PositionRankings
  attr_reader :position, :season, :scoring_type
  
  def initialize(position, season = Date.current.year, scoring_type = :ppr)
    @position = position.upcase
    @season = season
    @scoring_type = scoring_type
  end
  
  def top_performers(limit = 50)
    stats_class = "#{position.capitalize}SeasonStat".constantize
    
    stats_records = stats_class.includes(:player)
                               .by_season(season)
                               .joins(:player)
                               .where(players: { active: true })
                               .limit(limit * 2) # Get more records in case some are filtered out
    
    # Sort by fantasy points (database column or calculated)
    sorted_stats = stats_records.sort_by do |stats|
      fantasy_points = get_fantasy_points(stats) || 0
      -fantasy_points # Sort descending
    end
    
    sorted_stats.take(limit).map do |stats|
      begin
        {
          player: stats.player,
          stats: stats,
          fantasy_points: get_fantasy_points(stats) || 0,
          efficiency_score: Analytics::PlayerAnalyzer.new(stats.player, season).fantasy_value_score || 0
        }
      rescue => e
        Rails.logger.error "Error processing player #{stats.player&.name}: #{e.message}"
        nil
      end
    end.compact
  end
  
  def sleeper_candidates(min_games = 8)
    # Players with good efficiency but low total production (due to limited opportunity)
    all_stats = top_performers(200)
    
    return [] if all_stats.empty?
    
    all_stats.select do |player_data|
      stats = player_data[:stats]
      games = stats.respond_to?(:games) ? (stats.games || 0) : 0
      efficiency_score = player_data[:efficiency_score] || 0
      fantasy_points = player_data[:fantasy_points] || 0
      
      games >= min_games && 
      efficiency_score > position_efficiency_threshold &&
      fantasy_points < position_volume_threshold
    end.sort_by { |p| -(p[:efficiency_score] || 0) }
  end
  
  def bust_candidates
    # Players with high volume but poor efficiency
    all_stats = top_performers(200)
    
    return [] if all_stats.empty?
    
    all_stats.select do |player_data|
      efficiency_score = player_data[:efficiency_score] || 0
      fantasy_points = player_data[:fantasy_points] || 0
      
      fantasy_points > position_volume_threshold &&
      efficiency_score < position_efficiency_threshold
    end.sort_by { |p| p[:efficiency_score] || 0 }
  end
  
  def position_scarcity_analysis
    performers = top_performers(100)
    
    return {} if performers.empty?
    
    tiers = {
      elite: performers[0..4],
      tier1: performers[5..11],
      tier2: performers[12..23],
      tier3: performers[24..35],
      tier4: performers[36..49]
    }
    
    # Calculate drop-off between tiers
    tier_analysis = {}
    tiers.each_cons(2) do |(tier_name, tier_players), (next_tier_name, next_tier_players)|
      if tier_players&.any? && next_tier_players&.any?
        current_points = tier_players.map { |p| p[:fantasy_points] || 0 }
        next_points = next_tier_players.map { |p| p[:fantasy_points] || 0 }
        
        avg_current = current_points.sum.to_f / current_points.size
        avg_next = next_points.sum.to_f / next_points.size
        
        # Avoid division by zero
        drop_off = avg_current > 0 ? ((avg_current - avg_next) / avg_current * 100).round(1) : 0
        
        tier_analysis["#{tier_name}_to_#{next_tier_name}"] = {
          current_avg: avg_current.round(1),
          next_avg: avg_next.round(1),
          drop_off_percent: drop_off
        }
      end
    end
    
    tier_analysis
  end
  
  private
  
  def fantasy_points_query
    case scoring_type
    when :standard
      'fantasy_points_std DESC NULLS LAST'
    when :half_ppr
      'fantasy_points_half_ppr DESC NULLS LAST'
    else
      'fantasy_points_ppr DESC NULLS LAST'
    end
  end
  
  def position_efficiency_threshold
    case position
    when 'QB' then 18.0
    when 'RB' then 12.0
    when 'WR' then 11.0
    when 'TE' then 8.0
    else 10.0
    end
  end
  
  def position_volume_threshold
    case position
    when 'QB' then 250.0
    when 'RB' then 150.0
    when 'WR' then 120.0
    when 'TE' then 80.0
    else 100.0
    end
  end

  def get_fantasy_points(stats)
    return 0 unless stats

    # Try database column first
    fantasy_points = case scoring_type
    when :standard
      stats.respond_to?(:fantasy_points_std) ? stats.fantasy_points_std : nil
    when :half_ppr
      stats.respond_to?(:fantasy_points_half_ppr) ? stats.fantasy_points_half_ppr : nil
    else
      stats.respond_to?(:fantasy_points_ppr) ? stats.fantasy_points_ppr : nil
    end

    # If database column is nil or missing, calculate on the fly
    if fantasy_points.nil? && stats.respond_to?(:calculate_fantasy_points)
      begin
        fantasy_points = stats.calculate_fantasy_points(scoring_type)
      rescue => e
        Rails.logger.error "Error calculating fantasy points for #{stats.player&.name}: #{e.message}"
        fantasy_points = 0
      end
    end

    fantasy_points || 0
  end
end
