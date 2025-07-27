class RbSeasonStat < ApplicationRecord
  belongs_to :player
  
  validates :season, presence: true,
            numericality: { greater_than: 1999, less_than_or_equal_to: Date.current.year + 1 }
  validates :team_abbr, presence: true
  validates :player_id, uniqueness: { scope: :season }
  
  scope :by_season, ->(season) { where(season: season) }
  scope :by_team, ->(team) { where(team_abbr: team) }
  scope :min_touches, ->(touches) { where('touches >= ?', touches) }
  scope :min_targets, ->(targets) { where('targets >= ?', targets) }
  
  before_save :calculate_derived_stats
  
  def calculate_fantasy_points(scoring = :ppr)
    points = 0
    
    # Rushing (1 point per 10 yards, 6 points per TD)
    points += (rush_yds / 10.0) * 1
    points += rush_td * 6
    
    # Receiving
    points += (rec_yds / 10.0) * 1
    points += rec_td * 6
    
    # PPR bonus
    case scoring
    when :ppr
      points += rec * 1
    when :half_ppr
      points += rec * 0.5
    end
    
    # Fumbles
    points -= fumbles * 2
    
    points.round(2)
  end
  
  def target_share
    return 0 unless receiving_advanced['target_share']
    receiving_advanced['target_share'].to_f
  end
  
  def yards_before_contact_per_rush
    return 0 unless rushing_advanced['rush_yds_before_contact']
    return 0 if rush_att == 0
    
    (rushing_advanced['rush_yds_before_contact'].to_f / rush_att).round(2)
  end
  
  def yards_after_contact_per_rush
    return 0 unless rushing_advanced['rush_yac']
    return 0 if rush_att == 0
    
    (rushing_advanced['rush_yac'].to_f / rush_att).round(2)
  end
  
  def broken_tackle_rate
    return 0 unless rushing_advanced['rush_broken_tackles']
    return 0 if rush_att == 0
    
    (rushing_advanced['rush_broken_tackles'].to_f / rush_att * 100).round(2)
  end
  
  def receiving_efficiency
    return 0 if targets == 0
    
    (rec.to_f / targets * 100).round(2)
  end
  
  private
  
  def calculate_derived_stats
    self.total_td = rush_td + rec_td
    self.touches = rush_att + rec
    self.yds_from_scrimmage = rush_yds + rec_yds
    self.yds_per_touch = touches > 0 ? (yds_from_scrimmage.to_f / touches).round(2) : 0
  end

  def calculate_and_store_fantasy_points
    self.fantasy_points_std = calculate_fantasy_points(:standard)
    self.fantasy_points_half_ppr = calculate_fantasy_points(:half_ppr)
    self.fantasy_points_ppr = calculate_fantasy_points(:ppr)
  end
end
