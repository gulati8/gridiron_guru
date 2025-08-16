class BulkProFootballReferenceImportJob < ApplicationJob
  queue_as :default
  retry_on StandardError, attempts: 1
  
  def perform(season)
    stat_types = %w[passing rushing receiving]
    results = {}
    
    stat_types.each do |stat_type|
      begin
        service = ProFootballReferenceImportService.new(
          stat_type: stat_type,
          season: season
        )
        
        results[stat_type] = service.call
        results["#{stat_type}_errors"] = service.custom_errors if service.custom_errors.any?
        
        Rails.logger.info "Completed #{stat_type} import for #{season}"
      rescue => e
        results[stat_type] = false
        results["#{stat_type}_errors"] = [e.message]
        Rails.logger.error "Failed #{stat_type} import: #{e.message}"
      end
    end

    successful = results.select { |k, v| !k.include?('_errors') && v }.keys
    failed = results.select { |k, v| !k.include?('_errors') && !v }.keys

    Rails.logger.info "Bulk import completed for season #{season}"
    Rails.logger.info "Successful: #{successful.join(', ')}" if successful.any?
    Rails.logger.error "Failed: #{failed.join(', ')}" if failed.any?

    # Log specific errors
    results.each do |key, value|
      if key.include?('_errors') && value.is_a?(Array) && value.any?
        Rails.logger.error "#{key}: #{value.join(', ')}"
      end
    end
  end
end
