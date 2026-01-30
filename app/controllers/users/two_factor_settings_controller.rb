class Users::TwoFactorSettingsController < ApplicationController
  before_action :authenticate_user!

  def show
  end

  def create
    if current_user.two_factor_enabled?
      redirect_to users_two_factor_settings_path,
                  alert: "Two-factor authentication is already enabled."
      return
    end

    current_user.otp_secret ||= User.generate_otp_secret
    current_user.save!

    session[:otp_user_id] = current_user.id
    session[:otp_timestamp] = Time.current.to_i
    current_user.generate_and_send_email_otp!

    @user = current_user
    @qr_code = generate_qr_code(@user)
    @backup_codes = nil

    render :edit
  end

  def update
    @user = current_user
    otp_code = params[:otp_code].to_s.strip

    if @user.verify_email_otp(otp_code)
      @backup_codes = @user.regenerate_backup_codes!
      @user.enable_two_factor!
      @qr_code = generate_qr_code(@user)
      flash.now[:notice] = "Two-factor authentication enabled successfully!"
      render :edit
    else
      flash.now[:alert] = "Invalid code. Please check your email and try again."
      @qr_code = generate_qr_code(@user)
      @backup_codes = nil
      render :edit, status: :unprocessable_entity
    end
  end

  def backup_codes
    @backup_codes = session.delete(:backup_codes)
    if @backup_codes.blank?
      redirect_to users_two_factor_settings_path,
                  alert: "Backup codes already viewed."
    end
  end

  def destroy
    current_user.disable_two_factor!
    redirect_to users_two_factor_settings_path,
                notice: "Two-factor authentication has been disabled."
  end

  def regenerate_codes
    unless current_user.two_factor_enabled?
      redirect_to users_two_factor_settings_path, alert: "Two-factor authentication is not enabled."
      return
    end

    session[:backup_codes] = current_user.regenerate_backup_codes!
    redirect_to backup_codes_users_two_factor_settings_path
  end

  private

  def generate_qr_code(user)
    label = "#{Rails.application.class.module_parent_name}:#{user.email}"
    otp_secret = user.otp_secret
    RQRCode::QRCode.new(
      ROTP::TOTP.new(otp_secret).provisioning_uri(label)
    ).as_svg(
      offset: 0,
      color: "000",
      shape_rendering: "crispEdges",
      module_size: 6,
      standalone: true
    )
  end
end
