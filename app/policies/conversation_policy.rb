class ConversationPolicy < ApplicationPolicy
  def index?
    user_belongs_to_account?
  end

  def show?
    user_belongs_to_account? && (user_is_assignee? || user_is_admin? || user_is_team_member?)
  end

  def create?
    user_belongs_to_account?
  end

  def update?
    user_belongs_to_account? && (user_is_assignee? || user_is_admin?)
  end

  def assign_agent?
    user_belongs_to_account? && user_is_admin?
  end

  def resolve?
    user_belongs_to_account? && (user_is_assignee? || user_is_admin?)
  end

  def reopen?
    user_belongs_to_account? && (user_is_assignee? || user_is_admin?)
  end

  def update_priority?
    user_belongs_to_account? && (user_is_assignee? || user_is_admin?)
  end

  private

  def user_belongs_to_account?
    return false unless user && record

    user.account_users.exists?(account_id: record.account_id)
  end

  def user_is_assignee?
    return false unless user && record

    record.assignee_id == user.id
  end

  def user_is_admin?
    return false unless user && record

    user.account_users.exists?(account_id: record.account_id, role: [:administrator, :supervisor])
  end

  def user_is_team_member?
    return false unless user && record
    return true unless record.team_id

    TeamMember.exists?(team_id: record.team_id, user_id: user.id)
  end
end
