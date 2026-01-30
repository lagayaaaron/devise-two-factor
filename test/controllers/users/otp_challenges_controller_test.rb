require "test_helper"

class Users::OtpChallengesControllerTest < ActionDispatch::IntegrationTest
  test "should get new" do
    get users_otp_challenges_new_url
    assert_response :success
  end

  test "should get create" do
    get users_otp_challenges_create_url
    assert_response :success
  end
end
