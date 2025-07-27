class QbWeeklyStat < ApplicationRecord
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
  
  before_save :calculate_and_store_fantasy_points
  
  def calculate_fantasy_points(scoring = :ppr)
    points = 0
    
    # Passing (1 point per 25 yards, 4 points per TD, -2 per INT)
    points += (pass_yds / 25.0) * 1
    points += pass_td * 4
    points -= pass_int * 2
    
    # Rushing (1 point per 10 yards, 6 points per TD)
    points += (rush_yds / 10.0) * 1
    points += rush_td * 6
    
    # Fumbles
    points -= fumbles * 2
    
    points.round(2)
  end
  
  def total_td
    pass_td + rush_td
  end
  
  def completion_percentage
    return 0 if pass_att == 0
    ((pass_cmp.to_f / pass_att) * 100).round(1)
  end
  
  def yards_per_attempt
    return 0 if pass_att == 0
    (pass_yds.to_f / pass_att).round(1)
  end
  
  private
  
  def calculate_and_store_fantasy_points
    self.fantasy_points_std = calculate_fantasy_points(:standard)
    self.fantasy_points_half_ppr = calculate_fantasy_points(:half_ppr)
    self.fantasy_points_ppr = calculate_fantasy_points(:ppr)
  end
end