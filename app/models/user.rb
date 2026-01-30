# app/models/user.rb
class User < ApplicationRecord
  require "bcrypt"
  require "securerandom"
  # Devise modules
  devise :two_factor_authenticatable,
         :database_authenticatable,
         :registerable,
         :recoverable,
         :rememberable,
         :validatable,
         otp_secret_encryption_key: "692debb19d06c4b498578082fa64e52313bfd0f44c1861aa2e0f4382d94265b54f4aa1359df13fde5a01afc3825a7c37621c535e2d317197eb5c0d09ccfa93b5"


  OTP_EXPIRY_TIME = 5.minutes
  OTP_RESEND_COOLDOWN = 60.seconds
  MAX_OTP_ATTEMPTS = 5
  BACKUP_CODES_COUNT = 10

  def otp_session_token
    encryptor = ActiveSupport::MessageEncryptor.new(Rails.application.secret_key_base.byteslice(0..31))
    encryptor.encrypt_and_sign(id.to_s)
  end

  def self.decrypt_otp_session_token(token)
    encryptor = ActiveSupport::MessageEncryptor.new(Rails.application.secret_key_base.byteslice(0..31))
    id = encryptor.decrypt_and_verify(token)
    find_by(id: id)
  rescue ActiveSupport::MessageVerifier::InvalidSignature
    nil
  end

  def two_factor_enabled?
    otp_required_for_login?
  end


  def otp_provisioning_uri
    issuer = Rails.application.class.module_parent_name
    label = "#{issuer}:#{email}"
    ROTP::TOTP.new(otp_secret, issuer: issuer).provisioning_uri(label)
  end

  def enable_two_factor!
    self.otp_secret = User.generate_otp_secret unless otp_secret.present?
    self.otp_required_for_login = true
    save!
  end

  def disable_two_factor!
    update!(
      otp_required_for_login: false,
      otp_secret: nil,
      otp_backup_codes: nil,
      backup_codes_digest: nil
    )
  end

  def generate_backup_codes!
    codes = generate_otp_backup_codes!
    save!
    codes
  end

  # Verify TOTP code from authenticator app
  def verify_totp_code(code)
    return false if otp_secret.blank?

    totp = ROTP::TOTP.new(otp_secret)
    totp.verify(code, drift_behind: 30)
  end

  # Regenerate backup codes
  def regenerate_backup_codes!
    codes = Array.new(10) { SecureRandom.hex(5).upcase }
    self.otp_backup_codes = codes.map { |c| Digest::SHA256.hexdigest(c) }
    save!
    codes
  end

  def verify_backup_code(code)
    return false if backup_codes_digest.blank?
    return false if code.blank?

    matched_digest = backup_codes_digest.find do |digest|
      BCrypt::Password.new(digest) == code
    end

    return false unless matched_digest

    backup_codes_digest.delete(matched_digest)
    update_column(:backup_codes_digest, backup_codes_digest)
    true
  end

  # Generate and send OTP via email
  def generate_and_send_email_otp!
    otp = SecureRandom.random_number(1_000_000).to_s.rjust(6, "0")

    update_columns(
      otp_code_digest: Digest::SHA256.hexdigest(otp),
      otp_sent_at: Time.current,
      otp_attempts: 0
    )

    UserMailer.send_otp(self, otp).deliver_now
    otp
  end

  # Verify email OTP
  def verify_email_otp(code)
    return false if otp_code_digest.blank?
    return false if otp_sent_at.nil?
    return false if otp_sent_at < OTP_EXPIRY_TIME.ago
    return false if otp_attempts >= MAX_OTP_ATTEMPTS

    hashed_code = Digest::SHA256.hexdigest(code)

    if otp_code_digest == hashed_code
      clear_email_otp!
      true
    else
      increment!(:otp_attempts)
      false
    end
  end

  def clear_email_otp!
    update_columns(
      otp_code_digest: nil,
      otp_sent_at: nil,
      otp_attempts: 0
    )
  end

  def can_resend_otp?
    return true if otp_sent_at.nil?
    otp_sent_at < OTP_RESEND_COOLDOWN.ago
  end

  def otp_resend_cooldown_remaining
    return 0 if can_resend_otp?
    (OTP_RESEND_COOLDOWN - (Time.current - otp_sent_at)).to_i
  end

  def email_otp_expired?
    return true if otp_sent_at.nil?
    otp_sent_at < OTP_EXPIRY_TIME.ago
  end

  # Check if max attempts reached
  def email_otp_max_attempts_reached?
    otp_attempts >= MAX_OTP_ATTEMPTS
  end

  def verify_any_otp(code)
    return false if code.blank?

    case code.length
    when 6
      return verify_totp_code(code) if otp_secret.present?

      verify_email_otp(code)
    when 8
      verify_backup_code(code.downcase)
    else
      false
    end
  end
end
