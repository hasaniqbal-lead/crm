class Api::V1::SlaPoliciesController < Api::V1::BaseController
  before_action :set_sla_policy, only: [:show, :update, :destroy]

  # GET /api/v1/accounts/:account_id/sla_policies
  def index
    @sla_policies = @current_account.sla_policies
                                    .order(created_at: :desc)

    render json: {
      data: @sla_policies.map { |sla| sla_policy_json(sla) }
    }
  end

  # GET /api/v1/accounts/:account_id/sla_policies/:id
  def show
    authorize @sla_policy

    # Get applied SLAs count
    applied_count = AppliedSla.where(sla_policy_id: @sla_policy.id).count
    sla_met_count = AppliedSla.where(sla_policy_id: @sla_policy.id, sla_status: 'hit').count

    render json: {
      sla_policy: sla_policy_json(@sla_policy),
      stats: {
        applied_count: applied_count,
        sla_met_count: sla_met_count,
        compliance_rate: applied_count > 0 ? (sla_met_count.to_f / applied_count * 100).round(2) : 0
      }
    }
  end

  # POST /api/v1/accounts/:account_id/sla_policies
  def create
    @sla_policy = @current_account.sla_policies.build(sla_policy_params)
    authorize @sla_policy

    if @sla_policy.save
      render json: { sla_policy: sla_policy_json(@sla_policy) }, status: :created
    else
      render json: { errors: @sla_policy.errors.full_messages }, status: :unprocessable_entity
    end
  end

  # PATCH /api/v1/accounts/:account_id/sla_policies/:id
  def update
    authorize @sla_policy

    if @sla_policy.update(sla_policy_params)
      render json: { sla_policy: sla_policy_json(@sla_policy) }
    else
      render json: { errors: @sla_policy.errors.full_messages }, status: :unprocessable_entity
    end
  end

  # DELETE /api/v1/accounts/:account_id/sla_policies/:id
  def destroy
    authorize @sla_policy

    # Check if SLA is applied to any conversations
    if @sla_policy.applied_slas.exists?
      return render json: {
        error: 'Cannot delete SLA policy that has been applied to conversations'
      }, status: :unprocessable_entity
    end

    @sla_policy.destroy
    render json: { message: 'SLA policy deleted successfully' }
  end

  # GET /api/v1/accounts/:account_id/sla_policies/compliance_report
  def compliance_report
    # Date range
    start_date = params[:start_date]&.to_date || 30.days.ago.to_date
    end_date = params[:end_date]&.to_date || Date.today

    applied_slas = AppliedSla.joins(:conversation)
                             .where(conversations: { account_id: @current_account.id })
                             .where(created_at: start_date..end_date)

    total_count = applied_slas.count
    hit_count = applied_slas.where(sla_status: 'hit').count
    missed_count = applied_slas.where(sla_status: 'missed').count

    # Group by SLA policy
    by_policy = @current_account.sla_policies.map do |policy|
      policy_applied = applied_slas.where(sla_policy_id: policy.id)
      policy_total = policy_applied.count
      policy_hit = policy_applied.where(sla_status: 'hit').count

      {
        policy_id: policy.id,
        policy_name: policy.name,
        total: policy_total,
        hit: policy_hit,
        missed: policy_total - policy_hit,
        compliance_rate: policy_total > 0 ? (policy_hit.to_f / policy_total * 100).round(2) : 0
      }
    end

    # Group by inbox/channel
    by_inbox = Inbox.where(account_id: @current_account.id).map do |inbox|
      inbox_conversations = Conversation.where(inbox_id: inbox.id, created_at: start_date..end_date)
      inbox_applied = AppliedSla.where(conversation_id: inbox_conversations.pluck(:id))
      inbox_total = inbox_applied.count
      inbox_hit = inbox_applied.where(sla_status: 'hit').count

      {
        inbox_id: inbox.id,
        inbox_name: inbox.name,
        channel_type: inbox.channel_type,
        total: inbox_total,
        hit: inbox_hit,
        missed: inbox_total - inbox_hit,
        compliance_rate: inbox_total > 0 ? (inbox_hit.to_f / inbox_total * 100).round(2) : 0
      }
    end

    render json: {
      period: { start_date: start_date, end_date: end_date },
      overall: {
        total: total_count,
        hit: hit_count,
        missed: missed_count,
        compliance_rate: total_count > 0 ? (hit_count.to_f / total_count * 100).round(2) : 0
      },
      by_policy: by_policy,
      by_inbox: by_inbox
    }
  end

  private

  def set_sla_policy
    @sla_policy = @current_account.sla_policies.find(params[:id])
  end

  def sla_policy_params
    params.require(:sla_policy).permit(
      :name, :description, :first_response_time_threshold,
      :next_response_time_threshold, :resolution_time_threshold,
      :only_during_business_hours
    )
  end

  def sla_policy_json(sla)
    {
      id: sla.id,
      name: sla.name,
      description: sla.description,
      first_response_time_threshold: sla.first_response_time_threshold,
      next_response_time_threshold: sla.next_response_time_threshold,
      resolution_time_threshold: sla.resolution_time_threshold,
      only_during_business_hours: sla.only_during_business_hours,
      created_at: sla.created_at,
      updated_at: sla.updated_at
    }
  end
end
