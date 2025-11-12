class Api::V1::Channels::FacebookController < Api::V1::BaseController
  before_action :set_channel, only: [:show, :update, :destroy, :reauthorize]

  # GET /api/v1/accounts/:account_id/channels/facebook
  def index
    @channels = Channel::FacebookPage.joins(:inbox)
                                     .where(inboxes: { account_id: @current_account.id })

    render json: {
      data: @channels.map { |channel| channel_json(channel) }
    }
  end

  # GET /api/v1/accounts/:account_id/channels/facebook/:id
  def show
    authorize @channel

    render json: {
      channel: channel_json(@channel),
      inbox: @channel.inbox ? inbox_summary_json(@channel.inbox) : nil,
      reauthorization_required: @channel.reauthorization_required?
    }
  end

  # POST /api/v1/accounts/:account_id/channels/facebook
  def create
    @channel = Channel::FacebookPage.new(channel_params)
    authorize @channel

    ActiveRecord::Base.transaction do
      @channel.save!

      # Create associated inbox
      inbox = @current_account.inboxes.create!(
        name: "Facebook: #{@channel.name}",
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

  # PATCH /api/v1/accounts/:account_id/channels/facebook/:id
  def update
    authorize @channel

    if @channel.update(channel_params)
      render json: { channel: channel_json(@channel) }
    else
      render json: { errors: @channel.errors.full_messages }, status: :unprocessable_entity
    end
  end

  # DELETE /api/v1/accounts/:account_id/channels/facebook/:id
  def destroy
    authorize @channel

    @channel.inbox&.destroy # This will cascade delete the channel
    render json: { message: 'Facebook channel deleted successfully' }
  end

  # POST /api/v1/accounts/:account_id/channels/facebook/:id/reauthorize
  def reauthorize
    authorize @channel

    # Update page access token
    @channel.update!(
      page_access_token: params[:page_access_token],
      reauthorized_at: Time.current
    )

    render json: {
      channel: channel_json(@channel),
      message: 'Channel reauthorized successfully'
    }
  end

  private

  def set_channel
    @channel = Channel::FacebookPage.joins(:inbox)
                                    .where(inboxes: { account_id: @current_account.id })
                                    .find(params[:id])
  end

  def channel_params
    params.require(:channel).permit(
      :page_id, :name, :page_access_token, :user_access_token, :instagram_id
    )
  end

  def channel_json(channel)
    {
      id: channel.id,
      page_id: channel.page_id,
      name: channel.name,
      instagram_id: channel.instagram_id,
      created_at: channel.created_at,
      updated_at: channel.updated_at,
      reauthorized_at: channel.reauthorized_at
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
