class SleeperPlayer < ApplicationRecord
  validates :sleeper_player_id, presence: true, uniqueness: true
  validates :full_name, presence: true
  
  has_many :sleeper_player_stats, 
           foreign_key: :sleeper_player_id, 
           primary_key: :sleeper_player_id,
           dependent: :destroy
           
  has_many :sleeper_draft_picks,
           foreign_key: :sleeper_player_id,
           primary_key: :sleeper_player_id,
           dependent: :destroy

  scope :active, -> { where(status: 'Active') }
  scope :by_position, ->(position) { where(position: position) }
  scope :by_team, ->(team) { where(team: team) }
  scope :search_by_name, ->(name) { where('full_name ILIKE ?', "%#{name}%") }

  def display_name
    full_name.presence || "#{first_name} #{last_name}".strip
  end

  def position_group
    case position
    when 'QB' then 'Quarterback'
    when 'RB', 'FB' then 'Running Back'
    when 'WR' then 'Wide Receiver'
    when 'TE' then 'Tight End'
    when 'K' then 'Kicker'
    when 'DEF' then 'Defense'
    when 'DB', 'CB', 'S' then 'Defensive Back'
    when 'LB', 'ILB', 'OLB' then 'Linebacker'
    when 'DL', 'DE', 'DT', 'NT' then 'Defensive Line'
    when 'OL', 'OT', 'OG', 'C' then 'Offensive Line'
    else position
    end
  end

  def fantasy_relevant?
    %w[QB RB WR TE K DEF].include?(position)
  end

  def rookie?
    years_exp == 0
  end

  def veteran?
    years_exp && years_exp >= 5
  end

  def current_season_stats(season = Date.current.year)
    sleeper_player_stats.where(season: season, season_type: 'regular')
  end

  def career_fantasy_points(scoring_type = :ppr)
    sleeper_player_stats.where(season_type: 'regular')
                       .sum("fantasy_points_#{scoring_type}")
  end

  def best_season(scoring_type = :ppr)
    sleeper_player_stats.where(season_type: 'regular')
                       .group(:season)
                       .sum("fantasy_points_#{scoring_type}")
                       .max_by { |season, points| points }
  end

  def self.import_from_sleeper_api(use_cache: false)
    api_service = SleeperApiService.new
    players_data = api_service.get_players_nfl(use_cache: use_cache)
    
    return 0 unless players_data&.any?
    
    imported_count = 0
    total_players = players_data.size
    
    Rails.logger.info "Starting import of #{total_players} players from Sleeper API"
    
    players_data.each_with_index do |(player_id, player_data), index|
      begin
        import_player(player_id, player_data)
        imported_count += 1
        
        # Log progress every 1000 players
        if (index + 1) % 1000 == 0
          Rails.logger.info "Imported #{index + 1}/#{total_players} players"
        end
      rescue => e
        Rails.logger.error "Failed to import player #{player_id}: #{e.message}"
      end
    end
    
    Rails.logger.info "Successfully imported #{imported_count}/#{total_players} players"
    imported_count
  end
  
  private
  
  def self.import_player(player_id, player_data)
    player = find_or_initialize_by(sleeper_player_id: player_id)
    
    player.assign_attributes(
      first_name: player_data['first_name'],
      last_name: player_data['last_name'],
      full_name: player_data['full_name'],
      position: player_data['position'],
      team: player_data['team'],
      status: player_data['status'],
      years_exp: player_data['years_exp'],
      birth_date: parse_birth_date(player_data['birth_date']),
      height: player_data['height'],
      weight: player_data['weight'],
      college: player_data['college'],
      player_data: player_data
    )
    
    player.save!
    player
  end
  
  def self.parse_birth_date(birth_date_str)
    return nil unless birth_date_str
    Date.parse(birth_date_str)
  rescue Date::Error
    nil
  end
end
