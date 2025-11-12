class Api::V1::ContactsController < Api::V1::BaseController
  before_action :set_contact, only: [:show, :update, :destroy, :conversations]

  # GET /api/v1/accounts/:account_id/contacts
  def index
    @contacts = @current_account.contacts
                                .order(created_at: :desc)

    # Search by name, email, or phone
    if params[:q].present?
      @contacts = @contacts.where(
        "name ILIKE ? OR email ILIKE ? OR phone_number ILIKE ?",
        "%#{params[:q]}%", "%#{params[:q]}%", "%#{params[:q]}%"
      )
    end

    # Pagination
    @contacts = @contacts.page(pagination_params[:page])
                         .per(pagination_params[:per_page])

    render_collection(@contacts)
  end

  # GET /api/v1/accounts/:account_id/contacts/:id
  def show
    authorize @contact

    render json: {
      contact: contact_json(@contact),
      contact_inboxes: @contact.contact_inboxes.map { |ci| contact_inbox_json(ci) }
    }
  end

  # POST /api/v1/accounts/:account_id/contacts
  def create
    @contact = @current_account.contacts.build(contact_params)
    authorize @contact

    if @contact.save
      render json: { contact: contact_json(@contact) }, status: :created
    else
      render json: { errors: @contact.errors.full_messages }, status: :unprocessable_entity
    end
  end

  # PATCH /api/v1/accounts/:account_id/contacts/:id
  def update
    authorize @contact

    if @contact.update(contact_params)
      render json: { contact: contact_json(@contact) }
    else
      render json: { errors: @contact.errors.full_messages }, status: :unprocessable_entity
    end
  end

  # DELETE /api/v1/accounts/:account_id/contacts/:id
  def destroy
    authorize @contact

    @contact.destroy
    render json: { message: 'Contact deleted successfully' }
  end

  # GET /api/v1/accounts/:account_id/contacts/:id/conversations
  def conversations
    authorize @contact

    @conversations = @contact.conversations
                             .includes(:inbox, :assignee, :messages)
                             .order(updated_at: :desc)
                             .page(pagination_params[:page])
                             .per(pagination_params[:per_page])

    render json: {
      data: @conversations.map { |c| conversation_summary_json(c) },
      meta: {
        current_page: @conversations.current_page,
        total_pages: @conversations.total_pages,
        total_count: @conversations.total_count,
        per_page: @conversations.limit_value
      }
    }
  end

  private

  def set_contact
    @contact = @current_account.contacts.find(params[:id])
  end

  def contact_params
    params.require(:contact).permit(
      :name, :email, :phone_number, :avatar_url,
      :identifier, :custom_attributes
    )
  end

  def contact_json(contact)
    {
      id: contact.id,
      name: contact.name,
      email: contact.email,
      phone_number: contact.phone_number,
      avatar_url: contact.avatar_url,
      identifier: contact.identifier,
      custom_attributes: contact.custom_attributes,
      created_at: contact.created_at,
      updated_at: contact.updated_at,
      conversations_count: contact.conversations.count
    }
  end

  def contact_inbox_json(contact_inbox)
    {
      id: contact_inbox.id,
      inbox_id: contact_inbox.inbox_id,
      inbox_name: contact_inbox.inbox&.name,
      source_id: contact_inbox.source_id,
      created_at: contact_inbox.created_at
    }
  end

  def conversation_summary_json(conversation)
    {
      id: conversation.id,
      status: conversation.status,
      inbox_name: conversation.inbox&.name,
      assignee_name: conversation.assignee&.name,
      last_message: conversation.messages.last&.content,
      updated_at: conversation.updated_at
    }
  end
end
