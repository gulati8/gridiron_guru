class SleeperDraft < ApplicationRecord
  belongs_to :sleeper_league
  has_many :sleeper_draft_picks, dependent: :destroy

  validates :sleeper_draft_id, presence: true, uniqueness: true
  validates :draft_type, presence: true
  validates :status, presence: true

  scope :completed, -> { where(status: 'complete') }
  scope :in_progress, -> { where(status: 'drafting') }

  def total_picks
    sleeper_draft_picks.count
  end

  def rounds
    sleeper_draft_picks.maximum(:round) || 0
  end
end
