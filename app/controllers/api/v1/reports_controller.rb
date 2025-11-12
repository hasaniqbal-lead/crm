class Api::V1::ReportsController < Api::V1::BaseController
  # GET /api/v1/accounts/:account_id/reports/overview
  def overview
    start_date = params[:start_date]&.to_date || 30.days.ago.to_date
    end_date = params[:end_date]&.to_date || Date.today

    conversations = @current_account.conversations
                                    .where(created_at: start_date..end_date)

    total_conversations = conversations.count
    resolved_conversations = conversations.where(status: :resolved).count
    open_conversations = conversations.where(status: :open).count
    pending_conversations = conversations.where(status: :pending).count

    # Average response time
    avg_first_response = conversations.where.not(first_reply_created_at: nil)
                                     .average("EXTRACT(EPOCH FROM (first_reply_created_at - created_at))")

    # Messages sent/received
    messages = Message.where(account_id: @current_account.id, created_at: start_date..end_date)
    incoming_messages = messages.where(message_type: :incoming).count
    outgoing_messages = messages.where(message_type: :outgoing).count

    # SLA compliance
    applied_slas = AppliedSla.joins(:conversation)
                             .where(conversations: { account_id: @current_account.id })
                             .where(created_at: start_date..end_date)

    sla_total = applied_slas.count
    sla_met = applied_slas.where(sla_status: 'hit').count
    sla_compliance_rate = sla_total > 0 ? (sla_met.to_f / sla_total * 100).round(2) : 0

    render json: {
      period: { start_date: start_date, end_date: end_date },
      conversations: {
        total: total_conversations,
        resolved: resolved_conversations,
        open: open_conversations,
        pending: pending_conversations,
        resolution_rate: total_conversations > 0 ? (resolved_conversations.to_f / total_conversations * 100).round(2) : 0
      },
      response_time: {
        avg_first_response_seconds: avg_first_response&.to_i,
        avg_first_response_minutes: avg_first_response ? (avg_first_response / 60).round(2) : nil
      },
      messages: {
        incoming: incoming_messages,
        outgoing: outgoing_messages,
        total: incoming_messages + outgoing_messages
      },
      sla: {
        total: sla_total,
        met: sla_met,
        missed: sla_total - sla_met,
        compliance_rate: sla_compliance_rate
      }
    }
  end

  # GET /api/v1/accounts/:account_id/reports/agent_performance
  def agent_performance
    start_date = params[:start_date]&.to_date || 30.days.ago.to_date
    end_date = params[:end_date]&.to_date || Date.today

    agents = @current_account.account_users.includes(:user)

    agent_stats = agents.map do |agent|
      conversations = Conversation.where(
        account_id: @current_account.id,
        assignee_id: agent.user_id,
        created_at: start_date..end_date
      )

      total = conversations.count
      resolved = conversations.where(status: :resolved).count

      avg_response = conversations.where.not(first_reply_created_at: nil)
                                 .average("EXTRACT(EPOCH FROM (first_reply_created_at - created_at))")

      # SLA compliance
      applied_slas = AppliedSla.where(conversation_id: conversations.pluck(:id))
      sla_total = applied_slas.count
      sla_met = applied_slas.where(sla_status: 'hit').count

      {
        agent_id: agent.id,
        user_id: agent.user_id,
        name: agent.user&.name,
        email: agent.user&.email,
        conversations_handled: total,
        conversations_resolved: resolved,
        resolution_rate: total > 0 ? (resolved.to_f / total * 100).round(2) : 0,
        avg_first_response_minutes: avg_response ? (avg_response / 60).round(2) : nil,
        sla_compliance_rate: sla_total > 0 ? (sla_met.to_f / sla_total * 100).round(2) : 0,
        sla_met: sla_met,
        sla_total: sla_total
      }
    end

    render json: {
      period: { start_date: start_date, end_date: end_date },
      agents: agent_stats.sort_by { |a| -a[:conversations_handled] }
    }
  end

  # GET /api/v1/accounts/:account_id/reports/channel_performance
  def channel_performance
    start_date = params[:start_date]&.to_date || 30.days.ago.to_date
    end_date = params[:end_date]&.to_date || Date.today

    inboxes = @current_account.inboxes.includes(:channel)

    channel_stats = inboxes.map do |inbox|
      conversations = inbox.conversations.where(created_at: start_date..end_date)
      messages = Message.where(inbox_id: inbox.id, created_at: start_date..end_date)

      total_conversations = conversations.count
      resolved = conversations.where(status: :resolved).count

      avg_response = conversations.where.not(first_reply_created_at: nil)
                                 .average("EXTRACT(EPOCH FROM (first_reply_created_at - created_at))")

      {
        inbox_id: inbox.id,
        inbox_name: inbox.name,
        channel_type: inbox.channel_type,
        conversations: total_conversations,
        resolved: resolved,
        resolution_rate: total_conversations > 0 ? (resolved.to_f / total_conversations * 100).round(2) : 0,
        messages_received: messages.where(message_type: :incoming).count,
        messages_sent: messages.where(message_type: :outgoing).count,
        avg_first_response_minutes: avg_response ? (avg_response / 60).round(2) : nil
      }
    end

    render json: {
      period: { start_date: start_date, end_date: end_date },
      channels: channel_stats
    }
  end

  # GET /api/v1/accounts/:account_id/reports/conversation_trends
  def conversation_trends
    start_date = params[:start_date]&.to_date || 30.days.ago.to_date
    end_date = params[:end_date]&.to_date || Date.today

    # Group conversations by date
    daily_stats = (start_date..end_date).map do |date|
      conversations = @current_account.conversations
                                      .where('DATE(created_at) = ?', date)

      {
        date: date,
        total: conversations.count,
        resolved: conversations.where(status: :resolved).count,
        open: conversations.where(status: :open).count,
        pending: conversations.where(status: :pending).count
      }
    end

    render json: {
      period: { start_date: start_date, end_date: end_date },
      daily_trends: daily_stats
    }
  end
end
