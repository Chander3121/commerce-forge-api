# frozen_string_literal: true

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
    user.has_permission?("orders.update")
  end

  def cancel?
    user.has_permission?("orders.cancel")
  end

  private

  def privileged_order_reader?
    user.admin? || user.super_admin?
  end
end
