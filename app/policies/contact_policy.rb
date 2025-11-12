class ContactPolicy < ApplicationPolicy
  def index?
    user_belongs_to_account?
  end

  def show?
    user_belongs_to_account?
  end

  def create?
    user_belongs_to_account?
  end

  def update?
    user_belongs_to_account?
  end

  def destroy?
    user_belongs_to_account? && user_is_admin?
  end

  def conversations?
    user_belongs_to_account?
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
