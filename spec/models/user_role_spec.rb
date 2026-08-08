# frozen_string_literal: true

require "rails_helper"

RSpec.describe UserRole, type: :model do
  let(:user) do
    User.create!(
      email: "userrole-test@commerceforge.dev",
      password: "Password@123",
      password_confirmation: "Password@123",
      jti: SecureRandom.uuid
    )
  end

  let(:role) do
    Role.create!(
      name: "Manager",
      slug: "manager"
    )
  end

  describe "associations" do
    it { is_expected.to belong_to(:user) }
    it { is_expected.to belong_to(:role) }
  end

  describe "validations" do
    it "prevents assigning the same role to the same user twice" do
      described_class.create!(
        user: user,
        role: role
      )

      duplicate_user_role = described_class.new(
        user: user,
        role: role
      )

      expect(duplicate_user_role).not_to be_valid
      expect(duplicate_user_role.errors[:role_id]).to include(
        "has already been taken"
      )
    end
  end
end
