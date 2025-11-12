class Api::V1::AgentsController < Api::V1::BaseController
  before_action :set_agent, only: [:show, :update, :destroy, :update_availability]

  # GET /api/v1/accounts/:account_id/agents
  def index
    @agents = @current_account.account_users
                              .includes(:user)
                              .order(created_at: :desc)

    # Filter by role
    @agents = @agents.where(role: params[:role]) if params[:role].present?

    # Filter by availability
    if params[:availability].present?
      @agents = @agents.where(availability: params[:availability])
    end

    render json: {
      data: @agents.map { |agent| agent_json(agent) }
    }
  end

  # GET /api/v1/accounts/:account_id/agents/:id
  def show
    authorize @agent.user

    # Get agent metrics
    metrics = AgentMetric.where(user_id: @agent.user_id, account_id: @current_account.id)
                        .order(metric_date: :desc)
                        .limit(30)

    # Get current shift
    current_shift = AgentShift.current_shift(@agent.user_id, @current_account.id)

    render json: {
      agent: agent_json(@agent),
      metrics: metrics.map { |m| metric_json(m) },
      current_shift: current_shift ? shift_json(current_shift) : nil
    }
  end

  # POST /api/v1/accounts/:account_id/agents
  def create
    user = User.find_by(email: params[:email])

    if user.nil?
      return render json: { error: 'User not found' }, status: :not_found
    end

    @agent = @current_account.account_users.build(
      user: user,
      role: params[:role] || :agent,
      availability: params[:availability] || :online
    )
    authorize @agent, :create?

    if @agent.save
      render json: { agent: agent_json(@agent) }, status: :created
    else
      render json: { errors: @agent.errors.full_messages }, status: :unprocessable_entity
    end
  end

  # PATCH /api/v1/accounts/:account_id/agents/:id
  def update
    authorize @agent.user

    if @agent.update(agent_params)
      render json: { agent: agent_json(@agent) }
    else
      render json: { errors: @agent.errors.full_messages }, status: :unprocessable_entity
    end
  end

  # DELETE /api/v1/accounts/:account_id/agents/:id
  def destroy
    authorize @agent.user

    @agent.destroy
    render json: { message: 'Agent removed successfully' }
  end

  # POST /api/v1/accounts/:account_id/agents/:id/update_availability
  def update_availability
    authorize @agent.user

    old_availability = @agent.availability
    @agent.update!(availability: params[:availability])

    # Log the availability change
    AgentAvailabilityLog.create!(
      user_id: @agent.user_id,
      account_id: @current_account.id,
      status: params[:availability],
      logged_at: Time.current
    )

    render json: {
      agent: agent_json(@agent),
      message: "Availability updated from #{old_availability} to #{params[:availability]}"
    }
  end

  # GET /api/v1/accounts/:account_id/agents/:id/performance
  def performance
    @agent = @current_account.account_users.find(params[:id])
    authorize @agent.user

    # Date range
    start_date = params[:start_date]&.to_date || 30.days.ago.to_date
    end_date = params[:end_date]&.to_date || Date.today

    # Get conversations handled
    conversations = Conversation.where(
      account_id: @current_account.id,
      assignee_id: @agent.user_id,
      created_at: start_date..end_date
    )

    # Calculate metrics
    total_conversations = conversations.count
    resolved_conversations = conversations.where(status: :resolved).count
    avg_first_response = conversations.where.not(first_reply_created_at: nil)
                                     .average("EXTRACT(EPOCH FROM (first_reply_created_at - created_at))")

    # SLA compliance
    sla_met = 0
    sla_total = 0

    conversations.includes(:applied_sla).each do |conv|
      next unless conv.applied_sla

      sla_total += 1
      sla_met += 1 if conv.applied_sla.sla_status == 'hit'
    end

    sla_compliance_rate = sla_total > 0 ? (sla_met.to_f / sla_total * 100).round(2) : 0

    render json: {
      agent: agent_json(@agent),
      period: { start_date: start_date, end_date: end_date },
      metrics: {
        total_conversations: total_conversations,
        resolved_conversations: resolved_conversations,
        resolution_rate: total_conversations > 0 ? (resolved_conversations.to_f / total_conversations * 100).round(2) : 0,
        avg_first_response_seconds: avg_first_response&.to_i,
        avg_first_response_minutes: avg_first_response ? (avg_first_response / 60).round(2) : nil,
        sla_compliance_rate: sla_compliance_rate,
        sla_met_count: sla_met,
        sla_total_count: sla_total
      }
    }
  end

  private

  def set_agent
    @agent = @current_account.account_users.find(params[:id])
  end

  def agent_params
    params.permit(:role, :availability)
  end

  def agent_json(agent)
    {
      id: agent.id,
      user_id: agent.user_id,
      name: agent.user&.name,
      email: agent.user&.email,
      role: agent.role,
      availability: agent.availability,
      active_at: agent.active_at,
      created_at: agent.created_at,
      updated_at: agent.updated_at
    }
  end

  def metric_json(metric)
    {
      date: metric.metric_date,
      conversations_handled: metric.conversations_handled,
      avg_first_response_time: metric.avg_first_response_time,
      sla_met_count: metric.sla_met_count,
      online_duration: metric.online_duration
    }
  end

  def shift_json(shift)
    {
      id: shift.id,
      shift_start: shift.shift_start,
      shift_end: shift.shift_end,
      day_of_week: shift.day_of_week,
      timezone: shift.timezone
    }
  end
end
