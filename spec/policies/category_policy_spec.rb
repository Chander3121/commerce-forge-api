# frozen_string_literal: true

require "rails_helper"

RSpec.describe CategoryPolicy do
  subject(:policy) { described_class.new(user, category) }

  let(:user) { create(:user) }
  let(:category) { build(:category) }

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
    context "with categories.read permission" do
      before { grant_permission("categories.read") }

      it { expect(policy.index?).to be(true) }
    end

    context "without categories.read permission" do
      it { expect(policy.index?).to be(false) }
    end
  end

  describe "#show?" do
    context "with categories.read permission" do
      before { grant_permission("categories.read") }

      it { expect(policy.show?).to be(true) }
    end

    context "without categories.read permission" do
      it { expect(policy.show?).to be(false) }
    end
  end

  describe "#create?" do
    context "with categories.create permission" do
      before { grant_permission("categories.create") }

      it { expect(policy.create?).to be(true) }
    end

    context "without categories.create permission" do
      it { expect(policy.create?).to be(false) }
    end
  end

  describe "#update?" do
    context "with categories.update permission" do
      before { grant_permission("categories.update") }

      it { expect(policy.update?).to be(true) }
    end

    context "without categories.update permission" do
      it { expect(policy.update?).to be(false) }
    end
  end

  describe "#destroy?" do
    context "with categories.delete permission" do
      before { grant_permission("categories.delete") }

      it { expect(policy.destroy?).to be(true) }
    end

    context "without categories.delete permission" do
      it { expect(policy.destroy?).to be(false) }
    end
  end
end
