class SleeperLeague < ApplicationRecord
  has_many :sleeper_rosters, dependent: :destroy
  has_many :sleeper_matchups, dependent: :destroy
  has_many :sleeper_drafts, dependent: :destroy
  has_many :sleeper_transactions, dependent: :destroy
  has_many :sleeper_users, through: :sleeper_rosters

  validates :sleeper_league_id, presence: true, uniqueness: true
  validates :name, presence: true
  validates :season, presence: true, inclusion: { in: (2017..Date.current.year).to_a }
  validates :total_rosters, presence: true, numericality: { greater_than: 0 }
  validates :status, presence: true

  scope :by_season, ->(season) { where(season: season) }
  scope :active, -> { where(status: 'in_season') }
  scope :completed, -> { where(status: 'complete') }
end
