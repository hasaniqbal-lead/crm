class Channel::InstagramPolicy < ApplicationPolicy
  def index?
    user_belongs_to_account?
  end

  def show?
    user_belongs_to_account?
  end

  def create?
    user_is_admin?
  end

  def update?
    user_is_admin?
  end

  def destroy?
    user_is_admin?
  end

  def refresh_token?
    user_is_admin?
  end

  private

  def user_belongs_to_account?
    return false unless user && record

    inbox = record.inbox
    return false unless inbox

    user.account_users.exists?(account_id: inbox.account_id)
  end

  def user_is_admin?
    return false unless user && record

    inbox = record.inbox
    return false unless inbox

    user.account_users.exists?(account_id: inbox.account_id, role: [:administrator, :supervisor])
  end
end
