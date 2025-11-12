class Api::V1::Channels::WhatsappController < Api::V1::BaseController
  before_action :set_channel, only: [:show, :update, :destroy]

  # GET /api/v1/accounts/:account_id/channels/whatsapp
  def index
    @channels = Channel::Whatsapp.joins(:inbox)
                                 .where(inboxes: { account_id: @current_account.id })

    render json: {
      data: @channels.map { |channel| channel_json(channel) }
    }
  end

  # GET /api/v1/accounts/:account_id/channels/whatsapp/:id
  def show
    authorize @channel

    render json: {
      channel: channel_json(@channel),
      inbox: @channel.inbox ? inbox_summary_json(@channel.inbox) : nil
    }
  end

  # POST /api/v1/accounts/:account_id/channels/whatsapp
  def create
    @channel = Channel::Whatsapp.new(channel_params)
    authorize @channel

    ActiveRecord::Base.transaction do
      @channel.save!

      # Create associated inbox
      inbox = @current_account.inboxes.create!(
        name: "WhatsApp: #{@channel.phone_number}",
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

  # PATCH /api/v1/accounts/:account_id/channels/whatsapp/:id
  def update
    authorize @channel

    if @channel.update(channel_params)
      render json: { channel: channel_json(@channel) }
    else
      render json: { errors: @channel.errors.full_messages }, status: :unprocessable_entity
    end
  end

  # DELETE /api/v1/accounts/:account_id/channels/whatsapp/:id
  def destroy
    authorize @channel

    @channel.inbox&.destroy # This will cascade delete the channel
    render json: { message: 'WhatsApp channel deleted successfully' }
  end

  private

  def set_channel
    @channel = Channel::Whatsapp.joins(:inbox)
                                .where(inboxes: { account_id: @current_account.id })
                                .find(params[:id])
  end

  def channel_params
    params.require(:channel).permit(
      :phone_number, :provider, :provider_config, :message_templates_last_updated
    )
  end

  def channel_json(channel)
    {
      id: channel.id,
      phone_number: channel.phone_number,
      provider: channel.provider,
      provider_config: channel.provider_config,
      message_templates_last_updated: channel.message_templates_last_updated,
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
