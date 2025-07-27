class TeSeasonStat < ApplicationRecord
  belongs_to :player
  
  validates :season, presence: true,
            numericality: { greater_than: 1999, less_than_or_equal_to: Date.current.year + 1 }
  validates :team_abbr, presence: true
  validates :player_id, uniqueness: { scope: :season }
  
  scope :by_season, ->(season) { where(season: season) }
  scope :by_team, ->(team) { where(team_abbr: team) }
  scope :min_targets, ->(targets) { where('targets >= ?', targets) }
  
  before_save :calculate_derived_stats
  
  def calculate_fantasy_points(scoring = :ppr)
    points = 0
    
    # Receiving (1 point per 10 yards, 6 points per TD)
    points += (rec_yds / 10.0) * 1
    points += rec_td * 6
    
    # PPR bonus
    case scoring
    when :ppr
      points += rec * 1
    when :half_ppr
      points += rec * 0.5
    end
    
    # Rushing (very rare)
    points += (rush_yds / 10.0) * 1
    points += rush_td * 6
    
    # Fumbles
    points -= fumbles * 2
    
    points.round(2)
  end
  
  def target_share
    return 0 unless target_metrics['target_share']
    target_metrics['target_share'].to_f
  end
  
  def average_depth_of_target
    return 0 unless receiving_advanced['rec_adot']
    receiving_advanced['rec_adot'].to_f
  end
  
  def yards_after_catch_per_reception
    return 0 unless receiving_advanced['rec_yac']
    return 0 if rec == 0
    
    (receiving_advanced['rec_yac'].to_f / rec).round(2)
  end
  
  def red_zone_usage
    return 0 unless target_metrics['red_zone_targets']
    target_metrics['red_zone_targets'].to_f
  end
  
  def route_participation_rate
    return 0 unless blocking_metrics['route_participation']
    blocking_metrics['route_participation'].to_f
  end
  
  private
  
  def calculate_derived_stats
    self.total_td = rec_td + rush_td
    self.touches = rec + rush_att
    self.yds_from_scrimmage = rec_yds + rush_yds
    self.yds_per_touch = touches > 0 ? (yds_from_scrimmage.to_f / touches).round(2) : 0
  end
end
