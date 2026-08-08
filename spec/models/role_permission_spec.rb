# frozen_string_literal: true

require "rails_helper"

RSpec.describe RolePermission, type: :model do
  let(:role) do
    Role.create!(
      name: "Admin",
      slug: "admin"
    )
  end

  let(:permission) do
    Permission.create!(
      name: "View Products",
      code: "products.read"
    )
  end

  describe "associations" do
    it { is_expected.to belong_to(:role) }
    it { is_expected.to belong_to(:permission) }
  end

  describe "validations" do
    it "prevents assigning the same permission to the same role twice" do
      described_class.create!(
        role: role,
        permission: permission
      )

      duplicate_role_permission = described_class.new(
        role: role,
        permission: permission
      )

      expect(duplicate_role_permission).not_to be_valid
      expect(duplicate_role_permission.errors[:permission_id]).to include(
        "has already been taken"
      )
    end
  end
end
