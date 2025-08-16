class SleeperDraftPick < ApplicationRecord
  belongs_to :sleeper_draft
  belongs_to :sleeper_roster
  belongs_to :sleeper_player, foreign_key: :sleeper_player_id, primary_key: :sleeper_player_id, optional: true

  validates :pick_no, presence: true, uniqueness: { scope: :sleeper_draft_id }
  validates :round, presence: true, numericality: { greater_than: 0 }
  validates :sleeper_player_id, presence: true

  scope :by_round, ->(round) { where(round: round) }
  scope :chronological, -> { order(:pick_no) }

  def pick_in_round
    sleeper_draft.sleeper_draft_picks.where(round: round).where('pick_no <= ?', pick_no).count
  end
end
