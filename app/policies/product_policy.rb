# frozen_string_literal: true

class ProductPolicy < ApplicationPolicy
  def index?
    permitted?("products.read")
  end

  def show?
    permitted?("products.read")
  end

  def create?
    permitted?("products.create")
  end

  def update?
    permitted?("products.update")
  end

  def destroy?
    permitted?("products.delete")
  end
end
