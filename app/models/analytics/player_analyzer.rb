class Analytics::PlayerAnalyzer
  attr_reader :player, :season
  
  def initialize(player, season = Date.current.year)
    @player = player
    @season = season
  end
  
  def efficiency_metrics
    stats = player.season_stats(season)
    return {} unless stats
    
    case player.position
    when 'QB'
      qb_efficiency_metrics(stats)
    when 'RB'
      rb_efficiency_metrics(stats)
    when 'WR', 'TE'
      receiver_efficiency_metrics(stats)
    else
      {}
    end
  end
  
  def fantasy_value_score
    stats = player.season_stats(season)
    return 0 unless stats
    
    # Get fantasy points, calculate if not stored in database
    points = if stats.respond_to?(:fantasy_points_ppr) && stats.fantasy_points_ppr
      stats.fantasy_points_ppr
    elsif stats.respond_to?(:calculate_fantasy_points)
      stats.calculate_fantasy_points(:ppr)
    else
      0
    end
    
    return 0 if points.nil? || points == 0
    
    # Normalize by games played
    games = stats.games > 0 ? stats.games : 1
    points_per_game = points.to_f / games
    
    # Position-based scoring adjustment
    position_multiplier = case player.position
    when 'QB' then 0.8  # QBs typically score more
    when 'RB' then 1.0
    when 'WR' then 1.1
    when 'TE' then 1.3  # TEs typically score less
    else 1.0
    end
    
    (points_per_game * position_multiplier).round(2)
  end
  
  def consistency_score
    # This would require weekly data - placeholder for now
    # Would calculate standard deviation of weekly performances
    0.0
  end
  
  def injury_risk_factors
    stats = player.season_stats(season)
    return {} unless stats
    
    risk_factors = {}
    
    # Age factor
    age = stats.respond_to?(:age) ? stats.age : player.age_in_season(season)
    if age
      risk_factors[:age_risk] = case age
      when 0..25 then 'Low'
      when 26..29 then 'Medium'
      when 30..32 then 'High'
      else 'Very High'
      end
    end
    
    # Usage factor (high touch players more injury prone)
    if stats.respond_to?(:touches) && stats.touches > 300
      risk_factors[:usage_risk] = 'High'
    elsif stats.respond_to?(:touches) && stats.touches > 200
      risk_factors[:usage_risk] = 'Medium'
    else
      risk_factors[:usage_risk] = 'Low'
    end
    
    risk_factors
  end
  
  private
  
  def qb_efficiency_metrics(stats)
    {
      completion_percentage: stats.pass_efficiency,
      yards_per_attempt: stats.pass_yds_per_att,
      td_to_int_ratio: stats.pass_int > 0 ? (stats.pass_td.to_f / stats.pass_int).round(2) : stats.pass_td,
      pressure_rate: stats.pressure_rate,
      air_yards_per_attempt: stats.air_yards_per_attempt,
      fantasy_points_per_game: (stats.calculate_fantasy_points / [stats.games, 1].max).round(2)
    }
  end
  
  def rb_efficiency_metrics(stats)
    {
      yards_per_carry: stats.rush_yds_per_att,
      yards_per_target: stats.rec_yds_per_tgt,
      target_share: stats.target_share,
      yards_before_contact: stats.yards_before_contact_per_rush,
      broken_tackle_rate: stats.broken_tackle_rate,
      receiving_efficiency: stats.receiving_efficiency,
      fantasy_points_per_touch: stats.touches > 0 ? (stats.calculate_fantasy_points / stats.touches).round(2) : 0
    }
  end
  
  def receiver_efficiency_metrics(stats)
    {
      catch_percentage: stats.catch_pct,
      yards_per_target: stats.rec_yds_per_tgt,
      yards_per_reception: stats.rec_yds_per_rec,
      target_share: stats.target_share,
      average_depth_of_target: stats.average_depth_of_target,
      yards_after_catch: stats.yards_after_catch_per_reception,
      drop_rate: stats.respond_to?(:drop_rate) ? stats.drop_rate : 0,
      fantasy_points_per_target: stats.targets > 0 ? (stats.calculate_fantasy_points / stats.targets).round(2) : 0
    }
  end
end
