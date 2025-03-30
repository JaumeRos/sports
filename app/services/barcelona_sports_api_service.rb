require 'httparty'

class BarcelonaSportsApiService
  include HTTParty
  base_uri 'https://opendata-ajuntament.barcelona.cat/data/api/action'
  
  # Barcelona Open Data resource ID for events
  RESOURCE_ID = 'ab2d47b7-8493-4ed5-9f63-49ed116135f9'
  
  def initialize
    # No need for options that might interfere with the query
  end

  # Fetch all sports events happening today in Barcelona
  def fetch_todays_events
    today = Date.today.strftime('%Y-%m-%d')
    
    # Build SQL query to find events happening today
    sql = "SELECT * FROM \"#{RESOURCE_ID}\" " + 
          "WHERE to_char(start_date, 'YYYY-MM-DD') = '#{today}' " +
          "OR to_char(end_date, 'YYYY-MM-DD') = '#{today}' " +
          "LIMIT 50"
    
    url = "#{self.class.base_uri}/datastore_search_sql"
    response = HTTParty.get(url, query: { sql: sql })
    
    if response.success? && response['result'] && response['result']['records']
      events = response['result']['records']
      Rails.logger.info("Found #{events.size} events in API response")
      
      formatted_events = format_api_events(events)
      
      if formatted_events.empty? && Rails.env.development?
        Rails.logger.info("No formatted events, falling back to mock data")
        return mock_events
      else
        return formatted_events
      end
    else
      Rails.logger.error("API Error: #{response.code} - #{response.message}")
      return mock_events if Rails.env.development?
      return []
    end
  rescue => e
    Rails.logger.error("API Request Error: #{e.message}")
    return mock_events if Rails.env.development?
    return []
  end
  
  # Fetch events by sport type
  def fetch_events_by_sport(sport_type)
    # Map sport types to search terms
    search_term = case sport_type.downcase
                  when 'football', 'soccer'
                    'futbol'
                  when 'basketball'
                    'bàsquet'
                  when 'tennis'
                    'tennis'
                  when 'swimming'
                    'natació'
                  when 'volleyball'
                    'vòlei'
                  when 'running'
                    'marató OR cursa'
                  else
                    sport_type
                  end
    
    # Build SQL query to find events with given sport type
    sql = "SELECT * FROM \"#{RESOURCE_ID}\" " +
          "WHERE name ILIKE '%#{search_term}%' " +
          "LIMIT 50"
    
    url = "#{self.class.base_uri}/datastore_search_sql"
    response = HTTParty.get(url, query: { sql: sql })
    
    if response.success? && response['result'] && response['result']['records']
      events = response['result']['records']
      Rails.logger.info("Found #{events.size} events in API response")
      
      formatted_events = format_api_events(events)
      
      if formatted_events.empty? && Rails.env.development?
        Rails.logger.info("No matching events by sport, falling back to mock data")
        return mock_events.select { |e| e['sport_type'].downcase == sport_type.downcase }
      else
        return formatted_events
      end
    else
      Rails.logger.error("API Error: #{response.code} - #{response.message}")
      return mock_events.select { |e| e['sport_type'].downcase == sport_type.downcase } if Rails.env.development?
      return []
    end
  rescue => e
    Rails.logger.error("API Request Error: #{e.message}")
    return mock_events.select { |e| e['sport_type'].downcase == sport_type.downcase } if Rails.env.development?
    return []
  end
  
  # Search for events with custom parameters
  def search_events(params = {})
    query_parts = []
    
    # Add search term if present
    if params[:q].present?
      query_parts << "name ILIKE '%#{params[:q]}%'"
    end
    
    # Add sport type if present
    if params[:sport_type].present?
      search_term = case params[:sport_type].downcase
                    when 'football', 'soccer'
                      'futbol'
                    when 'basketball'
                      'bàsquet'
                    when 'tennis'
                      'tennis'
                    when 'swimming'
                      'natació'
                    when 'volleyball'
                      'vòlei'
                    when 'running'
                      'marató OR cursa'
                    else
                      params[:sport_type]
                    end
      
      query_parts << "name ILIKE '%#{search_term}%'"
    end
    
    # Add location if present
    if params[:location].present?
      query_parts << "addresses_town ILIKE '%#{params[:location]}%'"
    end
    
    # Build the WHERE clause
    where_clause = query_parts.empty? ? "" : "WHERE " + query_parts.join(" AND ")
    
    # Build SQL query
    sql = "SELECT * FROM \"#{RESOURCE_ID}\" #{where_clause} LIMIT 50"
    
    url = "#{self.class.base_uri}/datastore_search_sql"
    response = HTTParty.get(url, query: { sql: sql })
    
    if response.success? && response['result'] && response['result']['records']
      events = response['result']['records']
      Rails.logger.info("Found #{events.size} events in API response")
      
      formatted_events = format_api_events(events)
      
      if formatted_events.empty? && Rails.env.development?
        Rails.logger.info("No matching events from search, falling back to mock data")
        return filtered_mock_events(params)
      else
        return formatted_events
      end
    else
      Rails.logger.error("API Error: #{response.code} - #{response.message}")
      return filtered_mock_events(params) if Rails.env.development?
      return []
    end
  rescue => e
    Rails.logger.error("API Request Error: #{e.message}")
    return filtered_mock_events(params) if Rails.env.development?
    return []
  end
  
  # Test API method that uses the direct approach
  def test_api
    today = Date.today.strftime('%Y-%m-%d')
    url = 'https://opendata-ajuntament.barcelona.cat/data/api/action/datastore_search_sql'
    sql = "SELECT * FROM \"#{RESOURCE_ID}\" WHERE to_char(start_date, 'YYYY-MM-DD') = '#{today}' OR to_char(end_date, 'YYYY-MM-DD') = '#{today}' LIMIT 50"
    
    response = HTTParty.get(url, query: { sql: sql })
    puts "Test response code: #{response.code}"
    
    if response.success? && response['result'] && response['result']['records']
      events = response['result']['records']
      puts "Test found #{events.size} events"
      
      formatted_events = format_api_events(events)
      puts "Test formatted #{formatted_events.size} events"
      return formatted_events
    else
      puts "Test API error: #{response.code} - #{response.message}"
      return []
    end
  rescue => e
    puts "Test exception: #{e.message}"
    return []
  end
  
  private
  
  # Format API events to our application structure
  def format_api_events(api_events)
    Rails.logger.info("Formatting #{api_events.size} events from API")
    return [] if api_events.blank?
    
    formatted_events = api_events.map do |event|
      # Extract event data
      event_name = event['name'] || ''
      
      # Parse dates
      begin
        start_time = parse_date(event['start_date'])
        end_time = parse_date(event['end_date'])
        
        # Use defaults if parsing fails
        start_time ||= DateTime.now
        end_time ||= (start_time + 2.hours)
      rescue => e
        Rails.logger.error("Error parsing dates for event #{event_name}: #{e.message}")
        start_time = DateTime.now
        end_time = start_time + 2.hours
      end
      
      # Detect sport type from event name
      sport_type = determine_sport_type(event_name)
      
      # Extract team names if available
      team_regex = /'(.+?) - (.+?)'/ 
      match = event_name.match(team_regex)
      
      home_team = nil
      away_team = nil
      
      if match && match[1] && match[2]
        home_team = match[1]
        away_team = match[2]
      end
      
      # Format the event
      {
        'id' => event['_id'] || event['register_id'],
        'title' => event_name,
        'description' => event_name,
        'sport_type' => sport_type,
        'start_time' => start_time,
        'end_time' => end_time,
        'location' => event['addresses_town'] || 'Barcelona',
        'stadium' => [
          event['addresses_road_name'],
          event['addresses_start_street_number'],
          event['addresses_neighborhood_name']
        ].compact.join(', ').presence || 'Barcelona',
        'league_tier' => event_name.include?('liga') || event_name.include?('lliga') ? 'professional' : 'recreational',
        'home_team' => home_team,
        'away_team' => away_team,
        'ticket_price' => sport_type == 'football' ? 50.00 : 25.00,
        'capacity' => 5000,
        'organizer' => event['institution_name'].presence || 'Barcelona Sports',
        'event_status' => 'scheduled',
        'weather_conditions' => 'Check local forecast',
        'televised' => sport_type == 'football',
        'streaming_url' => sport_type == 'football' ? 'https://example.com/stream' : nil,
        'attendance' => nil
      }
    end
    
    Rails.logger.info("Successfully formatted #{formatted_events.size} events")
    formatted_events
  end
  
  # Determine sport type based on event name
  def determine_sport_type(event_name)
    event_name = event_name.to_s.downcase
    
    if event_name.include?('bàsquet') || event_name.include?('basket')
      'basketball'
    elsif event_name.include?('futbol') || event_name.include?('barça')
      'football'
    elsif event_name.include?('tenis') || event_name.include?('tennis')
      'tennis'
    elsif event_name.include?('natació') || event_name.include?('piscina')
      'swimming'
    elsif event_name.include?('vòlei') || event_name.include?('volei')
      'volleyball'
    elsif event_name.include?('marató') || event_name.include?('cursa') || event_name.include?('ciclista')
      'running'
    else
      'other'
    end
  end
  
  # Parse date from API format
  def parse_date(date_string)
    return nil if date_string.blank?
    DateTime.parse(date_string) rescue nil
  end
  
  # Filter mock events based on search parameters
  def filtered_mock_events(params)
    events = mock_events
    
    if params[:q].present?
      search_term = params[:q].downcase
      events = events.select do |event| 
        event['title'].downcase.include?(search_term) || 
        event['description'].downcase.include?(search_term)
      end
    end
    
    if params[:sport_type].present?
      events = events.select { |event| event['sport_type'].downcase == params[:sport_type].downcase }
    end
    
    if params[:league_tier].present?
      events = events.select { |event| event['league_tier'].downcase == params[:league_tier].downcase }
    end
    
    if params[:location].present?
      events = events.select { |event| event['location'].downcase.include?(params[:location].downcase) }
    end
    
    events
  end
  
  # Mock events for when API fails or for testing
  def mock_events
    [
      {
        'id' => 1,
        'title' => 'FC Barcelona vs Real Madrid',
        'description' => 'El Clásico match between FC Barcelona and Real Madrid CF',
        'sport_type' => 'football',
        'start_time' => DateTime.now.change(hour: 20, min: 0),
        'end_time' => DateTime.now.change(hour: 22, min: 0),
        'location' => 'Barcelona',
        'stadium' => 'Camp Nou',
        'league_tier' => 'professional',
        'home_team' => 'FC Barcelona',
        'away_team' => 'Real Madrid',
        'ticket_price' => 120.00,
        'capacity' => 99354,
        'organizer' => 'La Liga',
        'event_status' => 'scheduled',
        'weather_conditions' => 'Clear, 22°C',
        'televised' => true,
        'streaming_url' => 'https://example.com/stream',
        'attendance' => 95000
      },
      {
        'id' => 2,
        'title' => 'Barcelona Basketball vs Real Madrid Baloncesto',
        'description' => 'ACB League basketball match',
        'sport_type' => 'basketball',
        'start_time' => DateTime.now.change(hour: 18, min: 30),
        'end_time' => DateTime.now.change(hour: 20, min: 30),
        'location' => 'Barcelona',
        'stadium' => 'Palau Blaugrana',
        'league_tier' => 'professional',
        'home_team' => 'FC Barcelona Basket',
        'away_team' => 'Real Madrid Baloncesto',
        'ticket_price' => 45.00,
        'capacity' => 7585,
        'organizer' => 'ACB League',
        'event_status' => 'scheduled',
        'weather_conditions' => 'Indoor',
        'televised' => true,
        'streaming_url' => 'https://example.com/basket-stream',
        'attendance' => 7200
      },
      {
        'id' => 3,
        'title' => 'Barcelona Marathon',
        'description' => 'Annual marathon through the streets of Barcelona',
        'sport_type' => 'running',
        'start_time' => DateTime.now.change(hour: 8, min: 0),
        'end_time' => DateTime.now.change(hour: 14, min: 0),
        'location' => 'Barcelona',
        'stadium' => 'Plaça d\'Espanya to Plaça Catalunya',
        'league_tier' => 'amateur',
        'home_team' => nil,
        'away_team' => nil,
        'ticket_price' => 0.00,
        'capacity' => 20000,
        'organizer' => 'Barcelona City Council',
        'event_status' => 'in_progress',
        'weather_conditions' => 'Sunny, 18°C',
        'televised' => false,
        'streaming_url' => nil,
        'attendance' => 15000
      },
      {
        'id' => 4,
        'title' => 'Barcelona Tennis Open',
        'description' => 'ATP Tour 500 tournament on clay courts',
        'sport_type' => 'tennis',
        'start_time' => DateTime.now.change(hour: 11, min: 0),
        'end_time' => DateTime.now.change(hour: 19, min: 0),
        'location' => 'Barcelona',
        'stadium' => 'Real Club de Tenis Barcelona',
        'league_tier' => 'professional',
        'home_team' => nil,
        'away_team' => nil,
        'ticket_price' => 75.00,
        'capacity' => 8000,
        'organizer' => 'ATP Tour',
        'event_status' => 'scheduled',
        'weather_conditions' => 'Sunny, 20°C',
        'televised' => true,
        'streaming_url' => 'https://example.com/tennis-stream',
        'attendance' => 7500
      },
      {
        'id' => 5,
        'title' => 'Waterpolo Championship',
        'description' => 'Spanish Waterpolo Championship finals',
        'sport_type' => 'swimming',
        'start_time' => DateTime.now.change(hour: 16, min: 0),
        'end_time' => DateTime.now.change(hour: 18, min: 0),
        'location' => 'Barcelona',
        'stadium' => 'Piscina Sant Jordi',
        'league_tier' => 'professional',
        'home_team' => 'CN Barcelona',
        'away_team' => 'CN Sabadell',
        'ticket_price' => 25.00,
        'capacity' => 3000,
        'organizer' => 'Royal Spanish Swimming Federation',
        'event_status' => 'scheduled',
        'weather_conditions' => 'Indoor',
        'televised' => false,
        'streaming_url' => 'https://example.com/waterpolo-stream',
        'attendance' => 2800
      },
      {
        'id' => 6,
        'title' => 'Beach Volleyball Tournament',
        'description' => 'International beach volleyball tournament',
        'sport_type' => 'volleyball',
        'start_time' => DateTime.now.change(hour: 10, min: 0),
        'end_time' => DateTime.now.change(hour: 18, min: 0),
        'location' => 'Barcelona',
        'stadium' => 'Platja Nova Icària',
        'league_tier' => 'semi-professional',
        'home_team' => nil,
        'away_team' => nil,
        'ticket_price' => 0.00,
        'capacity' => 1000,
        'organizer' => 'FIVB',
        'event_status' => 'scheduled',
        'weather_conditions' => 'Sunny, 23°C',
        'televised' => false,
        'streaming_url' => nil,
        'attendance' => 800
      }
    ]
  end
end 