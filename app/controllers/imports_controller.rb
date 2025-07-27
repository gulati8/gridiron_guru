class ImportsController < ApplicationController
  before_action :authenticate_user! if respond_to?(:authenticate_user!)
  
  def index
    @recent_imports = ImportLog.recent.limit(20) if defined?(ImportLog)
  end
  
  def pro_football_reference_player_stats
    # Form for importing Pro Football Reference player stats
  end
  
  def import_pro_football_reference_stats
    file_path = params[:file_path]
    position = params[:position]
    season = params[:season]
    
    if file_path.present? && position.present? && season.present?
      ProFootballReferenceImportJob.perform_later(file_path, position, season)
      redirect_to imports_path, notice: "Import job queued for #{position} #{season} season"
    else
      redirect_to pro_football_reference_player_stats_imports_path, alert: "Please provide all required fields"
    end
  end
  
  def bulk_import_pro_football_reference_stats
    directory_path = params[:directory_path]
    season = params[:season]
    
    if directory_path.present? && season.present?
      BulkProFootballReferenceImportJob.perform_later(directory_path, season)
      redirect_to imports_path, notice: "Bulk import job queued for #{season} season"
    else
      redirect_to pro_football_reference_player_stats_imports_path, alert: "Please provide directory path and season"
    end
  end
end
