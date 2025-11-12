class Api::V1::Auth::SessionsController < ApplicationController
  # POST /api/v1/auth/login
  def create
    user = User.find_by(email: params[:email])

    if user&.valid_password?(params[:password])
      # TODO: Generate JWT token
      # For now, returning a placeholder
      render json: {
        user: {
          id: user.id,
          name: user.name,
          email: user.email
        },
        token: 'TODO_JWT_TOKEN',
        message: 'Login successful'
      }
    else
      render json: {
        error: 'Invalid credentials'
      }, status: :unauthorized
    end
  end

  # DELETE /api/v1/auth/logout
  def destroy
    # TODO: Invalidate JWT token
    render json: { message: 'Logout successful' }
  end
end
