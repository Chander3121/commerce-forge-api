# frozen_string_literal: true

class User < ApplicationRecord
  include Devise::JWT::RevocationStrategies::JTIMatcher

  has_many :user_roles, dependent: :restrict_with_error
  has_many :roles, through: :user_roles

  devise :database_authenticatable,
         :recoverable,
         :rememberable,
         :validatable,
         :jwt_authenticatable,
         jwt_revocation_strategy: self

  def assign_role(role)
    UserRole.find_or_create_by!(
      user: self,
      role: role
    )

    role
  end

  def remove_role(role)
    user_roles.where(role: role).destroy_all

    role
  end

  def has_role?(role)
    roles.exists?(slug: role.to_s)
  end

  def has_permission?(permission_code)
    Permission
      .joins(role_permissions: :role)
      .where(role_permissions: { role_id: user_roles.select(:role_id) })
      .where(code: permission_code)
      .exists?
  end

  def super_admin?
    has_role?(:super_admin)
  end

  def admin?
    has_role?(:admin)
  end

  def manager?
    has_role?(:manager)
  end

  def staff?
    has_role?(:staff)
  end

  def customer?
    has_role?(:customer)
  end
end
