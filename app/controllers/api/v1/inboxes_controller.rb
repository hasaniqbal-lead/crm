class Api::V1::InboxesController < Api::V1::BaseController
  before_action :set_inbox, only: [:show, :update, :destroy]

  # GET /api/v1/accounts/:account_id/inboxes
  def index
    @inboxes = @current_account.inboxes
                               .includes(:channel)
                               .order(created_at: :desc)

    render json: {
      data: @inboxes.map { |inbox| inbox_json(inbox) }
    }
  end

  # GET /api/v1/accounts/:account_id/inboxes/:id
  def show
    authorize @inbox

    render json: {
      inbox: inbox_json(@inbox),
      channel: channel_json(@inbox.channel),
      members: @inbox.inbox_members.map { |m| inbox_member_json(m) }
    }
  end

  # POST /api/v1/accounts/:account_id/inboxes
  # Generic inbox creation - specific channels created via their own endpoints
  def create
    @inbox = @current_account.inboxes.build(inbox_params)
    authorize @inbox

    if @inbox.save
      render json: { inbox: inbox_json(@inbox) }, status: :created
    else
      render json: { errors: @inbox.errors.full_messages }, status: :unprocessable_entity
    end
  end

  # PATCH /api/v1/accounts/:account_id/inboxes/:id
  def update
    authorize @inbox

    if @inbox.update(inbox_params)
      render json: { inbox: inbox_json(@inbox) }
    else
      render json: { errors: @inbox.errors.full_messages }, status: :unprocessable_entity
    end
  end

  # DELETE /api/v1/accounts/:account_id/inboxes/:id
  def destroy
    authorize @inbox

    @inbox.destroy
    render json: { message: 'Inbox deleted successfully' }
  end

  # POST /api/v1/accounts/:account_id/inboxes/:id/add_member
  def add_member
    @inbox = @current_account.inboxes.find(params[:id])
    authorize @inbox

    user = @current_account.users.find(params[:user_id])

    inbox_member = @inbox.inbox_members.create!(user: user)

    render json: {
      message: 'Member added successfully',
      member: inbox_member_json(inbox_member)
    }
  rescue ActiveRecord::RecordInvalid => e
    render json: { errors: e.record.errors.full_messages }, status: :unprocessable_entity
  end

  # DELETE /api/v1/accounts/:account_id/inboxes/:id/remove_member
  def remove_member
    @inbox = @current_account.inboxes.find(params[:id])
    authorize @inbox

    inbox_member = @inbox.inbox_members.find_by!(user_id: params[:user_id])
    inbox_member.destroy

    render json: { message: 'Member removed successfully' }
  end

  private

  def set_inbox
    @inbox = @current_account.inboxes.find(params[:id])
  end

  def inbox_params
    params.require(:inbox).permit(
      :name, :greeting_enabled, :greeting_message,
      :enable_auto_assignment, :working_hours_enabled,
      :out_of_office_message, :timezone
    )
  end

  def inbox_json(inbox)
    {
      id: inbox.id,
      name: inbox.name,
      channel_type: inbox.channel_type,
      channel_id: inbox.channel_id,
      greeting_enabled: inbox.greeting_enabled,
      greeting_message: inbox.greeting_message,
      enable_auto_assignment: inbox.enable_auto_assignment,
      working_hours_enabled: inbox.working_hours_enabled,
      out_of_office_message: inbox.out_of_office_message,
      timezone: inbox.timezone,
      created_at: inbox.created_at,
      updated_at: inbox.updated_at
    }
  end

  def channel_json(channel)
    return nil unless channel

    case channel
    when Channel::Whatsapp
      {
        type: 'whatsapp',
        phone_number: channel.phone_number,
        provider: channel.provider
      }
    when Channel::FacebookPage
      {
        type: 'facebook',
        page_id: channel.page_id,
        page_name: channel.name
      }
    when Channel::Instagram
      {
        type: 'instagram',
        instagram_id: channel.instagram_id,
        username: channel.username
      }
    else
      { type: 'unknown' }
    end
  end

  def inbox_member_json(member)
    {
      id: member.id,
      user_id: member.user_id,
      user_name: member.user&.name,
      user_email: member.user&.email,
      created_at: member.created_at
    }
  end
end
