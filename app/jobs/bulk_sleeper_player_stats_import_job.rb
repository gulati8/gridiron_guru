class BulkSleeperPlayerStatsImportJob < ApplicationJob
  queue_as :sleeper_imports
  
  def perform(season:, weeks: nil, season_type: 'regular')
    import_service = SleeperPlayerStatsImportService.new(
      season: season,
      season_type: season_type
    )
    
    # If specific weeks provided, import those; otherwise import full season
    if weeks&.any?
      result = import_service.import_full_season(weeks: weeks)
      log_result("Bulk import for #{season} weeks #{weeks.join(', ')}", result)
    else
      # Import all regular season weeks (1-18)
      result = import_service.import_full_season
      log_result("Full season import for #{season}", result)
    end
    
    result
  end
  
  private
  
  def log_result(description, result)
    if result[:success]
      Rails.logger.info "#{description}: #{result[:message]}"
    else
      Rails.logger.error "#{description} failed with #{result[:errors]&.size || 0} errors"
      result[:errors]&.each { |error| Rails.logger.error "  - #{error}" }
    end
  end
end