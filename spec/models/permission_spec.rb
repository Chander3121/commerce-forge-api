# frozen_string_literal: true

require "rails_helper"

RSpec.describe Permission, type: :model do
  describe "validations" do
    subject(:permission) do
      described_class.new(
        name: "View Products",
        code: "products.read"
      )
    end

    it "is valid with valid attributes" do
      expect(permission).to be_valid
    end

    it "requires a name" do
      permission.name = nil

      expect(permission).not_to be_valid
      expect(permission.errors[:name]).to include("can't be blank")
    end

    it "requires a code" do
      permission.code = nil

      expect(permission).not_to be_valid
      expect(permission.errors[:code]).to include("can't be blank")
    end

    it "requires a unique code" do
      described_class.create!(
        name: "View Products",
        code: "products.read"
      )

      duplicate_permission = described_class.new(
        name: "Read Products",
        code: "products.read"
      )

      expect(duplicate_permission).not_to be_valid
      expect(duplicate_permission.errors[:code]).to include("has already been taken")
    end
  end

  describe "associations" do
    it { is_expected.to have_many(:role_permissions).dependent(:restrict_with_error) }
    it { is_expected.to have_many(:roles).through(:role_permissions) }
  end
end
