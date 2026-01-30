# app/controllers/users/two_factor_settings_controller.rb
class Users::TwoFactorSettingsController < ApplicationController
  before_action :authenticate_user!

  # Show 2FA settings page
  def show
    # Just show the current status
  end

  # Enable 2FA
  def create
    if current_user.two_factor_enabled?
      redirect_to users_two_factor_settings_path,
                  alert: "Two-factor authentication is already enabled."
      return
    end

    # Generate backup codes
    session[:backup_codes] = current_user.regenerate_backup_codes!
    redirect_to backup_codes_users_two_factor_settings_path
  end

  def backup_codes
    @backup_codes = session.delete(:backup_codes)

    redirect_to users_two_factor_settings_path,
                alert: "Backup codes already viewed." if @backup_codes.blank?
  end

  # Disable 2FA
  def destroy
    current_user.disable_two_factor!
    redirect_to users_two_factor_settings_path, notice: "Two-factor authentication has been disabled."
  end

  # Regenerate backup codes
  def regenerate_codes
    unless current_user.two_factor_enabled?
      redirect_to users_two_factor_settings_path, alert: "Two-factor authentication is not enabled."
      return
    end

    session[:backup_codes] = current_user.regenerate_backup_codes!
    redirect_to backup_codes_users_two_factor_settings_path
  end

  def enable
    current_user.enable_two_factor!
    redirect_to users_two_factor_settings_path,
                notice: "Two-factor authentication enabled successfully."
  end
end
