class SleeperMatchup < ApplicationRecord
  belongs_to :sleeper_league
  belongs_to :sleeper_roster

  validates :week, presence: true, inclusion: { in: (1..18).to_a }
  validates :season, presence: true, inclusion: { in: (2017..Date.current.year).to_a }
  validates :points, presence: true, numericality: { greater_than_or_equal_to: 0 }

  scope :by_season, ->(season) { where(season: season) }
  scope :by_week, ->(week) { where(week: week) }
  scope :regular_season, -> { where(week: 1..14) }
  scope :playoffs, -> { where(week: 15..18) }

  def opponent_roster
    return nil unless opponent_roster_id
    sleeper_league.sleeper_rosters.find_by(sleeper_roster_id: opponent_roster_id)
  end

  def won?
    opponent_points && points > opponent_points
  end

  def lost?
    opponent_points && points < opponent_points
  end

  def tied?
    opponent_points && points == opponent_points
  end
end
