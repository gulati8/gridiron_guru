class SleeperRoster < ApplicationRecord
  belongs_to :sleeper_league
  belongs_to :sleeper_user
  has_many :sleeper_matchups, dependent: :destroy
  has_many :sleeper_draft_picks, dependent: :destroy
  has_many :sleeper_transactions, dependent: :destroy

  validates :sleeper_roster_id, presence: true, uniqueness: { scope: :sleeper_league_id }
  validates :sleeper_league, presence: true
  validates :sleeper_user, presence: true

  serialize :players, coder: JSON

  def player_ids
    players&.map(&:to_s) || []
  end

  def total_games
    wins + losses + ties
  end

  def win_percentage
    return 0.0 if total_games.zero?
    (wins.to_f / total_games).round(3)
  end
end
