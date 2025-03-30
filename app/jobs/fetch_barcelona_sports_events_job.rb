class FetchBarcelonaSportsEventsJob < ApplicationJob
  queue_as :default

  def perform
    Rails.logger.info("Starting to fetch Barcelona sports events")
    
    # Create the API service
    api_service = BarcelonaSportsApiService.new
    
    # Fetch events for today and upcoming events
    today = Date.today
    events = api_service.fetch_todays_events
    
    Rails.logger.info("Found #{events.size} events from API")
    return if events.blank?
    
    # Process each event - either update existing or create new
    events.each do |event_data|
      external_id = event_data['id'].to_s
      event = SportsEvent.find_by(external_id: external_id)
      
      event_attributes = {
        external_id: external_id,
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
        attendance: event_data['attendance'],
        last_fetched_at: Time.current
      }
      
      if event
        Rails.logger.info("Updating event: #{event_data['title']}")
        event.update(event_attributes)
      else
        Rails.logger.info("Creating new event: #{event_data['title']}")
        SportsEvent.create(event_attributes)
      end
    end
    
    Rails.logger.info("Completed fetching Barcelona sports events")
  end
end 