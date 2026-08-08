# frozen_string_literal: true

require "rails_helper"

RSpec.describe ProductPolicy do
  subject(:policy) { described_class.new(user, product) }

  let(:user) { create(:user) }
  let(:product) { build(:product) }

  def grant_permission(permission_code)
    permission = create(
      :permission,
      name: permission_code.humanize,
      code: permission_code
    )

    role = create(:role)

    create(
      :role_permission,
      role: role,
      permission: permission
    )

    create(
      :user_role,
      user: user,
      role: role
    )
  end

  describe "#index?" do
    context "with products.read permission" do
      before { grant_permission("products.read") }

      it { expect(policy.index?).to be(true) }
    end

    context "without products.read permission" do
      it { expect(policy.index?).to be(false) }
    end
  end

  describe "#show?" do
    context "with products.read permission" do
      before { grant_permission("products.read") }

      it { expect(policy.show?).to be(true) }
    end

    context "without products.read permission" do
      it { expect(policy.show?).to be(false) }
    end
  end

  describe "#create?" do
    context "with products.create permission" do
      before { grant_permission("products.create") }

      it { expect(policy.create?).to be(true) }
    end

    context "without products.create permission" do
      it { expect(policy.create?).to be(false) }
    end
  end

  describe "#update?" do
    context "with products.update permission" do
      before { grant_permission("products.update") }

      it { expect(policy.update?).to be(true) }
    end

    context "without products.update permission" do
      it { expect(policy.update?).to be(false) }
    end
  end

  describe "#destroy?" do
    context "with products.delete permission" do
      before { grant_permission("products.delete") }

      it { expect(policy.destroy?).to be(true) }
    end

    context "without products.delete permission" do
      it { expect(policy.destroy?).to be(false) }
    end
  end
end
