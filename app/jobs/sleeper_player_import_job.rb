class SleeperPlayerImportJob < ApplicationJob
  queue_as :default

  def perform
    Rails.logger.info "Starting Sleeper player import job"
    
    begin
      imported_count = SleeperPlayer.import_from_sleeper_api
      Rails.logger.info "SleeperPlayerImportJob completed successfully. Imported #{imported_count} players."
    rescue => e
      Rails.logger.error "SleeperPlayerImportJob failed: #{e.message}"
      Rails.logger.error e.backtrace.join("\n")
      raise e
    end
  end
end