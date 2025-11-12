class Api::V1::ConversationsController < Api::V1::BaseController
  before_action :set_conversation, only: [:show, :update, :assign_agent, :resolve, :reopen, :update_priority]

  # GET /api/v1/accounts/:account_id/conversations
  # Unified inbox - shows all conversations across all platforms
  def index
    @conversations = @current_account.conversations
                                     .includes(:inbox, :contact, :assignee, :messages)
                                     .order(updated_at: :desc)

    # Filter by status
    @conversations = @conversations.where(status: params[:status]) if params[:status].present?

    # Filter by inbox (channel)
    @conversations = @conversations.where(inbox_id: params[:inbox_id]) if params[:inbox_id].present?

    # Filter by assignee
    @conversations = @conversations.where(assignee_id: params[:assignee_id]) if params[:assignee_id].present?

    # Filter by team
    @conversations = @conversations.where(team_id: params[:team_id]) if params[:team_id].present?

    # Filter by priority
    @conversations = @conversations.where(priority: params[:priority]) if params[:priority].present?

    # Search by contact name or phone
    if params[:q].present?
      @conversations = @conversations.joins(:contact)
                                     .where("contacts.name ILIKE ? OR contacts.phone_number ILIKE ?",
                                            "%#{params[:q]}%", "%#{params[:q]}%")
    end

    # Pagination
    @conversations = @conversations.page(pagination_params[:page])
                                   .per(pagination_params[:per_page])

    render_collection(@conversations)
  end

  # GET /api/v1/accounts/:account_id/conversations/:id
  def show
    authorize @conversation

    # Load all messages for this conversation
    messages = @conversation.messages.order(created_at: :asc)

    render json: {
      conversation: conversation_json(@conversation),
      messages: messages.map { |m| message_json(m) },
      contact: contact_json(@conversation.contact)
    }
  end

  # POST /api/v1/accounts/:account_id/conversations
  def create
    @conversation = @current_account.conversations.new(conversation_params)
    authorize @conversation

    if @conversation.save
      render json: { conversation: conversation_json(@conversation) }, status: :created
    else
      render json: { errors: @conversation.errors.full_messages }, status: :unprocessable_entity
    end
  end

  # PATCH /api/v1/accounts/:account_id/conversations/:id
  def update
    authorize @conversation

    if @conversation.update(conversation_params)
      render json: { conversation: conversation_json(@conversation) }
    else
      render json: { errors: @conversation.errors.full_messages }, status: :unprocessable_entity
    end
  end

  # POST /api/v1/accounts/:account_id/conversations/:id/assign_agent
  def assign_agent
    authorize @conversation

    agent = @current_account.account_users.find_by(user_id: params[:user_id])

    if agent.nil?
      return render json: { error: 'Agent not found' }, status: :not_found
    end

    @conversation.assignee = agent.user
    @conversation.save!

    render json: {
      conversation: conversation_json(@conversation),
      message: 'Agent assigned successfully'
    }
  end

  # POST /api/v1/accounts/:account_id/conversations/:id/resolve
  def resolve
    authorize @conversation

    @conversation.status = :resolved
    @conversation.save!

    render json: {
      conversation: conversation_json(@conversation),
      message: 'Conversation resolved'
    }
  end

  # POST /api/v1/accounts/:account_id/conversations/:id/reopen
  def reopen
    authorize @conversation

    @conversation.status = :open
    @conversation.save!

    render json: {
      conversation: conversation_json(@conversation),
      message: 'Conversation reopened'
    }
  end

  # POST /api/v1/accounts/:account_id/conversations/:id/update_priority
  def update_priority
    authorize @conversation

    @conversation.priority = params[:priority]
    @conversation.save!

    render json: {
      conversation: conversation_json(@conversation),
      message: 'Priority updated'
    }
  end

  private

  def set_conversation
    @conversation = @current_account.conversations.find(params[:id])
  end

  def conversation_params
    params.require(:conversation).permit(
      :inbox_id, :contact_id, :assignee_id, :team_id,
      :status, :priority, :additional_attributes
    )
  end

  def conversation_json(conversation)
    {
      id: conversation.id,
      status: conversation.status,
      priority: conversation.priority,
      inbox_id: conversation.inbox_id,
      inbox_name: conversation.inbox&.name,
      channel_type: conversation.inbox&.channel_type,
      contact_id: conversation.contact_id,
      contact_name: conversation.contact&.name,
      assignee_id: conversation.assignee_id,
      assignee_name: conversation.assignee&.name,
      team_id: conversation.team_id,
      team_name: conversation.team&.name,
      unread_count: conversation.unread_incoming_messages&.count || 0,
      first_reply_created_at: conversation.first_reply_created_at,
      waiting_since: conversation.waiting_since,
      created_at: conversation.created_at,
      updated_at: conversation.updated_at,
      last_message: conversation.messages.last&.content
    }
  end

  def message_json(message)
    {
      id: message.id,
      content: message.content,
      message_type: message.message_type,
      content_type: message.content_type,
      sender_type: message.sender_type,
      sender_id: message.sender_id,
      created_at: message.created_at,
      attachments: message.attachments
    }
  end

  def contact_json(contact)
    {
      id: contact.id,
      name: contact.name,
      email: contact.email,
      phone_number: contact.phone_number,
      avatar_url: contact.avatar_url,
      custom_attributes: contact.custom_attributes
    }
  end
end
