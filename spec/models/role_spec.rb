# frozen_string_literal: true

require "rails_helper"

RSpec.describe Role, type: :model do
  describe "validations" do
    subject(:role) do
      described_class.new(
        name: "Admin",
        slug: "admin"
      )
    end

    it "is valid with valid attributes" do
      expect(role).to be_valid
    end

    it "requires a name" do
      role.name = nil

      expect(role).not_to be_valid
      expect(role.errors[:name]).to include("can't be blank")
    end

    it "requires a slug" do
      role.slug = nil

      expect(role).not_to be_valid
      expect(role.errors[:slug]).to include("can't be blank")
    end

    it "requires a unique slug" do
      described_class.create!(
        name: "Admin",
        slug: "admin"
      )

      duplicate_role = described_class.new(
        name: "Another Admin",
        slug: "admin"
      )

      expect(duplicate_role).not_to be_valid
      expect(duplicate_role.errors[:slug]).to include("has already been taken")
    end
  end

  describe "associations" do
    it { is_expected.to have_many(:user_roles).dependent(:restrict_with_error) }
    it { is_expected.to have_many(:users).through(:user_roles) }
    it { is_expected.to have_many(:role_permissions).dependent(:restrict_with_error) }
    it { is_expected.to have_many(:permissions).through(:role_permissions) }
  end
end
