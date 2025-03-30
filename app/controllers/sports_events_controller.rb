class SportsEventsController < ApplicationController
  def index
    # Fetch events from the database first
    if params[:sport_type].present?
      @db_events = SportsEvent.where(sport_type: params[:sport_type])
                         .where(start_time: Time.zone.now.beginning_of_day..Time.zone.now.end_of_day)
                         .order(start_time: :asc)
    else
      @db_events = SportsEvent.where(start_time: Time.zone.now.beginning_of_day..Time.zone.now.end_of_day)
                         .order(start_time: :asc)
    end
    
    # Convert to hash format for the view
    @events = @db_events.map { |event| event_to_hash(event) }
    
    # If no events found and in development, try mock API data
    if @events.blank? && Rails.env.development?
      begin
        # Fully qualify the class name with ::
        api_service = ::BarcelonaSportsApiService.new
        mock_data = api_service.send(:mock_events)
        
        # Filter by sport type if needed
        if params[:sport_type].present?
          mock_data = mock_data.select { |e| e['sport_type'].downcase == params[:sport_type].downcase }
        end
        
        @events = mock_data
      rescue => e
        Rails.logger.error("API Service Error: #{e.message}")
        @events = []
      end
    end
  end

  def show
    @event = SportsEvent.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    flash[:alert] = "Event not found"
    redirect_to sports_events_path
  end
  
  def search
    @api_service = BarcelonaSportsApiService.new
    search_params = {
      q: params[:query]
    }
    
    # Add filters if present
    search_params[:filters] = JSON.generate(
      sport_type: params[:sport_type],
      league_tier: params[:league_tier],
      location: params[:location]
    ) if params[:sport_type].present? || params[:league_tier].present? || params[:location].present?
    
    @events = @api_service.search_events(search_params)
    render :index
  end
  
  private
  
  def save_events_to_database(events)
    events.each do |event_data|
      # Skip if event already exists in the database
      next if SportsEvent.exists?(title: event_data['title'], start_time: event_data['start_time'])
      
      # Create new event record
      SportsEvent.create(
        title: event_data['title'],
        description: event_data['description'],
        sport_type: event_data['sport_type'],
        start_time: event_data['start_time'],
        end_time: event_data['end_time'],
        location: event_data['location'],
        stadium: event_data['stadium'],
        league_tier: event_data['league_tier'],
        home_team: event_data['home_team'],
        away_team: event_data['away_team'],
        ticket_price: event_data['ticket_price'],
        capacity: event_data['capacity'],
        organizer: event_data['organizer'],
        event_status: event_data['event_status'],
        weather_conditions: event_data['weather_conditions'],
        televised: event_data['televised'],
        streaming_url: event_data['streaming_url'],
        attendance: event_data['attendance']
      )
    end
  end
  
  # Convert ActiveRecord objects to hash for consistent handling with API data
  def event_to_hash(event)
    {
      'id' => event.id,
      'title' => event.title,
      'description' => event.description,
      'sport_type' => event.sport_type,
      'start_time' => event.start_time,
      'end_time' => event.end_time,
      'location' => event.location,
      'stadium' => event.stadium,
      'league_tier' => event.league_tier,
      'home_team' => event.home_team,
      'away_team' => event.away_team,
      'ticket_price' => event.ticket_price,
      'capacity' => event.capacity,
      'organizer' => event.organizer,
      'event_status' => event.event_status,
      'weather_conditions' => event.weather_conditions,
      'televised' => event.televised,
      'streaming_url' => event.streaming_url,
      'attendance' => event.attendance
    }
  end
end
