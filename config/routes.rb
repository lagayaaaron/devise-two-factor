# config/routes.rb
Rails.application.routes.draw do
  devise_for :users, controllers: {
    sessions: "users/sessions"
  }

  mount LetterOpenerWeb::Engine, at: "/letter_opener" if Rails.env.development?

  namespace :users do
    # OTP Challenge routes
    resource :otp_challenge, only: [ :new, :create ] do
      post :cancel, on: :collection
    end

    # Two-Factor Settings routes
    resource :two_factor_settings, only: [ :show, :create, :update, :destroy ] do
      post :regenerate_codes, on: :collection
      post :enable, on: :collection
      get :backup_codes, on: :collection
      patch :verify
      delete :disable
      post :resend, on: :collection
    end
  end

  root "home#index"
end
