require "open-uri"
require "openssl"

class ProFootballReferenceScraperService
  BASE_URL = "https://www.pro-football-reference.com"
  TABLE_IDS = {
    rushing:    { 
                    base:     "rushing_and_receiving",
                    advanced: "adv_rushing_and_receiving",
                    limit:    150
                },
    receiving:  { 
                    base:     "receiving_and_rushing",
                    advanced: "adv_receiving_and_rushing",
                    limit:    250
                },
    passing:    { 
                    base:     "passing",
                    advanced: "passing_advanced",
                    limit:    50
                }
  }

  attr_reader :stat_type, :season, :players, :rate_limit_wait, :player_content

  def initialize stat_type:, season:, rate_limit_wait: 2
    @stat_type          = stat_type
    @season             = season
    @rate_limit_wait    = rate_limit_wait
    @players            = []
    @player_content     = {}
  end

  def scrape_stats
    url = "#{BASE_URL}/years/#{season}/#{stat_type}.htm"
    doc = get_page_content(url)

    p "Fetching #{TABLE_IDS[stat_type.to_sym][:limit]} rows for #{stat_type} in #{season}"
    doc.css("##{stat_type} tbody tr").take(TABLE_IDS[stat_type.to_sym][:limit]).each do |row|
      next if row.css("td").empty?

      player_link = row.css("td[data-stat='name_display'] a").first
      next unless player_link

      p "Fetching #{season} #{stat_type} data for #{player_link.text.strip}"
      player_url = BASE_URL + player_link["href"]
      players << {
        name:           player_link.text.strip,
        season:         season,
        url:            player_url,
        position:       row.css("td[data-stat='pos']").text.strip,
        season_stats:   scrape_player_data(player_url, :base),
        advanced_stats: scrape_player_data(player_url, :advanced)
      }
    end

    players
  end

  private

  def get_page_content url
    player_content[url] ||= begin
        sleep(rate_limit_wait)
        Rails.logger.info "Fetching URL: #{url}"
        
        # Configure SSL options for production environments
        ssl_options = {
          ssl_verify_mode: OpenSSL::SSL::VERIFY_NONE,
          "User-Agent" => "Mozilla/5.0 (compatible; GridironGuru/1.0)"
        }
        
        Nokogiri::HTML(URI.open(url, ssl_options))
    rescue => e
        Rails.logger.error "Failed to fetch URL #{url}: #{e.message}"
        Rails.logger.error e.backtrace.first(3).join("\n") if e.backtrace
        raise "Failed to fetch data from Pro Football Reference: #{e.message}"
    end
  end

  def scrape_player_data player_url, category
    season_stats = {}

    doc = get_page_content(player_url)
    seasonal_row_id = "##{TABLE_IDS[stat_type.to_sym][category]}\\.#{season}"
    seasonal_row = doc.css(seasonal_row_id)
    return unless seasonal_row
    
    seasonal_row.css('td').each do |cell|
      stat_name = cell['data-stat']
      next unless stat_name
      
      value = cell.text.strip
      season_stats[stat_name.to_sym] = value.match?(/^\d+$/) ? value.to_i : value
    end
    season_stats
  end
end
