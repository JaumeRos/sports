class CreateSportsEvents < ActiveRecord::Migration[7.2]
  def change
    create_table :sports_events do |t|
      t.string :title
      t.text :description
      t.string :sport_type
      t.datetime :start_time
      t.datetime :end_time
      t.string :location
      t.string :stadium
      t.string :league_tier
      t.string :home_team
      t.string :away_team
      t.decimal :ticket_price
      t.integer :capacity
      t.string :organizer
      t.string :event_status
      t.string :weather_conditions
      t.boolean :televised
      t.string :streaming_url
      t.integer :attendance

      t.timestamps
    end
  end
end
