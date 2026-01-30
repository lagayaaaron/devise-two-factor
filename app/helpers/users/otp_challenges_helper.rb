# app/helpers/users/otp_challenges_helper.rb
module Users::OtpChallengesHelper
  def session_remaining_time
    return 0 unless session[:otp_timestamp]

    elapsed = Time.current.to_i - session[:otp_timestamp]
    remaining = (10.minutes.to_i - elapsed)

    [ remaining, 0 ].max
  end

  def format_time(seconds)
    minutes = seconds / 60
    secs = seconds % 60
    "#{minutes}:#{secs.to_s.rjust(2, '0')}"
  end
end
