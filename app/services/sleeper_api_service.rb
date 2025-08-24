class SleeperApiService
  include ActiveModel::Model
  
  BASE_URL = 'https://api.sleeper.app/v1'.freeze
  RATE_LIMIT_DELAY = 0.06 # 60ms delay to stay under 1000 calls/minute
  CACHE_TTL = 24.hours # 24 hour cache TTL for all endpoints
  
  attr_accessor :rate_limit_enabled
  
  def initialize(rate_limit_enabled: true)
    @rate_limit_enabled = rate_limit_enabled
  end
  
  # User endpoints
  def get_user(username)
    cached_get_request("/user/#{username}", "user:#{username}")
  end
  
  def get_user_leagues(user_id, season)
    cached_get_request("/user/#{user_id}/leagues/nfl/#{season}", "user_leagues:#{user_id}:#{season}")
  end
  
  # League endpoints
  def get_league(league_id)
    cached_get_request("/league/#{league_id}", "league:#{league_id}")
  end
  
  def get_league_rosters(league_id)
    cached_get_request("/league/#{league_id}/rosters", "league_rosters:#{league_id}")
  end
  
  def get_league_users(league_id)
    cached_get_request("/league/#{league_id}/users", "league_users:#{league_id}")
  end
  
  def get_league_matchups(league_id, week)
    cached_get_request("/league/#{league_id}/matchups/#{week}", "league_matchups:#{league_id}:#{week}")
  end
  
  def get_league_drafts(league_id)
    cached_get_request("/league/#{league_id}/drafts", "league_drafts:#{league_id}")
  end
  
  def get_league_transactions(league_id, week)
    cached_get_request("/league/#{league_id}/transactions/#{week}", "league_transactions:#{league_id}:#{week}")
  end
  
  # Draft endpoints
  def get_draft(draft_id)
    cached_get_request("/draft/#{draft_id}", "draft:#{draft_id}")
  end
  
  def get_draft_picks(draft_id)
    cached_get_request("/draft/#{draft_id}/picks", "draft_picks:#{draft_id}")
  end
  
  # Player endpoints
  def get_players_nfl
    cached_get_request("/players/nfl", "players_nfl")
  end
  
  # State endpoints
  def get_nfl_state
    cached_get_request("/state/nfl", "nfl_state")
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
    cache_key = "player_stats:#{season}:#{week}:#{season_type}:#{positions&.join(',') || 'all'}"
    cached_get_request_stats(full_endpoint, cache_key)
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
    cache_key = "season_stats:#{season}:#{season_type}:#{positions&.join(',') || 'all'}"
    cached_get_request_stats(full_endpoint, cache_key)
  end
  
  private
  
  def cached_get_request(endpoint, cache_key)
    full_cache_key = "sleeper_api:#{cache_key}"
    
    # Always check cache first
    cached_data = Rails.cache.read(full_cache_key)
    if cached_data
      Rails.logger.info "Cache hit for Sleeper API: #{cache_key}"
      return cached_data
    end
    
    # Cache miss - make API call
    Rails.logger.info "Cache miss for Sleeper API: #{cache_key}"
    data = get_request(endpoint)
    
    # Cache the response with TTL
    if data
      Rails.cache.write(full_cache_key, data, expires_in: CACHE_TTL)
      Rails.logger.info "Cached Sleeper API response: #{cache_key} (TTL: #{CACHE_TTL})"
    end
    
    data
  end
  
  def cached_get_request_stats(endpoint, cache_key)
    full_cache_key = "sleeper_api:#{cache_key}"
    
    # Always check cache first
    cached_data = Rails.cache.read(full_cache_key)
    if cached_data
      Rails.logger.info "Cache hit for Sleeper Stats API: #{cache_key}"
      return cached_data
    end
    
    # Cache miss - make API call
    Rails.logger.info "Cache miss for Sleeper Stats API: #{cache_key}"
    data = get_request_stats(endpoint)
    
    # Cache the response with TTL
    if data
      Rails.cache.write(full_cache_key, data, expires_in: CACHE_TTL)
      Rails.logger.info "Cached Sleeper Stats API response: #{cache_key} (TTL: #{CACHE_TTL})"
    end
    
    data
  end
  
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