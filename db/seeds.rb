# frozen_string_literal: true

permissions = [
  {
    name: "View Products",
    code: "products.read",
    description: "View products."
  },
  {
    name: "Create Products",
    code: "products.create",
    description: "Create products."
  },
  {
    name: "Update Products",
    code: "products.update",
    description: "Update products."
  },
  {
    name: "Delete Products",
    code: "products.delete",
    description: "Delete products."
  },

  {
    name: "View Categories",
    code: "categories.read",
    description: "View categories."
  },
  {
    name: "Create Categories",
    code: "categories.create",
    description: "Create categories."
  },
  {
    name: "Update Categories",
    code: "categories.update",
    description: "Update categories."
  },
  {
    name: "Delete Categories",
    code: "categories.delete",
    description: "Delete categories."
  },

  {
    name: "Create Orders",
    code: "orders.create",
    description: "Allows creating orders"
  },
  {
    name: "View Orders",
    code: "orders.read",
    description: "View orders."
  },
  {
    name: "Update Orders",
    code: "orders.update",
    description: "Update orders."
  },
  {
    name: "Cancel Orders",
    code: "orders.cancel",
    description: "Cancel orders."
  },

  {
    name: "View Customers",
    code: "customers.read",
    description: "View customers."
  },
  {
    name: "Update Customers",
    code: "customers.update",
    description: "Update customers."
  },

  {
    name: "View Users",
    code: "users.read",
    description: "View users."
  },
  {
    name: "Create Users",
    code: "users.create",
    description: "Create users."
  },
  {
    name: "Update Users",
    code: "users.update",
    description: "Update users."
  },
  {
    name: "Delete Users",
    code: "users.delete",
    description: "Delete users."
  },

  {
    name: "View Roles",
    code: "roles.read",
    description: "View roles."
  },
  {
    name: "Create Roles",
    code: "roles.create",
    description: "Create roles."
  },
  {
    name: "Update Roles",
    code: "roles.update",
    description: "Update roles."
  },
  {
    name: "Delete Roles",
    code: "roles.delete",
    description: "Delete roles."
  },

  {
    name: "View Permissions",
    code: "permissions.read",
    description: "View permissions."
  },
  {
    name: "Update Permissions",
    code: "permissions.update",
    description: "Update permission assignments."
  },

  {
    name: "View Settings",
    code: "settings.read",
    description: "View application settings."
  },
  {
    name: "Update Settings",
    code: "settings.update",
    description: "Update application settings."
  },

  {
    name: "View Theme",
    code: "theme.read",
    description: "View theme configuration."
  },
  {
    name: "Update Theme",
    code: "theme.update",
    description: "Update theme configuration."
  },

  {
    name: "View Media",
    code: "media.read",
    description: "View media library."
  },
  {
    name: "Upload Media",
    code: "media.create",
    description: "Upload media."
  },
  {
    name: "Delete Media",
    code: "media.delete",
    description: "Delete media."
  },

  {
    name: "View Audit Logs",
    code: "audit_logs.read",
    description: "View audit logs."
  }
]

permissions.each do |attributes|
  permission = Permission.find_or_initialize_by(code: attributes[:code])
  permission.assign_attributes(attributes)
  permission.save!
end

roles = [
  {
    name: "Super Admin",
    slug: "super_admin",
    description: "Full access to the CommerceForge administration system.",
    system: true,
    permissions: permissions.map { |permission| permission[:code] }
  },
  {
    name: "Admin",
    slug: "admin",
    description: "Administrative access to the store.",
    system: true,
    permissions: permissions.map { |permission| permission[:code] }
  },
  {
    name: "Manager",
    slug: "manager",
    description: "Operational management access.",
    system: true,
    permissions: %w[
      products.read
      products.create
      products.update
      categories.read
      categories.create
      categories.update
      orders.read
      orders.update
      orders.cancel
      customers.read
      customers.update
    ]
  },
  {
    name: "Staff",
    slug: "staff",
    description: "Limited operational access.",
    system: true,
    permissions: %w[
      products.read
      categories.read
      orders.read
      orders.update
      customers.read
    ]
  },
  {
    name: "Customer",
    slug: "customer",
    description: "Standard customer access.",
    system: true,
    permissions: %w[
      products.read
    ]
  }
]

roles.each do |attributes|
  permission_codes = attributes[:permissions]

  role_attributes = attributes.except(:permissions)

  role = Role.find_or_initialize_by(slug: role_attributes[:slug])
  role.assign_attributes(role_attributes)
  role.save!

  permission_codes.each do |permission_code|
    permission = Permission.find_by!(code: permission_code)

    RolePermission.find_or_create_by!(
      role: role,
      permission: permission
    )
  end
end
