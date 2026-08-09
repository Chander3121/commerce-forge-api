# frozen_string_literal: true

class CustomerPolicy < ApplicationPolicy
  def index?
    user.has_permission?("customers.read")
  end

  def show?
    user.has_permission?("customers.read")
  end

  def update?
    user.has_permission?("customers.update")
  end

  def orders?
    user.has_permission?("customers.read")
  end
end
