class AccountUserPolicy < ApplicationPolicy
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
    user_is_admin? || record.user_id == user.id
  end

  def destroy?
    user_is_admin?
  end

  def update_availability?
    user_belongs_to_account? && (record.user_id == user.id || user_is_admin?)
  end

  def performance?
    user_belongs_to_account? && (record.user_id == user.id || user_is_admin?)
  end

  private

  def user_belongs_to_account?
    return false unless user && record

    user.account_users.exists?(account_id: record.account_id)
  end

  def user_is_admin?
    return false unless user && record

    user.account_users.exists?(account_id: record.account_id, role: [:administrator, :supervisor])
  end
end
