class SleeperUser < ApplicationRecord
  has_many :sleeper_rosters, dependent: :destroy
  has_many :sleeper_leagues, through: :sleeper_rosters

  validates :sleeper_user_id, presence: true, uniqueness: true
  validates :display_name, presence: true
end
