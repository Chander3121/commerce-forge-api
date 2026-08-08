# frozen_string_literal: true

require "rails_helper"

RSpec.describe User, type: :model do
  subject(:user) do
    described_class.create!(
      email: "user-test@commerceforge.dev",
      password: "Password@123",
      password_confirmation: "Password@123",
      jti: SecureRandom.uuid
    )
  end

  describe "associations" do
    it { is_expected.to have_many(:user_roles).dependent(:restrict_with_error) }
    it { is_expected.to have_many(:roles).through(:user_roles) }
  end

  describe "authentication" do
    it "authenticates with the correct password" do
      expect(user.valid_password?("Password@123")).to be(true)
    end

    it "does not authenticate with an incorrect password" do
      expect(user.valid_password?("WrongPassword@123")).to be(false)
    end
  end

  describe "roles" do
    it "returns assigned roles" do
      role = Role.create!(
        name: "Staff",
        slug: "staff"
      )

      UserRole.create!(
        user: user,
        role: role
      )

      expect(user.roles).to contain_exactly(role)
    end

    describe "#assign_role" do
      let(:role) do
        Role.create!(
          name: "Manager",
          slug: "manager"
        )
      end

      it "assigns a role to the user" do
        user.assign_role(role)

        expect(user.roles).to contain_exactly(role)
      end

      it "does not create duplicate role assignments" do
        user.assign_role(role)
        user.assign_role(role)

        expect(user.user_roles.count).to eq(1)
      end
    end

    describe "#remove_role" do
      let(:role) do
        Role.create!(
          name: "Manager",
          slug: "manager"
        )
      end

      it "removes the role from the user" do
        user.assign_role(role)

        user.remove_role(role)

        expect(user.roles).to be_empty
      end
    end

    describe "#has_role?" do
      let(:role) do
        Role.create!(
          name: "Manager",
          slug: "manager"
        )
      end

      it "returns true when the user has the role" do
        user.assign_role(role)

        expect(user.has_role?(:manager)).to be(true)
      end

      it "returns false when the user does not have the role" do
        expect(user.has_role?(:manager)).to be(false)
      end
    end

    describe "#has_permission?" do
      let(:role) do
        Role.create!(
          name: "Manager",
          slug: "manager"
        )
      end

      let(:permission) do
        Permission.create!(
          name: "View Products",
          code: "products.read"
        )
      end

      before do
        RolePermission.create!(
          role: role,
          permission: permission
        )

        user.assign_role(role)
      end

      it "returns true when the user has the permission" do
        expect(user.has_permission?("products.read")).to be(true)
      end

      it "returns false when the user does not have the permission" do
        expect(user.has_permission?("products.delete")).to be(false)
      end
    end

    describe "role helpers" do
      it "identifies an admin" do
        role = Role.create!(
          name: "Admin",
          slug: "admin"
        )

        user.assign_role(role)

        expect(user.admin?).to be(true)
      end

      it "identifies a super admin" do
        role = Role.create!(
          name: "Super Admin",
          slug: "super_admin"
        )

        user.assign_role(role)

        expect(user.super_admin?).to be(true)
      end
    end
  end
end
