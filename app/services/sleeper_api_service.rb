class SleeperApiService
  include ActiveModel::Model
  
  BASE_URL = 'https://api.sleeper.app/v1'.freeze
  RATE_LIMIT_DELAY = 0.06 # 60ms delay to stay under 1000 calls/minute
  
  attr_accessor :rate_limit_enabled
  
  def initialize(rate_limit_enabled: true)
    @rate_limit_enabled = rate_limit_enabled
  end
  
  # User endpoints
  def get_user(username)
    get_request("/user/#{username}")
  end
  
  def get_user_leagues(user_id, season)
    get_request("/user/#{user_id}/leagues/nfl/#{season}")
  end
  
  # League endpoints
  def get_league(league_id)
    get_request("/league/#{league_id}")
  end
  
  def get_league_rosters(league_id)
    get_request("/league/#{league_id}/rosters")
  end
  
  def get_league_users(league_id)
    get_request("/league/#{league_id}/users")
  end
  
  def get_league_matchups(league_id, week)
    get_request("/league/#{league_id}/matchups/#{week}")
  end
  
  def get_league_drafts(league_id)
    get_request("/league/#{league_id}/drafts")
  end
  
  def get_league_transactions(league_id, week)
    get_request("/league/#{league_id}/transactions/#{week}")
  end
  
  # Draft endpoints
  def get_draft(draft_id)
    get_request("/draft/#{draft_id}")
  end
  
  def get_draft_picks(draft_id)
    get_request("/draft/#{draft_id}/picks")
  end
  
  # Player endpoints
  def get_players_nfl(use_cache: false)
    if use_cache && File.exist?('tmp/sleeper_players_data.json')
      JSON.parse(File.read('tmp/sleeper_players_data.json'))
    else
      get_request("/players/nfl")
    end
  end
  
  # State endpoints
  def get_nfl_state
    get_request("/state/nfl")
  end

  # Player stats endpoints - NEW
  def get_player_stats(season, week, season_type: 'regular', positions: nil)
    endpoint = "/stats/nfl/#{season}/#{week}"
    params = { season_type: season_type }
    
    # Add position filters if specified
    if positions
      position_params = positions.map { |pos| "position[]=#{pos}" }.join('&')
      params[:order_by] = 'pts_ppr' # Default ordering
      query_string = "#{params.to_query}&#{position_params}"
    else
      query_string = params.to_query
    end
    
    full_endpoint = "#{endpoint}?#{query_string}"
    get_request_stats(full_endpoint)
  end

  def get_season_stats(season, season_type: 'regular', positions: nil)
    endpoint = "/stats/nfl/#{season}"
    params = { season_type: season_type }
    
    # Add position filters if specified
    if positions
      position_params = positions.map { |pos| "position[]=#{pos}" }.join('&')
      params[:order_by] = 'pts_ppr'
      query_string = "#{params.to_query}&#{position_params}"
    else
      query_string = params.to_query
    end
    
    full_endpoint = "#{endpoint}?#{query_string}"
    get_request_stats(full_endpoint)
  end
  
  private
  
  def get_request_stats(endpoint)
    # Stats API uses a different base URL
    url = "https://api.sleeper.com#{endpoint}"
    
    Rails.logger.info "Sleeper Stats API request: #{url}"
    
    response = HTTParty.get(url, {
      headers: {
        'User-Agent' => 'GridironGuru/1.0 (Fantasy Football Analytics)',
        'Accept' => 'application/json'
      },
      timeout: 30
    })
    
    handle_response(response, url)
  rescue HTTParty::Error, Net::TimeoutError => e
    Rails.logger.error "Sleeper Stats API request failed for #{url}: #{e.message}"
    raise SleeperApiError, "Stats API request failed: #{e.message}"
  ensure
    # Rate limiting
    sleep(RATE_LIMIT_DELAY) if rate_limit_enabled
  end
  
  def get_request(endpoint)
    url = "#{BASE_URL}#{endpoint}"
    
    Rails.logger.info "Sleeper API request: #{url}"
    
    response = HTTParty.get(url, {
      headers: {
        'User-Agent' => 'GridironGuru/1.0 (Fantasy Football Analytics)',
        'Accept' => 'application/json'
      },
      timeout: 30
    })
    
    handle_response(response, url)
  rescue HTTParty::Error, Net::TimeoutError => e
    Rails.logger.error "Sleeper API request failed for #{url}: #{e.message}"
    raise SleeperApiError, "API request failed: #{e.message}"
  ensure
    # Rate limiting
    sleep(RATE_LIMIT_DELAY) if rate_limit_enabled
  end
  
  def handle_response(response, url)
    case response.code
    when 200
      JSON.parse(response.body) if response.body
    when 404
      Rails.logger.warn "Sleeper API resource not found: #{url}"
      nil
    when 429
      Rails.logger.error "Sleeper API rate limit exceeded for: #{url}"
      raise SleeperApiError, "Rate limit exceeded. Please wait before making more requests."
    when 500..599
      Rails.logger.error "Sleeper API server error (#{response.code}) for: #{url}"
      raise SleeperApiError, "Server error (#{response.code}). Please try again later."
    else
      Rails.logger.error "Sleeper API unexpected response (#{response.code}) for: #{url}"
      raise SleeperApiError, "Unexpected response code: #{response.code}"
    end
  rescue JSON::ParserError => e
    Rails.logger.error "Failed to parse Sleeper API response for #{url}: #{e.message}"
    raise SleeperApiError, "Invalid JSON response: #{e.message}"
  end
end

class SleeperApiError < StandardError; end