# frozen_string_literal: true

class Role < ApplicationRecord
  has_many :user_roles, dependent: :restrict_with_error
  has_many :users, through: :user_roles

  has_many :role_permissions, dependent: :restrict_with_error
  has_many :permissions, through: :role_permissions

  validates :name, presence: true
  validates :slug, presence: true, uniqueness: true
end
