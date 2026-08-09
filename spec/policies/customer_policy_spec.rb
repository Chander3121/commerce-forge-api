# frozen_string_literal: true

require "rails_helper"

RSpec.describe CustomerPolicy do
  subject(:policy) { described_class.new(user, customer) }

  let(:user) { create(:user) }
  let(:customer) { build(:customer) }

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
    context "with customers.read permission" do
      before { grant_permission("customers.read") }

      it { expect(policy.index?).to be(true) }
    end

    context "without customers.read permission" do
      it { expect(policy.index?).to be(false) }
    end
  end

  describe "#show?" do
    context "with customers.read permission" do
      before { grant_permission("customers.read") }

      it { expect(policy.show?).to be(true) }
    end

    context "without customers.read permission" do
      it { expect(policy.show?).to be(false) }
    end
  end

  describe "#update?" do
    context "with customers.update permission" do
      before { grant_permission("customers.update") }

      it { expect(policy.update?).to be(true) }
    end

    context "without customers.update permission" do
      it { expect(policy.update?).to be(false) }
    end
  end

  describe "#orders?" do
    context "with customers.read permission" do
      before { grant_permission("customers.read") }

      it { expect(policy.orders?).to be(true) }
    end

    context "without customers.read permission" do
      it { expect(policy.orders?).to be(false) }
    end
  end
end
