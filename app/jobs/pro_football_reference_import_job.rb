class ProFootballReferenceImportJob < ApplicationJob
  queue_as :default
  retry_on StandardError, attempts: 1
  
  def perform(stat_type, season)
    service = ProFootballReferenceImportService.new(
      stat_type: stat_type,
      season: season
    )

    if service.call
      Rails.logger.info "Successfully imported #{stat_type} data for #{season}"
    else
      Rails.logger.error "Failed to import #{stat_type} data: #{service.custom_errors.join(', ')}"
      raise "Import failed: #{service.custom_errors.join(', ')}"
    end
  end
end
