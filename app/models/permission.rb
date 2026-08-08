# frozen_string_literal: true

class Permission < ApplicationRecord
  has_many :role_permissions, dependent: :restrict_with_error
  has_many :roles, through: :role_permissions

  validates :name, presence: true
  validates :code, presence: true, uniqueness: true
end
