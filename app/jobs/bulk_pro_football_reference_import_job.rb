class BulkProFootballReferenceImportJob < ApplicationJob
  queue_as :default
  
  def perform(directory_path, season)
    results = ProFootballReferenceImportService.import_from_files(directory_path, season)

    successful = results.select { |k, v| !k.include?('_errors') && v }.keys
    failed = results.select { |k, v| !k.include?('_errors') && !v }.keys

    Rails.logger.info "Bulk import completed for season #{season}"
    Rails.logger.info "Successful: #{successful.join(', ')}" if successful.any?
    Rails.logger.error "Failed: #{failed.join(', ')}" if failed.any?

    # Log specific errors
    results.each do |key, value|
      if key.include?('_errors') && value.any?
        Rails.logger.error "#{key}: #{value.join(', ')}"
      end
    end
  end
end
