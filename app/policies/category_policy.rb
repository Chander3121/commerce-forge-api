# frozen_string_literal: true

class CategoryPolicy < ApplicationPolicy
  def index?
    permitted?("categories.read")
  end

  def show?
    permitted?("categories.read")
  end

  def create?
    permitted?("categories.create")
  end

  def update?
    permitted?("categories.update")
  end

  def destroy?
    permitted?("categories.delete")
  end
end
