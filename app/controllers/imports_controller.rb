class ImportsController < ApplicationController
  before_action :authenticate_user! if respond_to?(:authenticate_user!)
  
  def index
    @recent_imports = ImportLog.recent.limit(20) if defined?(ImportLog)
  end
  
  def pro_football_reference_player_stats
    # Form for importing Pro Football Reference player stats
  end
  
  def import_pro_football_reference_stats
    stat_type = params[:stat_type]
    season = params[:season]
    
    if stat_type.present? && season.present?
      ProFootballReferenceImportJob.perform_later(stat_type, season)
      redirect_to imports_path, notice: "Import job queued for #{stat_type} #{season} season"
    else
      redirect_to imports_path, alert: "Please provide stat type and season"
    end
  end
  
  def bulk_import_pro_football_reference_stats
    season = params[:season]
    
    if season.present?
      BulkProFootballReferenceImportJob.perform_later(season)
      redirect_to imports_path, notice: "Bulk import job queued for #{season} season (all stat types)"
    else
      redirect_to imports_path, alert: "Please provide season"
    end
  end

  def sleeper_league_data
    # Form for importing Sleeper league data
  end

  def import_sleeper_league_data
    username = params[:username]
    seasons = params[:seasons]&.split(',')&.map(&:strip)&.map(&:to_i)
    
    if username.present? && seasons.present?
      SleeperImportJob.perform_later(username: username, seasons: seasons)
      redirect_to imports_path, notice: "Sleeper import job queued for #{username} (seasons: #{seasons.join(', ')})"
    else
      redirect_to imports_path, alert: "Please provide username and seasons"
    end
  end

  def bulk_import_sleeper_league_data
    username = params[:username]
    start_season = params[:start_season]&.to_i || 2017
    end_season = params[:end_season]&.to_i || Date.current.year
    
    if username.present?
      SleeperBulkImportJob.perform_later(
        username: username,
        start_season: start_season,
        end_season: end_season
      )
      redirect_to imports_path, notice: "Bulk Sleeper import job queued for #{username} (#{start_season}-#{end_season})"
    else
      redirect_to imports_path, alert: "Please provide username"
    end
  end

  # Sleeper Player Stats import actions
  def sleeper_player_stats
    # Form for importing Sleeper player stats
  end

  def import_sleeper_player_stats
    season = params[:season]&.to_i
    week = params[:week]&.to_i if params[:week].present?
    season_type = params[:season_type] || 'regular'
    
    if season.present?
      SleeperPlayerStatsImportJob.perform_later(
        season: season,
        week: week,
        season_type: season_type
      )
      
      if week
        redirect_to imports_path, notice: "Player stats import queued for #{season} week #{week}"
      else
        redirect_to imports_path, notice: "Season player stats import queued for #{season}"
      end
    else
      redirect_to imports_path, alert: "Please provide season"
    end
  end

  def bulk_import_sleeper_player_stats
    season = params[:season]&.to_i
    start_week = params[:start_week]&.to_i || 1
    end_week = params[:end_week]&.to_i || 18
    season_type = params[:season_type] || 'regular'
    
    if season.present?
      weeks = (start_week..end_week).to_a
      
      BulkSleeperPlayerStatsImportJob.perform_later(
        season: season,
        weeks: weeks,
        season_type: season_type
      )
      
      redirect_to imports_path, notice: "Bulk player stats import queued for #{season} weeks #{start_week}-#{end_week}"
    else
      redirect_to imports_path, alert: "Please provide season"
    end
  end

  # Sleeper Player import actions
  def import_sleeper_players
    use_cache = params[:use_cache] == 'true'
    
    SleeperPlayerImportJob.perform_later(use_cache: use_cache)
    
    if use_cache
      redirect_to imports_path, notice: "Sleeper player import queued (using cached data)"
    else
      redirect_to imports_path, notice: "Sleeper player import queued (fresh API call - may take time)"
    end
  end
end
