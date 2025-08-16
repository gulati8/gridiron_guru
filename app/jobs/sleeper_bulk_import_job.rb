class SleeperBulkImportJob < ApplicationJob
  queue_as :sleeper_imports

  def perform(username:, start_season: 2017, end_season: Date.current.year)
    Rails.logger.info "Starting bulk Sleeper import for #{username} from #{start_season} to #{end_season}"
    
    seasons = (start_season..end_season).to_a
    total_seasons = seasons.count
    
    seasons.each_with_index do |season, index|
      Rails.logger.info "Processing season #{season} (#{index + 1}/#{total_seasons})"
      
      service = SleeperImportService.new(username: username, seasons: [season])
      
      if service.call
        Rails.logger.info "Season #{season} imported successfully"
        Rails.logger.info "Season #{season} summary: #{service.imported_data}"
      else
        Rails.logger.error "Season #{season} import failed"
        # Continue with next season instead of failing completely
      end
      
      # Brief pause between seasons to be respectful to API
      sleep(1) unless index == total_seasons - 1
    end
    
    Rails.logger.info "Bulk Sleeper import completed for #{username}"
  end
end
