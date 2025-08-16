class SleeperPlayerStatsImportJob < ApplicationJob
  queue_as :sleeper_imports
  
  def perform(season:, week: nil, season_type: 'regular')
    import_service = SleeperPlayerStatsImportService.new(
      season: season,
      week: week,
      season_type: season_type
    )
    
    if week
      # Import specific week
      result = import_service.import_week_stats
      log_result("Week #{week} stats for #{season}", result)
    else
      # Import season totals
      result = import_service.import_season_stats
      log_result("Season stats for #{season}", result)
    end
    
    result
  end
  
  private
  
  def log_result(description, result)
    if result[:success]
      Rails.logger.info "#{description}: #{result[:message]}"
    else
      Rails.logger.error "#{description} failed: #{result[:error]}"
    end
  end
end