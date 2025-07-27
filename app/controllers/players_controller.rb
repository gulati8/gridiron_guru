class PlayersController < ApplicationController
  before_action :set_position
  before_action :set_season

  def index
    @players = Player.includes(season_stats_association)
                    .by_position(@position)
                    .active
                    .joins(season_stats_association)
                    .where(season_stats_table => { season: @season })
                    .order(:name)

    @stats_summary = calculate_position_stats
  end

  def show
    @player = Player.find(params[:id])
    
    # Ensure player is the correct position
    redirect_to position_path(@player.position.downcase), alert: "Player not found in #{@position} position" unless @player.position == @position
    
    @stats = @player.season_stats(@season)
    redirect_to position_path(@position.downcase), alert: "No #{@season} stats found for #{@player.name}" unless @stats
    
    @analyzer = Analytics::PlayerAnalyzer.new(@player, @season)
    @efficiency_metrics = @analyzer.efficiency_metrics
    @fantasy_value_score = @analyzer.fantasy_value_score
    @injury_risk = @analyzer.injury_risk_factors
    
    # Get weekly stats for charting
    @weekly_stats = @player.weekly_stats(@season)
    @chart_data = generate_chart_data(@weekly_stats)
  end

  private

  def set_position
    @position = params[:position]&.upcase
    redirect_to root_path, alert: "Invalid position" unless %w[QB RB WR TE].include?(@position)
  end

  def set_season
    @season = params[:season]&.to_i || Date.current.year
  end

  def season_stats_association
    case @position
    when 'QB' then :qb_season_stats
    when 'RB' then :rb_season_stats
    when 'WR' then :wr_season_stats
    when 'TE' then :te_season_stats
    end
  end

  def season_stats_table
    case @position
    when 'QB' then :qb_season_stats
    when 'RB' then :rb_season_stats
    when 'WR' then :wr_season_stats
    when 'TE' then :te_season_stats
    end
  end

  def calculate_position_stats
    return {} unless @players.any?

    stats_with_fantasy_points = @players.map do |player|
      stats = player.season_stats(@season)
      next unless stats

      # Calculate fantasy points, handling nil values
      fantasy_points = if stats.respond_to?(:fantasy_points_ppr) && stats.fantasy_points_ppr
        stats.fantasy_points_ppr
      elsif stats.respond_to?(:calculate_fantasy_points)
        stats.calculate_fantasy_points(:ppr)
      else
        0
      end

      {
        player: player,
        stats: stats,
        fantasy_points: fantasy_points || 0
      }
    end.compact

    return {} if stats_with_fantasy_points.empty?

    # Ensure all fantasy_points are numeric
    valid_fantasy_points = stats_with_fantasy_points.map { |p| p[:fantasy_points].to_f }
    
    {
      total_players: @players.count,
      avg_fantasy_points: valid_fantasy_points.sum / valid_fantasy_points.count,
      top_performer: stats_with_fantasy_points.max_by { |p| p[:fantasy_points].to_f }&.dig(:player),
      position_name: position_display_name
    }
  end

  def position_display_name
    case @position
    when 'QB' then 'Quarterbacks'
    when 'RB' then 'Running Backs'
    when 'WR' then 'Wide Receivers'
    when 'TE' then 'Tight Ends'
    end
  end

  def position_path(position)
    case position.downcase
    when 'qb' then '/quarterbacks'
    when 'rb' then '/running-backs'
    when 'wr' then '/wide-receivers'
    when 'te' then '/tight-ends'
    else root_path
    end
  end

  def generate_chart_data(weekly_stats)
    return {} if weekly_stats.empty?

    weeks = weekly_stats.map(&:week)
    
    case @position
    when 'QB'
      {
        fantasy_points: {
          labels: weeks,
          datasets: [{
            label: 'Fantasy Points (PPR)',
            data: weekly_stats.map { |stat| stat.fantasy_points_ppr || stat.calculate_fantasy_points(:ppr) },
            borderColor: 'rgb(75, 192, 192)',
            backgroundColor: 'rgba(75, 192, 192, 0.1)',
            tension: 0.1
          }]
        },
        passing_yards: {
          labels: weeks,
          datasets: [{
            label: 'Passing Yards',
            data: weekly_stats.map(&:pass_yds),
            borderColor: 'rgb(54, 162, 235)',
            backgroundColor: 'rgba(54, 162, 235, 0.1)',
            tension: 0.1
          }]
        },
        passing_tds: {
          labels: weeks,
          datasets: [{
            label: 'Passing TDs',
            data: weekly_stats.map(&:pass_td),
            borderColor: 'rgb(255, 99, 132)',
            backgroundColor: 'rgba(255, 99, 132, 0.1)',
            tension: 0.1
          }]
        }
      }
    when 'RB'
      {
        fantasy_points: {
          labels: weeks,
          datasets: [{
            label: 'Fantasy Points (PPR)',
            data: weekly_stats.map { |stat| stat.fantasy_points_ppr || stat.calculate_fantasy_points(:ppr) },
            borderColor: 'rgb(75, 192, 192)',
            backgroundColor: 'rgba(75, 192, 192, 0.1)',
            tension: 0.1
          }]
        },
        rushing_yards: {
          labels: weeks,
          datasets: [{
            label: 'Rushing Yards',
            data: weekly_stats.map(&:rush_yds),
            borderColor: 'rgb(255, 159, 64)',
            backgroundColor: 'rgba(255, 159, 64, 0.1)',
            tension: 0.1
          }]
        },
        receiving_yards: {
          labels: weeks,
          datasets: [{
            label: 'Receiving Yards',
            data: weekly_stats.map(&:rec_yds),
            borderColor: 'rgb(153, 102, 255)',
            backgroundColor: 'rgba(153, 102, 255, 0.1)',
            tension: 0.1
          }]
        },
        total_touchdowns: {
          labels: weeks,
          datasets: [{
            label: 'Total TDs',
            data: weekly_stats.map(&:total_td),
            borderColor: 'rgb(255, 99, 132)',
            backgroundColor: 'rgba(255, 99, 132, 0.1)',
            tension: 0.1
          }]
        }
      }
    when 'WR', 'TE'
      {
        fantasy_points: {
          labels: weeks,
          datasets: [{
            label: 'Fantasy Points (PPR)',
            data: weekly_stats.map { |stat| stat.fantasy_points_ppr || stat.calculate_fantasy_points(:ppr) },
            borderColor: 'rgb(75, 192, 192)',
            backgroundColor: 'rgba(75, 192, 192, 0.1)',
            tension: 0.1
          }]
        },
        receiving_yards: {
          labels: weeks,
          datasets: [{
            label: 'Receiving Yards',
            data: weekly_stats.map(&:rec_yds),
            borderColor: 'rgb(54, 162, 235)',
            backgroundColor: 'rgba(54, 162, 235, 0.1)',
            tension: 0.1
          }]
        },
        targets: {
          labels: weeks,
          datasets: [{
            label: 'Targets',
            data: weekly_stats.map(&:targets),
            borderColor: 'rgb(255, 159, 64)',
            backgroundColor: 'rgba(255, 159, 64, 0.1)',
            tension: 0.1
          }]
        },
        receptions: {
          labels: weeks,
          datasets: [{
            label: 'Receptions',
            data: weekly_stats.map(&:rec),
            borderColor: 'rgb(153, 102, 255)',
            backgroundColor: 'rgba(153, 102, 255, 0.1)',
            tension: 0.1
          }]
        }
      }
    else
      {}
    end
  end
end