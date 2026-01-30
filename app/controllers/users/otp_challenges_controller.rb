class Users::OtpChallengesController < ApplicationController
  skip_before_action :authenticate_user!, raise: false

  before_action :ensure_otp_session
  before_action :check_session_expiry

  def new
    @user = pending_user
    redirect_to new_user_session_path, alert: "Session expired. Please sign in again." unless @user
  end

  def create
    @user = pending_user

    unless @user
      clear_otp_session
      redirect_to new_user_session_path, alert: "Session expired. Please sign in again."
      return
    end

    otp_code = params[:otp_attempt]&.strip

    if @user.verify_any_otp(otp_code)
      complete_sign_in(@user)
    else
      increment_failed_attempts
      remaining = max_attempts - failed_attempts_count

      if remaining <= 0
        clear_otp_session
        redirect_to new_user_session_path, alert: "Too many failed attempts. Please sign in again."
      else
        flash.now[:alert] = "Invalid OTP. #{remaining} attempts remaining."
        render :new, status: :unprocessable_entity
      end
    end
  end

  def cancel
    clear_otp_session
    redirect_to new_user_session_path, notice: "Sign in cancelled."
  end

  private

  def pending_user
    token = session[:otp_user_token]
    return nil unless token
    User.decrypt_otp_session_token(token)
  end

  def ensure_otp_session
    redirect_to new_user_session_path, alert: "Please sign in first." unless session[:otp_user_token].present?
  end

  def check_session_expiry
    if session[:otp_timestamp].nil? || session[:otp_timestamp] < 10.minutes.ago.to_i
      clear_otp_session
      redirect_to new_user_session_path, alert: "Session expired. Please sign in again."
    end
  end

  def complete_sign_in(user)
    clear_otp_session
    sign_in(:user, user)
    redirect_to after_sign_in_path_for(user), notice: "Signed in successfully."
  end

  def clear_otp_session
    session.delete(:otp_user_token)
    session.delete(:otp_timestamp)
    session.delete(:otp_failed_attempts)
  end

  def increment_failed_attempts
    session[:otp_failed_attempts] = failed_attempts_count + 1
  end

  def failed_attempts_count
    session[:otp_failed_attempts].to_i
  end

  def max_attempts
    5
  end
end
