# Authorization module for JWT token validation
module Authorize
  extend ActiveSupport::Concern

  included do
    before_action :authorize_request
  end

  private

  # Authorize request by validating JWT token
  def authorize_request
    @current_user = user_from_token
    raise ExceptionHandler::AuthenticationError, 'Invalid credentials' unless @current_user
  end

  # Extract user from JWT token
  def user_from_token
    @user_from_token ||= begin
      token = request_token
      raise ExceptionHandler::MissingToken, 'Missing token' unless token

      decoded = JsonWebToken.decode(token)
      User.find_by(id: decoded[:user_id])
    end
  end

  # Extract token from Authorization header
  def request_token
    @request_token ||= begin
      header = request.headers['Authorization']
      header&.split(' ')&.last
    end
  end

  # Current authenticated user
  def current_user
    @current_user
  end

  # Check if user is authenticated
  def user_signed_in?
    current_user.present?
  end
end
