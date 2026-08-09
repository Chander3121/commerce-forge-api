# frozen_string_literal: true

require "rails_helper"

RSpec.describe OrderPolicy do
  subject(:policy) { described_class.new(user, order) }

  let(:user) { create(:user) }
  let(:order) { create(:order, user: user) }

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
    context "with orders.read permission" do
      before { grant_permission("orders.read") }

      it { expect(policy.index?).to be(true) }
    end

    context "without orders.read permission" do
      it { expect(policy.index?).to be(false) }
    end
  end

  describe "#create?" do
    context "with orders.create permission" do
      before { grant_permission("orders.create") }

      it { expect(policy.create?).to be(true) }
    end

    context "without orders.create permission" do
      it { expect(policy.create?).to be(false) }
    end
  end

  describe "#show?" do
    context "with orders.read permission" do
      before { grant_permission("orders.read") }

      it { expect(policy.show?).to be(true) }
    end

    context "without orders.read permission" do
      it { expect(policy.show?).to be(false) }
    end
  end

  describe "#update?" do
    context "with orders.update permission" do
      before { grant_permission("orders.update") }

      it { expect(policy.update?).to be(true) }
    end

    context "without orders.update permission" do
      it { expect(policy.update?).to be(false) }
    end
  end

  describe "#confirm?" do
    context "with orders.update permission" do
      before { grant_permission("orders.update") }

      it { expect(policy.confirm?).to be(true) }
    end

    context "without orders.update permission" do
      it { expect(policy.confirm?).to be(false) }
    end
  end

  describe "#process_order?" do
    context "with orders.update permission" do
      before { grant_permission("orders.update") }

      it { expect(policy.process_order?).to be(true) }
    end

    context "without orders.update permission" do
      it { expect(policy.process_order?).to be(false) }
    end
  end

  describe "#ship?" do
    context "with orders.update permission" do
      before { grant_permission("orders.update") }

      it { expect(policy.ship?).to be(true) }
    end

    context "without orders.update permission" do
      it { expect(policy.ship?).to be(false) }
    end
  end

  describe "#deliver?" do
    context "with orders.update permission" do
      before { grant_permission("orders.update") }

      it { expect(policy.deliver?).to be(true) }
    end

    context "without orders.update permission" do
      it { expect(policy.deliver?).to be(false) }
    end
  end

  describe "#cancel?" do
    context "with orders.update permission" do
      before { grant_permission("orders.update") }

      it { expect(policy.cancel?).to be(true) }
    end

    context "without orders.update permission" do
      it { expect(policy.cancel?).to be(false) }
    end
  end
end
