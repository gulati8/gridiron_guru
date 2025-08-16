require "test_helper"

class SleeperAnalyticsControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get sleeper_analytics_index_url
    assert_response :success
  end

  test "should get leagues" do
    get sleeper_analytics_leagues_url
    assert_response :success
  end

  test "should get show" do
    get sleeper_analytics_show_url
    assert_response :success
  end

  test "should get draft_analysis" do
    get sleeper_analytics_draft_analysis_url
    assert_response :success
  end

  test "should get player_performance" do
    get sleeper_analytics_player_performance_url
    assert_response :success
  end

  test "should get team_performance" do
    get sleeper_analytics_team_performance_url
    assert_response :success
  end
end
