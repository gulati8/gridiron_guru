class SleeperPlayerStatsImportService
  include ActiveModel::Model
  
  attr_accessor :api_service, :season, :week, :season_type
  
  def initialize(season:, week: nil, season_type: 'regular')
    @api_service = SleeperApiService.new
    @season = season
    @week = week
    @season_type = season_type
  end
  
  def import_week_stats
    return { success: false, error: 'Week is required for weekly import' } unless week
    
    positions = SleeperPlayerStat::SKILL_POSITIONS + SleeperPlayerStat::DEFENSE_POSITIONS
    
    begin
      stats_data = api_service.get_player_stats(season, week, season_type: season_type, positions: positions)
      
      if stats_data.nil? || stats_data.empty?
        return { success: false, error: "No stats data found for #{season} week #{week}" }
      end
      
      imported_count = 0
      errors = []
      
      stats_data.each do |player_data|
        begin
          import_player_stat_from_array_response(player_data)
          imported_count += 1
        rescue => e
          player_id = player_data['player_id'] || 'unknown'
          errors << "Player #{player_id}: #{e.message}"
          Rails.logger.error "Failed to import player stat for #{player_data}: #{e.message}"
        end
      end
      
      Rails.logger.info "Imported #{imported_count} player stats for #{season} week #{week}"
      
      {
        success: true,
        imported_count: imported_count,
        errors: errors,
        message: "Successfully imported #{imported_count} player stats"
      }
      
    rescue SleeperApiError => e
      Rails.logger.error "API error during stats import: #{e.message}"
      { success: false, error: "API Error: #{e.message}" }
    rescue => e
      Rails.logger.error "Unexpected error during stats import: #{e.message}"
      { success: false, error: "Import failed: #{e.message}" }
    end
  end
  
  def import_season_stats
    positions = SleeperPlayerStat::SKILL_POSITIONS + SleeperPlayerStat::DEFENSE_POSITIONS
    
    begin
      stats_data = api_service.get_season_stats(season, season_type: season_type, positions: positions)
      
      if stats_data.nil? || stats_data.empty?
        return { success: false, error: "No season stats data found for #{season}" }
      end
      
      imported_count = 0
      errors = []
      
      stats_data.each do |player_data|
        begin
          # Season stats don't have week breakdown, so we'll store as week 0
          import_player_stat_from_array_response(player_data, week: 0)
          imported_count += 1
        rescue => e
          player_id = player_data['player_id'] || 'unknown'
          errors << "Player #{player_id}: #{e.message}"
          Rails.logger.error "Failed to import season stat for #{player_id}: #{e.message}"
        end
      end
      
      Rails.logger.info "Imported #{imported_count} season player stats for #{season}"
      
      {
        success: true,
        imported_count: imported_count,
        errors: errors,
        message: "Successfully imported #{imported_count} season stats"
      }
      
    rescue SleeperApiError => e
      Rails.logger.error "API error during season stats import: #{e.message}"
      { success: false, error: "API Error: #{e.message}" }
    rescue => e
      Rails.logger.error "Unexpected error during season stats import: #{e.message}"
      { success: false, error: "Import failed: #{e.message}" }
    end
  end
  
  def import_full_season(weeks: nil)
    # Import all weeks for a season
    weeks ||= (1..18).to_a # Regular season weeks
    total_imported = 0
    all_errors = []
    
    weeks.each do |week_num|
      Rails.logger.info "Importing week #{week_num} stats for #{season}"
      
      week_import = self.class.new(season: season, week: week_num, season_type: season_type)
      result = week_import.import_week_stats
      
      if result[:success]
        total_imported += result[:imported_count]
      else
        all_errors << "Week #{week_num}: #{result[:error]}"
      end
      
      # Add extra delay between weeks to be respectful of API
      sleep(1)
    end
    
    {
      success: all_errors.empty?,
      total_imported: total_imported,
      weeks_processed: weeks.size,
      errors: all_errors,
      message: "Imported #{total_imported} total player stats across #{weeks.size} weeks"
    }
  end
  
  private
  
  def import_player_stat_from_array_response(player_data, week: nil)
    # Extract player ID from the response structure
    player_id = player_data['player_id']
    return unless player_id.present?
    
    # Use the provided week or fall back to week from data or instance week
    stat_week = week || player_data['week'] || self.week
    
    # Extract player info from nested structure
    player_info = player_data['player'] || {}
    player_name = extract_player_name_from_response(player_info)
    position = extract_position_from_response(player_info, player_data)
    team = player_data['team']
    
    # Extract stats and fantasy points
    stats_hash = player_data['stats'] || {}
    fantasy_points = extract_fantasy_points_from_response(stats_hash)
    
    # Find or create the player stat record
    player_stat = SleeperPlayerStat.find_or_initialize_by(
      sleeper_player_id: player_id,
      season: season,
      week: stat_week,
      season_type: season_type
    )
    
    # Update attributes
    player_stat.assign_attributes(
      player_name: player_name,
      position: position,
      team: team,
      stats: stats_hash,
      fantasy_points_standard: fantasy_points[:standard],
      fantasy_points_half_ppr: fantasy_points[:half_ppr],
      fantasy_points_ppr: fantasy_points[:ppr]
    )
    
    player_stat.save!
    player_stat
  end
  
  def import_player_stat(player_id, player_data, week: nil)
    # Use the provided week or fall back to instance week
    stat_week = week || self.week
    
    # Extract basic player info
    player_name = extract_player_name(player_data)
    position = player_data['pos'] || extract_position(player_data)
    team = player_data['team']
    
    # Extract fantasy points
    fantasy_points = extract_fantasy_points(player_data)
    
    # Find or create the player stat record
    player_stat = SleeperPlayerStat.find_or_initialize_by(
      sleeper_player_id: player_id,
      season: season,
      week: stat_week,
      season_type: season_type
    )
    
    # Update attributes
    player_stat.assign_attributes(
      player_name: player_name,
      position: position,
      team: team,
      stats: player_data,
      fantasy_points_standard: fantasy_points[:standard],
      fantasy_points_half_ppr: fantasy_points[:half_ppr],
      fantasy_points_ppr: fantasy_points[:ppr]
    )
    
    player_stat.save!
    player_stat
  end
  
  def extract_player_name(player_data)
    # Try different possible name fields
    player_data['player_name'] || 
    player_data['name'] || 
    [player_data['first_name'], player_data['last_name']].compact.join(' ') ||
    "Unknown Player"
  end
  
  def extract_position(player_data)
    # Try different possible position fields
    player_data['position'] || 
    player_data['pos'] || 
    player_data['fantasy_position'] ||
    'UNKNOWN'
  end
  
  def extract_fantasy_points(player_data)
    {
      standard: player_data['pts_std']&.to_f || 0.0,
      half_ppr: player_data['pts_half_ppr']&.to_f || 0.0,
      ppr: player_data['pts_ppr']&.to_f || 0.0
    }
  end

  def extract_player_name_from_response(player_info)
    return "Unknown Player" if player_info.empty?
    
    first_name = player_info['first_name']
    last_name = player_info['last_name']
    
    if first_name.present? && last_name.present?
      "#{first_name} #{last_name}"
    elsif first_name.present?
      first_name
    elsif last_name.present?
      last_name
    else
      "Unknown Player"
    end
  end

  def extract_position_from_response(player_info, player_data)
    # Try multiple sources for position
    position = player_info['position'] || 
               player_info['pos'] || 
               player_data['position'] ||
               'UNKNOWN'
    
    # Map some position variants
    case position.upcase
    when 'CB', 'FS', 'SS', 'S' then 'DB'
    when 'ILB', 'OLB', 'MLB' then 'LB'
    when 'DT', 'DE', 'NT' then 'DL'
    when 'FB' then 'RB'
    else position.upcase
    end
  end

  def extract_fantasy_points_from_response(stats_hash)
    {
      standard: stats_hash['pts_std']&.to_f || 0.0,
      half_ppr: stats_hash['pts_half_ppr']&.to_f || 0.0,
      ppr: stats_hash['pts_ppr']&.to_f || 0.0
    }
  end
end