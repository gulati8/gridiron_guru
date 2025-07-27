class QbSeasonStat < ApplicationRecord
  belongs_to :player
  
  validates :season, presence: true, 
            numericality: { greater_than: 1999, less_than_or_equal_to: Date.current.year + 1 }
  validates :team_abbr, presence: true
  validates :player_id, uniqueness: { scope: :season }
  
  scope :by_season, ->(season) { where(season: season) }
  scope :by_team, ->(team) { where(team_abbr: team) }
  scope :min_attempts, ->(attempts) { where('pass_att >= ?', attempts) }
  
  before_save :calculate_and_store_fantasy_points

  def calculate_fantasy_points(scoring = :ppr)
    points = 0

    # Passing (typically 1 point per 25 yards, 4-6 points per TD)
    points += (pass_yds / 25.0) * 1
    points += pass_td * 4
    points -= pass_int * 2

    # Rushing (typically 1 point per 10 yards, 6 points per TD)
    points += (rush_yds / 10.0) * 1
    points += rush_td * 6

    # Fumbles
    points -= fumbles * 2

    points.round(2)
  end

  def pass_efficiency
    return 0 if pass_att == 0

    ((pass_cmp.to_f / pass_att) * 100).round(2)
  end

  def total_tds
    pass_td + rush_td
  end

  def total_yards
    pass_yds + rush_yds
  end

  def turnover_worthy_plays
    pass_int + fumbles
  end

  def pressure_rate
    return 0 unless pressure_stats['pass_pressured_pct']
    pressure_stats['pass_pressured_pct'].to_f
  end

  def air_yards_per_attempt
    return 0 unless advanced_passing['pass_air_yds']
    return 0 if pass_att == 0

    (advanced_passing['pass_air_yds'].to_f / pass_att).round(2)
  end

  private

  def calculate_and_store_fantasy_points
    self.fantasy_points_std = calculate_fantasy_points(:standard)
    self.fantasy_points_half_ppr = calculate_fantasy_points(:half_ppr)
    self.fantasy_points_ppr = calculate_fantasy_points(:ppr)
  end
end
