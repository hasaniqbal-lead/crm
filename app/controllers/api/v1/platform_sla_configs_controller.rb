class Api::V1::PlatformSlaConfigsController < Api::V1::BaseController
  before_action :set_config, only: [:show, :update, :destroy, :toggle]

  # GET /api/v1/accounts/:account_id/platform_sla_configs
  def index
    @configs = PlatformSlaConfig.where(account_id: @current_account.id)
                                .order(:channel_type)

    render json: {
      data: @configs.map { |config| config_json(config) }
    }
  end

  # GET /api/v1/accounts/:account_id/platform_sla_configs/:id
  def show
    authorize @config

    render json: {
      config: config_json(@config)
    }
  end

  # POST /api/v1/accounts/:account_id/platform_sla_configs
  def create
    @config = PlatformSlaConfig.new(config_params)
    @config.account_id = @current_account.id
    authorize @config

    if @config.save
      render json: { config: config_json(@config) }, status: :created
    else
      render json: { errors: @config.errors.full_messages }, status: :unprocessable_entity
    end
  end

  # PATCH /api/v1/accounts/:account_id/platform_sla_configs/:id
  def update
    authorize @config

    if @config.update(config_params)
      render json: { config: config_json(@config) }
    else
      render json: { errors: @config.errors.full_messages }, status: :unprocessable_entity
    end
  end

  # DELETE /api/v1/accounts/:account_id/platform_sla_configs/:id
  def destroy
    authorize @config

    @config.destroy
    render json: { message: 'Platform SLA config deleted successfully' }
  end

  # POST /api/v1/accounts/:account_id/platform_sla_configs/:id/toggle
  def toggle
    authorize @config

    @config.update!(enabled: !@config.enabled)

    render json: {
      config: config_json(@config),
      message: "Platform SLA config #{@config.enabled ? 'enabled' : 'disabled'}"
    }
  end

  # GET /api/v1/accounts/:account_id/platform_sla_configs/by_channel/:channel_type
  def by_channel
    channel_type = params[:channel_type]

    @config = PlatformSlaConfig.find_by(
      account_id: @current_account.id,
      channel_type: channel_type
    )

    if @config
      render json: { config: config_json(@config) }
    else
      render json: {
        message: 'No SLA config found for this channel type',
        channel_type: channel_type
      }, status: :not_found
    end
  end

  private

  def set_config
    @config = PlatformSlaConfig.find(params[:id])
  end

  def config_params
    params.require(:platform_sla_config).permit(
      :channel_type, :first_response_minutes, :resolution_hours,
      :enabled, :additional_config
    )
  end

  def config_json(config)
    {
      id: config.id,
      channel_type: config.channel_type,
      channel_name: channel_type_name(config.channel_type),
      first_response_minutes: config.first_response_minutes,
      resolution_hours: config.resolution_hours,
      enabled: config.enabled,
      additional_config: config.additional_config,
      created_at: config.created_at,
      updated_at: config.updated_at
    }
  end

  def channel_type_name(channel_type)
    case channel_type
    when 'Channel::Whatsapp'
      'WhatsApp'
    when 'Channel::FacebookPage'
      'Facebook Messenger'
    when 'Channel::Instagram'
      'Instagram DM'
    else
      channel_type
    end
  end
end
