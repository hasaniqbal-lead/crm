class Api::V1::Auth::SessionsController < ApplicationController
  include ExceptionHandler

  # POST /api/v1/auth/login
  # @param email [String] User email
  # @param password [String] User password
  # @return [JSON] User info, access token, refresh token
  def create
    user = User.find_by(email: params[:email])

    unless user&.valid_password?(params[:password])
      return render json: {
        error: 'Invalid credentials',
        message: 'The email or password you entered is incorrect'
      }, status: :unauthorized
    end

    # Generate tokens
    access_token = JsonWebToken.access_token(user.id)
    refresh_token = JsonWebToken.refresh_token(user.id)

    # Get user's accounts
    accounts = user.account_users.includes(:account).map do |au|
      {
        id: au.account_id,
        name: au.account.name,
        role: au.role,
        availability: au.availability
      }
    end

    render json: {
      user: user_json(user),
      accounts: accounts,
      tokens: {
        access_token: access_token,
        refresh_token: refresh_token,
        token_type: 'Bearer',
        expires_in: 24.hours.to_i
      },
      message: 'Login successful'
    }
  end

  # POST /api/v1/auth/refresh
  # @param refresh_token [String] Refresh token
  # @return [JSON] New access token
  def refresh
    token = params[:refresh_token]

    unless token
      return render json: {
        error: 'Missing refresh token'
      }, status: :bad_request
    end

    begin
      decoded = JsonWebToken.decode(token)

      unless decoded[:type] == 'refresh'
        return render json: {
          error: 'Invalid token type'
        }, status: :unauthorized
      end

      user = User.find_by(id: decoded[:user_id])

      unless user
        return render json: {
          error: 'User not found'
        }, status: :unauthorized
      end

      # Generate new access token
      access_token = JsonWebToken.access_token(user.id)

      render json: {
        tokens: {
          access_token: access_token,
          token_type: 'Bearer',
          expires_in: 24.hours.to_i
        },
        message: 'Token refreshed successfully'
      }
    rescue => e
      render json: {
        error: 'Invalid or expired refresh token',
        message: e.message
      }, status: :unauthorized
    end
  end

  # DELETE /api/v1/auth/logout
  # Note: JWT is stateless, so logout is handled client-side by removing token
  # For enhanced security, you could implement a token blacklist in Redis
  def destroy
    render json: {
      message: 'Logout successful. Please remove the token from client storage.'
    }
  end

  private

  def user_json(user)
    {
      id: user.id,
      name: user.name,
      email: user.email,
      display_name: user.display_name,
      avatar_url: user.avatar_url,
      created_at: user.created_at
    }
  end
end
