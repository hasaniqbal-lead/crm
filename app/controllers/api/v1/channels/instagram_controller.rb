class Api::V1::Channels::InstagramController < Api::V1::BaseController
  before_action :set_channel, only: [:show, :update, :destroy, :refresh_token]

  # GET /api/v1/accounts/:account_id/channels/instagram
  def index
    @channels = Channel::Instagram.joins(:inbox)
                                  .where(inboxes: { account_id: @current_account.id })

    render json: {
      data: @channels.map { |channel| channel_json(channel) }
    }
  end

  # GET /api/v1/accounts/:account_id/channels/instagram/:id
  def show
    authorize @channel

    render json: {
      channel: channel_json(@channel),
      inbox: @channel.inbox ? inbox_summary_json(@channel.inbox) : nil,
      token_expires_at: @channel.token_expires_at,
      token_expired: @channel.token_expires_at && @channel.token_expires_at < Time.current
    }
  end

  # POST /api/v1/accounts/:account_id/channels/instagram
  def create
    @channel = Channel::Instagram.new(channel_params)
    authorize @channel

    ActiveRecord::Base.transaction do
      @channel.save!

      # Create associated inbox
      inbox = @current_account.inboxes.create!(
        name: "Instagram: @#{@channel.username}",
        channel: @channel
      )

      render json: {
        channel: channel_json(@channel),
        inbox: inbox_summary_json(inbox)
      }, status: :created
    end
  rescue ActiveRecord::RecordInvalid => e
    render json: { errors: e.record.errors.full_messages }, status: :unprocessable_entity
  end

  # PATCH /api/v1/accounts/:account_id/channels/instagram/:id
  def update
    authorize @channel

    if @channel.update(channel_params)
      render json: { channel: channel_json(@channel) }
    else
      render json: { errors: @channel.errors.full_messages }, status: :unprocessable_entity
    end
  end

  # DELETE /api/v1/accounts/:account_id/channels/instagram/:id
  def destroy
    authorize @channel

    @channel.inbox&.destroy # This will cascade delete the channel
    render json: { message: 'Instagram channel deleted successfully' }
  end

  # POST /api/v1/accounts/:account_id/channels/instagram/:id/refresh_token
  def refresh_token
    authorize @channel

    begin
      Instagram::RefreshOauthTokenService.new(channel: @channel).perform

      render json: {
        channel: channel_json(@channel),
        message: 'Token refreshed successfully',
        new_expiry: @channel.reload.token_expires_at
      }
    rescue StandardError => e
      render json: {
        error: 'Token refresh failed',
        message: e.message
      }, status: :unprocessable_entity
    end
  end

  private

  def set_channel
    @channel = Channel::Instagram.joins(:inbox)
                                 .where(inboxes: { account_id: @current_account.id })
                                 .find(params[:id])
  end

  def channel_params
    params.require(:channel).permit(
      :instagram_id, :username, :access_token, :token_expires_at
    )
  end

  def channel_json(channel)
    {
      id: channel.id,
      instagram_id: channel.instagram_id,
      username: channel.username,
      token_expires_at: channel.token_expires_at,
      created_at: channel.created_at,
      updated_at: channel.updated_at
    }
  end

  def inbox_summary_json(inbox)
    {
      id: inbox.id,
      name: inbox.name,
      account_id: inbox.account_id
    }
  end
end
