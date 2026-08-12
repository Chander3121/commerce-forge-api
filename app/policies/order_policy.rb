class OrderPolicy < ApplicationPolicy
  def index?
    user.has_permission?("orders.read")
  end

  def create?
    user.has_permission?("orders.create")
  end

  def show?
    return false unless user.has_permission?("orders.read")

    record.user_id == user.id || privileged_order_reader?
  end

  def update?
    manageable?("orders.update")
  end

  def confirm?
    manageable?("orders.update")
  end

  def process_order?
    manageable?("orders.update")
  end

  def ship?
    manageable?("orders.update")
  end

  def deliver?
    manageable?("orders.update")
  end

  def cancel?
    manageable?("orders.update")
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      if user.admin? || user.super_admin?
        scope.all
      else
        scope.where(user_id: user.id)
      end
    end
  end

  private

  def manageable?(permission)
    return false unless user.has_permission?(permission)

    record.user_id == user.id || privileged_order_manager?
  end

  def privileged_order_reader?
    user.admin? || user.super_admin?
  end

  def privileged_order_manager?
    user.admin? || user.super_admin?
  end
end
