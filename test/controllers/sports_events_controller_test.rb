require "test_helper"

class SportsEventsControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get sports_events_index_url
    assert_response :success
  end

  test "should get show" do
    get sports_events_show_url
    assert_response :success
  end
end
