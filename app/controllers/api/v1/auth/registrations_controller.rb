class Api::V1::Auth::RegistrationsController < ApplicationController
  include ExceptionHandler

  # POST /api/v1/auth/signup
  # @param name [String] User full name
  # @param email [String] User email
  # @param password [String] Password (min 6 characters)
  # @param password_confirmation [String] Password confirmation
  # @param account_name [String] Optional - Create account during signup
  # @return [JSON] User info, access token, refresh token
  def create
    user = User.new(user_params)

    if user.save
      # Create default account if account_name provided
      account = nil
      if params[:account_name].present?
        account = Account.create!(
          name: params[:account_name],
          settings: {},
          limits: {}
        )

        # Add user as administrator
        AccountUser.create!(
          account: account,
          user: user,
          role: :administrator,
          availability: :online
        )
      end

      # Generate tokens
      access_token = JsonWebToken.access_token(user.id)
      refresh_token = JsonWebToken.refresh_token(user.id)

      render json: {
        user: user_json(user),
        account: account ? account_json(account) : nil,
        tokens: {
          access_token: access_token,
          refresh_token: refresh_token,
          token_type: 'Bearer',
          expires_in: 24.hours.to_i
        },
        message: 'Registration successful'
      }, status: :created
    else
      render json: {
        error: 'Registration failed',
        errors: user.errors.full_messages
      }, status: :unprocessable_entity
    end
  rescue ActiveRecord::RecordInvalid => e
    render json: {
      error: 'Registration failed',
      errors: e.record.errors.full_messages
    }, status: :unprocessable_entity
  end

  private

  def user_params
    params.require(:user).permit(:name, :email, :password, :password_confirmation, :display_name)
  end

  def user_json(user)
    {
      id: user.id,
      name: user.name,
      email: user.email,
      display_name: user.display_name,
      created_at: user.created_at
    }
  end

  def account_json(account)
    {
      id: account.id,
      name: account.name,
      created_at: account.created_at
    }
  end
end
