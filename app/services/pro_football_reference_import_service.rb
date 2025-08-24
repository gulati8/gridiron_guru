class ProFootballReferenceImportService
  include ActiveModel::Model
  
  attr_accessor :season, :stat_type
  
  validates :stat_type, presence: true, inclusion: { in: %w[passing rushing receiving] }
  validates :season, presence: true, inclusion: { in: (2020..2025).to_a }
  
  def initialize(stat_type:, season:)
    @stat_type  = stat_type
    @season     = season.to_i  # Ensure season is an integer
    @custom_errors = []
    
    Rails.logger.info "ProFootballReferenceImportService initialized with stat_type: #{@stat_type}, season: #{@season} (#{@season.class})"
  end
  
  def call
    unless valid?
      Rails.logger.error "Pro Football Reference Import validation failed: #{errors.full_messages.join(', ')}"
      @custom_errors.concat(errors.full_messages)
      return false
    end
    
    begin
      data = ProFootballReferenceScraperService.new(stat_type: stat_type, season: season).scrape_stats
      import_player_data(data)
      
      Rails.logger.info "Successfully imported #{stat_type} data for #{season}"
      true
    rescue => e
      Rails.logger.error "Pro Football Reference Import failed: #{e.message}"
      Rails.logger.error e.backtrace.first(5).join("\n") if e.backtrace
      @custom_errors << e.message
      false
    end
  end
  
  
  def custom_errors
    @custom_errors
  end
  
  private

  def import_player_data(data)
    # Handle both single player object and array of players
    players_data = data.is_a?(Array) ? data : [data]
    
    players_data.each do |player_data|
      begin
        p "Importing #{season} data for #{player_data[:name]}"
        import_single_player(player_data)
      rescue => e
        p "Import failed: #{e.message}"
      end
    end
  end
  
  def import_single_player(player_data)
    # Create or find player
    player = find_or_create_player(player_data)
    
    # Import season stats based on position from the scraped data
    position = player_data[:position] || player.position
    case position
    when "QB"
      import_qb_stats(player, player_data)
    when "RB"
      import_rb_stats(player, player_data)
    when "WR"
      import_wr_stats(player, player_data)
    when "TE"
      import_te_stats(player, player_data)
    end
  end
  
  def find_or_create_player(player_data)
    pfr_url = player_data[:url]
    
    # Try to find by PFR URL first
    player = Player.find_by(pro_football_reference_url: pfr_url)
    
    # If not found, try by name (regardless of position, since positions can change)
    player ||= Player.find_by(name: player_data[:name])
    
    # Create new player if not found
    player ||= Player.new
    
    # Map scraped position to primary position for multi-position players
    mapped_position = map_player_position(player_data[:name], player_data[:position])
    
    # Update player attributes
    player.assign_attributes(
      name:                       player_data[:name],
      position:                   mapped_position,
      pro_football_reference_url: pfr_url,
      active:                     true
    )
    
    player.save!
    player
  end
  
  def import_qb_stats(player, player_data)
    season_stats = player_data[:season_stats] || {}
    advanced_stats = player_data[:advanced_stats] || {}
    
    qb_stats = player.qb_season_stats.find_or_initialize_by(season: season)
    
    qb_stats.assign_attributes(
      team_abbr: season_stats[:team_name_abbr],
      age: season_stats[:age],
      games: season_stats[:games] || 0,
      games_started: season_stats[:games_started] || 0,
      qb_record: season_stats[:qb_rec],
      
      # Core passing stats
      pass_cmp: season_stats[:pass_cmp] || 0,
      pass_att: season_stats[:pass_att] || 0,
      pass_yds: season_stats[:pass_yds] || 0,
      pass_td: season_stats[:pass_td] || 0,
      pass_int: season_stats[:pass_int] || 0,
      pass_cmp_pct: safe_to_decimal(season_stats[:pass_cmp_pct]),
      pass_rating: safe_to_decimal(season_stats[:pass_rating]),
      
      # Rushing stats
      rush_att: season_stats[:rush_att] || 0,
      rush_yds: season_stats[:rush_yds] || 0,
      rush_td: season_stats[:rush_td] || 0,
      fumbles: season_stats[:fumbles] || 0,
      
      # Efficiency metrics
      pass_yds_per_att: safe_to_decimal(season_stats[:pass_yds_per_att]),
      qbr: safe_to_decimal(season_stats[:qbr]),
      pass_sacked: season_stats[:pass_sacked] || 0,
      pass_sacked_yds: season_stats[:pass_sacked_yds] || 0,
      pass_sacked_pct: safe_to_decimal(season_stats[:pass_sacked_pct]),
      
      # JSON fields
      advanced_passing: extract_advanced_passing(advanced_stats),
      pressure_stats: extract_pressure_stats(advanced_stats),
      situational_stats: extract_situational_stats(advanced_stats),
      raw_season_data: season_stats,
      raw_advanced_data: advanced_stats
    )
    
    qb_stats.save!
  end
  
  def import_rb_stats(player, player_data)
    season_stats = player_data[:season_stats] || {}
    advanced_stats = player_data[:advanced_stats] || {}
    
    rb_stats = player.rb_season_stats.find_or_initialize_by(season: season)
    
    rb_stats.assign_attributes(
      team_abbr: season_stats[:team_name_abbr],
      age: season_stats[:age],
      games: season_stats[:games] || 0,
      games_started: season_stats[:games_started] || 0,
      
      # Rushing stats
      rush_att: season_stats[:rush_att] || 0,
      rush_yds: season_stats[:rush_yds] || 0,
      rush_td: season_stats[:rush_td] || 0,
      rush_yds_per_att: safe_to_decimal(season_stats[:rush_yds_per_att]),
      rush_long: season_stats[:rush_long] || 0,
      
      # Receiving stats
      targets: season_stats[:targets] || 0,
      rec: season_stats[:rec] || 0,
      rec_yds: season_stats[:rec_yds] || 0,
      rec_td: season_stats[:rec_td] || 0,
      catch_pct: safe_to_decimal(season_stats[:catch_pct]),
      rec_yds_per_tgt: safe_to_decimal(season_stats[:rec_yds_per_tgt]),
      
      # Other stats
      fumbles: season_stats[:fumbles] || 0,
      rush_success_rate: safe_to_decimal(season_stats[:rush_success]),
      rec_success_rate: safe_to_decimal(season_stats[:rec_success]),
      
      # JSON fields
      rushing_advanced: extract_rushing_advanced(advanced_stats),
      receiving_advanced: extract_receiving_advanced(advanced_stats),
      efficiency_metrics: extract_efficiency_metrics(advanced_stats),
      raw_season_data: season_stats,
      raw_advanced_data: advanced_stats
    )
    
    rb_stats.save!
  end
  
  def import_wr_stats(player, player_data)
    season_stats = player_data[:season_stats] || {}
    advanced_stats = player_data[:advanced_stats] || {}
    
    wr_stats = player.wr_season_stats.find_or_initialize_by(season: season)
    
    wr_stats.assign_attributes(
      team_abbr: season_stats[:team_name_abbr],
      age: season_stats[:age],
      games: season_stats[:games] || 0,
      games_started: season_stats[:games_started] || 0,
      
      # Receiving stats
      targets: season_stats[:targets] || 0,
      rec: season_stats[:rec] || 0,
      rec_yds: season_stats[:rec_yds] || 0,
      rec_td: season_stats[:rec_td] || 0,
      catch_pct: safe_to_decimal(season_stats[:catch_pct]),
      rec_yds_per_rec: safe_to_decimal(season_stats[:rec_yds_per_rec]),
      rec_yds_per_tgt: safe_to_decimal(season_stats[:rec_yds_per_tgt]),
      rec_long: season_stats[:rec_long] || 0,
      
      # Rushing stats (some WRs get carries)
      rush_att: season_stats[:rush_att] || 0,
      rush_yds: season_stats[:rush_yds] || 0,
      rush_td: season_stats[:rush_td] || 0,
      rush_yds_per_att: safe_to_decimal(season_stats[:rush_yds_per_att]),
      
      # Other stats
      fumbles: season_stats[:fumbles] || 0,
      rec_success_rate: safe_to_decimal(season_stats[:rec_success]),
      
      # JSON fields
      receiving_advanced: extract_receiving_advanced(advanced_stats),
      target_metrics: extract_target_metrics(advanced_stats),
      efficiency_metrics: extract_efficiency_metrics(advanced_stats),
      raw_season_data: season_stats,
      raw_advanced_data: advanced_stats
    )
    
    wr_stats.save!
  end
  
  def import_te_stats(player, player_data)
    season_stats = player_data[:season_stats] || {}
    advanced_stats = player_data[:advanced_stats] || {}
    
    te_stats = player.te_season_stats.find_or_initialize_by(season: season)
    
    te_stats.assign_attributes(
      team_abbr: season_stats[:team_name_abbr],
      age: season_stats[:age],
      games: season_stats[:games] || 0,
      games_started: season_stats[:games_started] || 0,
      
      # Receiving stats
      targets: season_stats[:targets] || 0,
      rec: season_stats[:rec] || 0,
      rec_yds: season_stats[:rec_yds] || 0,
      rec_td: season_stats[:rec_td] || 0,
      catch_pct: safe_to_decimal(season_stats[:catch_pct]),
      rec_yds_per_rec: safe_to_decimal(season_stats[:rec_yds_per_rec]),
      rec_yds_per_tgt: safe_to_decimal(season_stats[:rec_yds_per_tgt]),
      rec_long: season_stats[:rec_long] || 0,
      
      # Rushing (rare for TEs)
      rush_att: season_stats[:rush_att] || 0,
      rush_yds: season_stats[:rush_yds] || 0,
      rush_td: season_stats[:rush_td] || 0,
      
      # Other stats
      fumbles: season_stats[:fumbles] || 0,
      rec_success_rate: safe_to_decimal(season_stats[:rec_success]),
      
      # JSON fields
      receiving_advanced: extract_receiving_advanced(advanced_stats),
      target_metrics: extract_target_metrics(advanced_stats),
      blocking_metrics: extract_blocking_metrics(advanced_stats),
      raw_season_data: season_stats,
      raw_advanced_data: advanced_stats
    )
    
    te_stats.save!
  end
  
  # Helper methods for extracting specific JSON data
  def extract_advanced_passing(advanced_stats)
    {
      pass_air_yds: advanced_stats[:pass_air_yds],
      pass_air_yds_per_att: advanced_stats[:pass_air_yds_per_att],
      pass_yac: advanced_stats[:pass_yac],
      pass_yac_per_cmp: advanced_stats[:pass_yac_per_cmp],
      pass_on_target_pct: advanced_stats[:pass_on_target_pct],
      pass_poor_throw_pct: advanced_stats[:pass_poor_throw_pct]
    }.compact
  end
  
  def extract_pressure_stats(advanced_stats)
    {
      pass_pressured_pct: advanced_stats[:pass_pressured_pct],
      pass_blitzed: advanced_stats[:pass_blitzed],
      pass_hurried: advanced_stats[:pass_hurried],
      pass_hits: advanced_stats[:pass_hits],
      pocket_time: advanced_stats[:pocket_time]
    }.compact
  end
  
  def extract_situational_stats(advanced_stats)
    {
      pass_rpo: advanced_stats[:pass_rpo],
      pass_rpo_yds: advanced_stats[:pass_rpo_yds],
      pass_play_action: advanced_stats[:pass_play_action],
      pass_play_action_pass_yds: advanced_stats[:pass_play_action_pass_yds],
      rush_scrambles: advanced_stats[:rush_scrambles]
    }.compact
  end
  
  def extract_rushing_advanced(advanced_stats)
    {
      rush_yds_before_contact: advanced_stats[:rush_yds_before_contact],
      rush_yds_bc_per_rush: advanced_stats[:rush_yds_bc_per_rush],
      rush_yac: advanced_stats[:rush_yac],
      rush_yac_per_rush: advanced_stats[:rush_yac_per_rush],
      rush_broken_tackles: advanced_stats[:rush_broken_tackles],
      rush_broken_tackles_per_rush: advanced_stats[:rush_broken_tackles_per_rush]
    }.compact
  end
  
  def extract_receiving_advanced(advanced_stats)
    {
      rec_air_yds: advanced_stats[:rec_air_yds],
      rec_air_yds_per_rec: advanced_stats[:rec_air_yds_per_rec],
      rec_yac: advanced_stats[:rec_yac],
      rec_yac_per_rec: advanced_stats[:rec_yac_per_rec],
      rec_adot: advanced_stats[:rec_adot],
      rec_drops: advanced_stats[:rec_drops],
      rec_drop_pct: advanced_stats[:rec_drop_pct],
      rec_broken_tackles: advanced_stats[:rec_broken_tackles]
    }.compact
  end
  
  def extract_target_metrics(advanced_stats)
    {
      target_share: calculate_target_share(advanced_stats),
      red_zone_targets: advanced_stats[:red_zone_targets]
    }.compact
  end
  
  def extract_efficiency_metrics(advanced_stats)
    {
      success_rate: advanced_stats[:success_rate],
      contested_catches: advanced_stats[:contested_catches]
    }.compact
  end
  
  def extract_blocking_metrics(advanced_stats)
    {
      route_participation: advanced_stats[:route_participation],
      snap_share: advanced_stats[:snap_share]
    }.compact
  end
  
  def calculate_target_share(advanced_stats)
    # This would need team-level data to calculate properly
    # For now, just store if it"s available in the data
    advanced_stats[:target_share]
  end
  
  def map_player_position(player_name, scraped_position)
    # Handle special cases for multi-position players
    case player_name
    when 'Taysom Hill'
      'QB'  # He plays multiple positions but QB is where he gets most stats
    when 'Cordarrelle Patterson'
      'RB'  # Primarily RB despite WR background
    else
      scraped_position
    end
  end
  
  def safe_to_decimal(value)
    return nil if value.nil? || value == ""
    
    # Remove percentage signs and convert to decimal
    clean_value = value.to_s.gsub("%", "")
    Float(clean_value)
  rescue ArgumentError
    nil
  end
end
  
