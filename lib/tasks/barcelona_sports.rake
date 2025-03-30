namespace :barcelona_sports do
  desc "Fetch and store Barcelona sports events"
  task fetch_events: :environment do
    puts "Starting to fetch Barcelona sports events"
    service = BarcelonaSportsApiService.new
    events = service.fetch_todays_events
    
    if events.present?
      puts "Found #{events.size} events from API"
      
      events.each do |event|
        # Use the external ID from the API to check if event already exists
        existing_event = SportsEvent.find_by(external_id: event['id'].to_s)
        
        event_attributes = {
          title: event['title'],
          description: event['description'],
          sport_type: event['sport_type'],
          start_time: event['start_time'],
          end_time: event['end_time'],
          location: event['location'],
          stadium: event['stadium'],
          league_tier: event['league_tier'],
          home_team: event['home_team'],
          away_team: event['away_team'],
          ticket_price: event['ticket_price'] || 0.0,
          capacity: event['capacity'] || 1000,
          organizer: event['organizer'] || 'Barcelona Sports',
          event_status: event['event_status'] || 'scheduled',
          weather_conditions: event['weather_conditions'] || 'Check local forecast',
          televised: event['televised'] || false,
          streaming_url: event['streaming_url'],
          attendance: event['attendance'],
          external_id: event['id'].to_s,
          last_fetched_at: Time.current
        }
        
        if existing_event
          existing_event.update(event_attributes)
          puts "Updating event: #{event['title']}"
        else
          SportsEvent.create!(event_attributes)
          puts "Creating new event: #{event['title']}"
        end
      end
      
      puts "Completed fetching Barcelona sports events"
    else
      puts "No events found from the API"
    end
  end
end 