class ProFootballReferenceImportJob < ApplicationJob
  queue_as :default
  
  def perform(file_path, position, season)
    service = ProFootballReferenceImportService.new(
      file_path: file_path,
      position: position,
      season: season
    )

    if service.call
      Rails.logger.info "Successfully imported #{position} data for #{season}"
    else
      Rails.logger.error "Failed to import #{position} data: #{service.errors.join(', ')}"
      raise "Import failed: #{service.errors.join(', ')}"
    end
  end
end
