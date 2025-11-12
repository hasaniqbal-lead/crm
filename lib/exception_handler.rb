# Exception handler module for JWT and API errors
module ExceptionHandler
  extend ActiveSupport::Concern

  # Custom error classes
  class AuthenticationError < StandardError; end
  class MissingToken < StandardError; end
  class InvalidToken < StandardError; end
  class ExpiredSignature < StandardError; end

  included do
    # Handle authentication errors
    rescue_from ExceptionHandler::AuthenticationError, with: :unauthorized_request
    rescue_from ExceptionHandler::MissingToken, with: :unauthorized_request
    rescue_from ExceptionHandler::InvalidToken, with: :unauthorized_request
    rescue_from ExceptionHandler::ExpiredSignature, with: :token_expired

    rescue_from ActiveRecord::RecordNotFound, with: :not_found
    rescue_from ActiveRecord::RecordInvalid, with: :unprocessable_entity
    rescue_from Pundit::NotAuthorizedError, with: :forbidden
  end

  private

  # JSON response with message; Status code 401 - Unauthorized
  def unauthorized_request(exception)
    render json: {
      error: 'Unauthorized',
      message: exception.message
    }, status: :unauthorized
  end

  # JSON response with message; Status code 401 - Token expired
  def token_expired(_exception)
    render json: {
      error: 'Token Expired',
      message: 'Your session has expired. Please login again.'
    }, status: :unauthorized
  end

  # JSON response with message; Status code 404 - Not found
  def not_found(exception)
    render json: {
      error: 'Not Found',
      message: exception.message
    }, status: :not_found
  end

  # JSON response with message; Status code 422 - Unprocessable entity
  def unprocessable_entity(exception)
    render json: {
      error: 'Unprocessable Entity',
      message: exception.record.errors.full_messages
    }, status: :unprocessable_entity
  end

  # JSON response with message; Status code 403 - Forbidden
  def forbidden(_exception)
    render json: {
      error: 'Forbidden',
      message: 'You are not authorized to perform this action'
    }, status: :forbidden
  end
end
