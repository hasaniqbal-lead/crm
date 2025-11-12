class Api::V1::BaseController < ApplicationController
  include ExceptionHandler
  include Authorize
  include Pundit::Authorization

  before_action :set_current_account

  private

  def set_current_account
    account_id = params[:account_id]

    if account_id.present?
      @current_account = current_user.accounts.find(account_id)
    else
      @current_account = current_user.accounts.first
    end

    raise ActiveRecord::RecordNotFound, 'Account not found or access denied' unless @current_account
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
