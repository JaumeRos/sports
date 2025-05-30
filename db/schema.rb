# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[7.2].define(version: 2025_03_30_162448) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "sports_events", force: :cascade do |t|
    t.string "title"
    t.text "description"
    t.string "sport_type"
    t.datetime "start_time"
    t.datetime "end_time"
    t.string "location"
    t.string "stadium"
    t.string "league_tier"
    t.string "home_team"
    t.string "away_team"
    t.decimal "ticket_price"
    t.integer "capacity"
    t.string "organizer"
    t.string "event_status"
    t.string "weather_conditions"
    t.boolean "televised"
    t.string "streaming_url"
    t.integer "attendance"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "external_id"
    t.datetime "last_fetched_at"
  end
end
