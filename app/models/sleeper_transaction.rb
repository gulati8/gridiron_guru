class SleeperTransaction < ApplicationRecord
  belongs_to :sleeper_league
  belongs_to :sleeper_roster, optional: true

  validates :sleeper_transaction_id, presence: true, uniqueness: true
  validates :transaction_type, presence: true
  validates :status, presence: true
  validates :week, presence: true, inclusion: { in: (0..18).to_a }
  validates :season, presence: true, inclusion: { in: (2017..Date.current.year).to_a }

  scope :by_season, ->(season) { where(season: season) }
  scope :by_week, ->(week) { where(week: week) }
  scope :by_type, ->(type) { where(transaction_type: type) }
  scope :completed, -> { where(status: 'complete') }

  TRANSACTION_TYPES = %w[waiver free_agent trade].freeze

  def waiver_claim?
    transaction_type == 'waiver'
  end

  def free_agent_pickup?
    transaction_type == 'free_agent'
  end

  def trade?
    transaction_type == 'trade'
  end
end
