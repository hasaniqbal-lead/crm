class Api::V1::MessagesController < Api::V1::BaseController
  before_action :set_conversation

  # GET /api/v1/accounts/:account_id/conversations/:conversation_id/messages
  def index
    authorize @conversation, :show?

    @messages = @conversation.messages
                             .order(created_at: :asc)
                             .page(pagination_params[:page])
                             .per(pagination_params[:per_page])

    render json: {
      data: @messages.map { |m| message_json(m) },
      meta: {
        current_page: @messages.current_page,
        total_pages: @messages.total_pages,
        total_count: @messages.total_count,
        per_page: @messages.limit_value
      }
    }
  end

  # POST /api/v1/accounts/:account_id/conversations/:conversation_id/messages
  # Send a message on WhatsApp/Facebook/Instagram
  def create
    authorize @conversation, :update?

    @message = @conversation.messages.build(message_params)
    @message.account_id = @current_account.id
    @message.inbox_id = @conversation.inbox_id
    @message.message_type = :outgoing
    @message.sender = current_user

    if @message.save
      # Send via appropriate channel
      send_via_channel(@message)

      render json: {
        message: message_json(@message),
        status: 'Message sent successfully'
      }, status: :created
    else
      render json: { errors: @message.errors.full_messages }, status: :unprocessable_entity
    end
  end

  # GET /api/v1/accounts/:account_id/conversations/:conversation_id/messages/:id
  def show
    authorize @conversation, :show?

    @message = @conversation.messages.find(params[:id])
    render json: { message: message_json(@message) }
  end

  private

  def set_conversation
    @conversation = @current_account.conversations.find(params[:conversation_id])
  end

  def message_params
    params.require(:message).permit(:content, :content_type, :private, attachments: [])
  end

  def send_via_channel(message)
    inbox = @conversation.inbox
    channel = inbox.channel

    case channel
    when Channel::Whatsapp
      Whatsapp::SendOnWhatsappService.new(
        conversation: @conversation,
        message: message
      ).perform
    when Channel::FacebookPage
      Facebook::SendOnFacebookService.new(
        conversation: @conversation,
        message: message
      ).perform
    when Channel::Instagram
      Instagram::SendOnInstagramService.new(
        conversation: @conversation,
        message: message
      ).perform
    else
      Rails.logger.error "Unknown channel type: #{channel.class.name}"
    end
  rescue StandardError => e
    Rails.logger.error "Failed to send message: #{e.message}"
    # Message is already saved, just log the error
    # Frontend can show delivery status
  end

  def message_json(message)
    {
      id: message.id,
      content: message.content,
      message_type: message.message_type,
      content_type: message.content_type,
      sender_type: message.sender_type,
      sender_id: message.sender_id,
      sender_name: message.sender&.name,
      conversation_id: message.conversation_id,
      created_at: message.created_at,
      updated_at: message.updated_at,
      attachments: message.attachments,
      source_id: message.source_id,
      private: message.private
    }
  end
end
