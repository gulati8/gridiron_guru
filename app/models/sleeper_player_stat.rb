class SleeperPlayerStat < ApplicationRecord
  belongs_to :sleeper_player, 
             foreign_key: :sleeper_player_id, 
             primary_key: :sleeper_player_id,
             optional: true

  validates :sleeper_player_id, presence: true
  validates :player_name, presence: true
  validates :position, presence: true, inclusion: { in: %w[QB RB WR TE K DEF DB DL LB] }
  validates :season, presence: true, inclusion: { in: (2009..Date.current.year + 1).to_a }
  validates :week, presence: true, inclusion: { in: (0..18).to_a }
  validates :season_type, presence: true, inclusion: { in: %w[regular post] }
  
  validates :sleeper_player_id, uniqueness: { scope: [:season, :week, :season_type] }

  # JSON columns don't need serialize directive in PostgreSQL

  scope :by_season, ->(season) { where(season: season) }
  scope :by_week, ->(week) { where(week: week) }
  scope :by_position, ->(position) { where(position: position) }
  scope :by_season_type, ->(type) { where(season_type: type) }
  scope :regular_season, -> { where(season_type: 'regular') }
  scope :playoffs, -> { where(season_type: 'post') }
  scope :top_performers, ->(limit = 50) { order(fantasy_points_ppr: :desc).limit(limit) }

  # Fantasy football relevant positions
  SKILL_POSITIONS = %w[QB RB WR TE].freeze
  DEFENSE_POSITIONS = %w[K DEF DB DL LB].freeze

  def skill_position?
    SKILL_POSITIONS.include?(position)
  end

  def defense_position?
    DEFENSE_POSITIONS.include?(position)
  end

  def weekly_rank_by_position
    # Calculate rank among players at same position for this week
    self.class.where(position: position, season: season, week: week, season_type: season_type)
             .where('fantasy_points_ppr > ?', fantasy_points_ppr || 0)
             .count + 1
  end

  def season_total_points(scoring_type = :ppr)
    self.class.where(sleeper_player_id: sleeper_player_id, season: season, season_type: 'regular')
             .sum("fantasy_points_#{scoring_type}")
  end

  def games_played_in_season
    self.class.where(sleeper_player_id: sleeper_player_id, season: season, season_type: 'regular')
             .where('fantasy_points_ppr > 0')
             .count
  end

  def average_points_per_game(scoring_type = :ppr)
    total = season_total_points(scoring_type)
    games = games_played_in_season
    return 0.0 if games.zero?
    
    (total / games).round(2)
  end
end
