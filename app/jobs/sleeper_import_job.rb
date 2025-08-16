class SleeperImportJob < ApplicationJob
  queue_as :sleeper_imports

  def perform(username:, seasons:)
    Rails.logger.info "Starting Sleeper import for #{username}, seasons: #{seasons}"
    
    service = SleeperImportService.new(username: username, seasons: seasons)
    
    if service.call
      Rails.logger.info "Sleeper import completed successfully for #{username}"
      Rails.logger.info "Import summary: #{service.imported_data}"
    else
      Rails.logger.error "Sleeper import failed for #{username}"
      raise "Sleeper import failed for #{username}"
    end
  end
end
