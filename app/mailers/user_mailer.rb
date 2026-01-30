# app/mailers/user_mailer.rb
class UserMailer < ApplicationMailer
  default from: "noreply@yourapp.com"

  def send_otp(user, otp_code)
    @user = user
    @otp_code = otp_code
    @expires_in = User::OTP_EXPIRY_TIME.in_minutes.to_i

    mail(
      to: @user.email,
      subject: "Your login code for #{Rails.application.class.module_parent_name}"
    )
  end
end
