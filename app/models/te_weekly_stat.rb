class TeWeeklyStat < ApplicationRecord
  belongs_to :player
  
  validates :season, presence: true,
            numericality: { greater_than: 1999, less_than_or_equal_to: Date.current.year + 1 }
  validates :week, presence: true,
            numericality: { greater_than: 0, less_than_or_equal_to: 18 }
  validates :team_abbr, presence: true
  validates :player_id, uniqueness: { scope: [:season, :week] }
  
  scope :by_season, ->(season) { where(season: season) }
  scope :by_week, ->(week) { where(week: week) }
  scope :by_team, ->(team) { where(team_abbr: team) }
  scope :by_player, ->(player_id) { where(player_id: player_id) }
  scope :chronological, -> { order(:week) }
  
  before_save :calculate_derived_stats, :calculate_and_store_fantasy_points
  
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
    
    # Rushing (rare but happens)
    points += (rush_yds / 10.0) * 1
    points += rush_td * 6
    
    # Fumbles
    points -= fumbles * 2
    
    points.round(2)
  end
  
  def total_td
    rec_td + rush_td
  end
  
  def total_touches
    rec + rush_att
  end
  
  def total_yards
    rec_yds + rush_yds
  end
  
  def catch_percentage
    return 0 if targets == 0
    ((rec.to_f / targets) * 100).round(1)
  end
  
  def yards_per_target
    return 0 if targets == 0
    (rec_yds.to_f / targets).round(1)
  end
  
  def yards_per_reception
    return 0 if rec == 0
    (rec_yds.to_f / rec).round(1)
  end
  
  private
  
  def calculate_derived_stats
    # These can be calculated from base stats
  end
  
  def calculate_and_store_fantasy_points
    self.fantasy_points_std = calculate_fantasy_points(:standard)
    self.fantasy_points_half_ppr = calculate_fantasy_points(:half_ppr)
    self.fantasy_points_ppr = calculate_fantasy_points(:ppr)
  end
end