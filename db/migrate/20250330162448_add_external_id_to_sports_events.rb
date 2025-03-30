class AddExternalIdToSportsEvents < ActiveRecord::Migration[7.2]
  def change
    add_column :sports_events, :external_id, :string
    add_column :sports_events, :last_fetched_at, :datetime
    
    add_index :sports_events, :external_id
  end
end
