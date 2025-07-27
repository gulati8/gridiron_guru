class Player < ApplicationRecord
  has_many :qb_season_stats, dependent: :destroy
  has_many :rb_season_stats, dependent: :destroy
  has_many :wr_season_stats, dependent: :destroy
  has_many :te_season_stats, dependent: :destroy
  
  has_many :qb_weekly_stats, dependent: :destroy
  has_many :rb_weekly_stats, dependent: :destroy
  has_many :wr_weekly_stats, dependent: :destroy
  has_many :te_weekly_stats, dependent: :destroy
  
  validates :name, presence: true
  validates :position, presence: true, inclusion: { in: %w[QB RB WR TE K DST] }
  validates :pro_football_reference_url, presence: true, uniqueness: true, format: { with: URI::DEFAULT_PARSER.make_regexp }

  scope :active, -> { where(active: true) }
  scope :by_position, ->(pos) { where(position: pos) }
  scope :quarterbacks, -> { where(position: 'QB') }
  scope :running_backs, -> { where(position: 'RB') }
  scope :wide_receivers, -> { where(position: 'WR') }
  scope :tight_ends, -> { where(position: 'TE') }

  def season_stats(season)
    case position
    when 'QB'
      qb_season_stats.find_by(season: season)
    when 'RB'
      rb_season_stats.find_by(season: season)
    when 'WR'
      wr_season_stats.find_by(season: season)
    when 'TE'
      te_season_stats.find_by(season: season)
    end
  end

  def fantasy_points(season, scoring: :ppr)
    stats = season_stats(season)
    return 0 unless stats

    stats.calculate_fantasy_points(scoring)
  end

  def age_in_season(season)
    return nil unless birth_date

    # Approximate age during season (most of season is in fall)
    season - birth_date.year
  end

  def experience_in_season(season)
    return nil unless years_exp

    # Assuming years_exp is as of current year, calculate for given season
    current_year = Date.current.year
    years_exp + (season - current_year)
  end

  def weekly_stats(season)
    case position
    when 'QB'
      qb_weekly_stats.by_season(season).chronological
    when 'RB'
      rb_weekly_stats.by_season(season).chronological
    when 'WR'
      wr_weekly_stats.by_season(season).chronological
    when 'TE'
      te_weekly_stats.by_season(season).chronological
    else
      []
    end
  end

  def weekly_stat(season, week)
    case position
    when 'QB'
      qb_weekly_stats.find_by(season: season, week: week)
    when 'RB'
      rb_weekly_stats.find_by(season: season, week: week)
    when 'WR'
      wr_weekly_stats.find_by(season: season, week: week)
    when 'TE'
      te_weekly_stats.find_by(season: season, week: week)
    end
  end
end
