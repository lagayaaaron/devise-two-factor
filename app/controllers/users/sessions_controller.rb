class Users::SessionsController < Devise::SessionsController
  skip_before_action :verify_authenticity_token, only: [ :create ], if: -> { request.format.json? }

  def create
    email = params.dig(:user, :email) || params[:email]
    password = params.dig(:user, :password) || params[:password]

    user = User.find_by(email: email)

    if user&.valid_password?(password)
      if user.otp_required_for_login?
        user.generate_and_send_email_otp!

        session[:otp_user_token] = user.otp_session_token
        session[:otp_timestamp] = Time.current.to_i
        session[:otp_failed_attempts] = 0

        redirect_to new_users_otp_challenge_path
      else
        sign_in(user)
        redirect_to after_sign_in_path_for(user), notice: "Signed in successfully."
      end
    else
      flash.now[:alert] = "Invalid email or password."
      self.resource = User.new
      render :new, status: :unprocessable_entity
    end
  end
end
