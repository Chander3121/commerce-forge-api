# frozen_string_literal: true

module AuthorizationHelpers
  def assign_permission(user, permission_code)
    permission = Permission.find_by!(code: permission_code)

    role = Role.create!(
      name: "Test Role",
      slug: "test-role-#{SecureRandom.hex(4)}"
    )

    RolePermission.create!(
      role: role,
      permission: permission
    )

    UserRole.create!(
      user: user,
      role: role
    )

    role
  end
end
