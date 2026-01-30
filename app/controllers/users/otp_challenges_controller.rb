# app/controllers/users/otp_challenges_controller.rb
class Users::OtpChallengesController < ApplicationController
  skip_before_action :authenticate_user!, raise: false

  before_action :ensure_otp_session, only: [ :new, :create ]
  before_action :check_session_expiry, only: [ :new, :create ]

  def new
    @user = find_pending_user

    unless @user
      redirect_to new_user_session_path, alert: "Session expired. Please sign in again."
    end
  end

  def create
    @user = find_pending_user

    unless @user
      clear_otp_session
      redirect_to new_user_session_path, alert: "Session expired. Please sign in again."
      return
    end

    otp_attempt = params[:otp_attempt]&.strip

    if verify_otp_attempt(@user, otp_attempt)
      complete_sign_in(@user)
    else
      handle_invalid_attempt(@user)
    end
  end

  def cancel
    clear_otp_session
    redirect_to new_user_session_path, notice: "Sign in cancelled."
  end

  private

  def verify_otp_attempt(user, otp_attempt)
    user.verify_any_otp(otp_attempt)
  end

  def ensure_otp_session
    unless session[:otp_user_token].present? && find_pending_user.present?
      clear_otp_session
      redirect_to new_user_session_path, alert: "Please sign in first."
      false
    end
  end

  def check_session_expiry
    if session_expired?
      clear_otp_session
      redirect_to new_user_session_path, alert: "Session expired. Please sign in again."
      false
    end
  end

  def find_pending_user
    token = session[:otp_user_token]
    return nil unless token

    User.decrypt_otp_session_token(token)
  end

  def clear_otp_session
    session.delete(:otp_user_token)
    session.delete(:otp_timestamp)
    session.delete(:otp_failed_attempts)
    session.delete(:otp_remember_me)
  end

  def complete_sign_in(user)
    remember_me = session.delete(:otp_remember_me)
    clear_otp_session

    sign_in(:user, user, remember: remember_me)

    if user.respond_to?(:update_tracked_fields!)
      user.update_tracked_fields!(request)
    end

    redirect_to after_sign_in_path_for(user), notice: "Signed in successfully."
  end

  def handle_invalid_attempt(user)
    increment_failed_attempts
    remaining = max_attempts - failed_attempts_count

    if remaining <= 0
      handle_max_attempts_reached(user)
    else
      flash.now[:alert] = "Invalid authentication code. #{remaining} attempts remaining."
      render :new, status: :unprocessable_entity
    end
  end

  def increment_failed_attempts
    session[:otp_failed_attempts] = failed_attempts_count + 1
  end

  def handle_max_attempts_reached(user)
    Rails.logger.warn "Max OTP attempts for user #{user.id} from #{request.remote_ip}"
    clear_otp_session
    redirect_to new_user_session_path, alert: "Too many failed attempts. Please sign in again."
  end

  def session_expired?
    session[:otp_timestamp].nil? || session[:otp_timestamp] < 10.minutes.ago.to_i
  end

  def clear_otp_session
    session.delete(:otp_user_id)
    session.delete(:otp_timestamp)
    session.delete(:otp_failed_attempts)
    session.delete(:otp_remember_me)
  end

  def failed_attempts_count
    session[:otp_failed_attempts].to_i
  end

  def max_attempts
    5
  end

  def after_sign_in_path_for(user)
    stored_location_for(:user) || root_path
  end
end
