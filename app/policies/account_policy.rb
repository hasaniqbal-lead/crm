class AccountPolicy < ApplicationPolicy
  def show?
    user_is_member?
  end

  def update?
    user_is_admin?
  end

  def destroy?
    user_is_admin?
  end

  private

  def user_is_member?
    return false unless user && record

    user.account_users.exists?(account_id: record.id)
  end

  def user_is_admin?
    return false unless user && record

    user.account_users.exists?(account_id: record.id, role: :administrator)
  end
end
