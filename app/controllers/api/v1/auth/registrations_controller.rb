class Api::V1::Auth::RegistrationsController < ApplicationController
  # POST /api/v1/auth/signup
  def create
    user = User.new(user_params)

    if user.save
      # TODO: Generate JWT token
      render json: {
        user: {
          id: user.id,
          name: user.name,
          email: user.email
        },
        token: 'TODO_JWT_TOKEN',
        message: 'Registration successful'
      }, status: :created
    else
      render json: {
        errors: user.errors.full_messages
      }, status: :unprocessable_entity
    end
  end

  private

  def user_params
    params.require(:user).permit(:name, :email, :password, :password_confirmation)
  end
end
