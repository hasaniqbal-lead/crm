class Api::V1::BaseController < ApplicationController
  include Pundit::Authorization

  before_action :authenticate_user!
  before_action :set_current_account

  rescue_from ActiveRecord::RecordNotFound, with: :record_not_found
  rescue_from ActiveRecord::RecordInvalid, with: :record_invalid
  rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized

  private

  def set_current_account
    @current_account = Account.find(params[:account_id]) if params[:account_id]
    authorize @current_account if @current_account
  end

  def current_user
    # Override with Devise token auth
    @current_user
  end

  def authenticate_user!
    # TODO: Implement JWT/Devise token authentication
    # For now, this is a placeholder
    head :unauthorized unless current_user
  end

  def record_not_found(exception)
    render json: {
      error: 'Record not found',
      message: exception.message
    }, status: :not_found
  end

  def record_invalid(exception)
    render json: {
      error: 'Validation failed',
      errors: exception.record.errors.full_messages
    }, status: :unprocessable_entity
  end

  def user_not_authorized
    render json: {
      error: 'Unauthorized',
      message: 'You are not authorized to perform this action'
    }, status: :forbidden
  end

  def pagination_params
    {
      page: params[:page] || 1,
      per_page: [params[:per_page]&.to_i || 25, 100].min
    }
  end

  def render_collection(collection, serializer: nil)
    render json: {
      data: collection,
      meta: {
        current_page: collection.current_page,
        total_pages: collection.total_pages,
        total_count: collection.total_count,
        per_page: collection.limit_value
      }
    }
  end
end
