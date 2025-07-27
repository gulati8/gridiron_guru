# app/controllers/analytics_controller.rb
class AnalyticsController < ApplicationController
  before_action :authenticate_user! if respond_to?(:authenticate_user!)
  
  # GET / (root)
  # GET /analytics
  def index
    @season = params[:season]&.to_i || Date.current.year
    @position_data = {}
    
    %w[QB RB WR TE].each do |position|
      begin
        rankings = Analytics::PositionRankings.new(position, @season)
        sleepers = rankings.sleeper_candidates
        busts = rankings.bust_candidates
        
        @position_data[position] = {
          top_performers: rankings.top_performers(10),
          sleepers: sleepers.respond_to?(:first) ? sleepers.first(5) : [],
          busts: busts.respond_to?(:first) ? busts.first(5) : [],
          scarcity: rankings.position_scarcity_analysis
        }
      rescue => e
        Rails.logger.error "Error loading analytics for #{position} in #{@season}: #{e.message}"
        @position_data[position] = {
          top_performers: [],
          sleepers: [],
          busts: [],
          scarcity: {}
        }
      end
    end
  end
  
  # GET /analytics/:id (player detail)
  def show
    @player = Player.find(params[:id])
    @season = params[:season]&.to_i || Date.current.year
    @analyzer = Analytics::PlayerAnalyzer.new(@player, @season)
    @stats = @player.season_stats(@season)
    
    return redirect_to analytics_path, alert: "No stats found for #{@player.name} in #{@season}" unless @stats
    
    @efficiency_metrics = @analyzer.efficiency_metrics
    @fantasy_value_score = @analyzer.fantasy_value_score
    @injury_risk = @analyzer.injury_risk_factors
  end
  
  # GET /analytics/rankings
  def rankings
    @position = params[:position]&.upcase || 'RB'
    @season = params[:season]&.to_i || Date.current.year
    @scoring_type = params[:scoring_type]&.to_sym || :ppr
    
    begin
      @rankings = Analytics::PositionRankings.new(@position, @season, @scoring_type)
      @performers = @rankings.top_performers(50)
      @sleepers = @rankings.sleeper_candidates
      @busts = @rankings.bust_candidates
      @scarcity_analysis = @rankings.position_scarcity_analysis
    rescue => e
      Rails.logger.error "Error loading rankings for #{@position} in #{@season}: #{e.message}"
      flash.now[:alert] = "Error loading rankings data for #{@season}. Please try a different season."
      @performers = []
      @sleepers = []
      @busts = []
      @scarcity_analysis = {}
    end
  end
  
  # GET /analytics/teams
  def teams
    @team = params[:team]&.upcase
    @season = params[:season]&.to_i || Date.current.year
    
    return redirect_to analytics_path, alert: "Please select a team" unless @team
    
    @team_players = {}
    %w[QB RB WR TE].each do |position|
      begin
        stats_class = "#{position.capitalize}SeasonStat".constantize
        @team_players[position] = stats_class.includes(:player)
                                            .by_season(@season)
                                            .by_team(@team)
                                            .joins(:player)
                                            .where(players: { active: true })
      rescue => e
        Rails.logger.error "Error loading team data for #{position} #{@team} in #{@season}: #{e.message}"
        @team_players[position] = []
      end
    end
  end
end
