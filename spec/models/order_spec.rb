# frozen_string_literal: true

require "rails_helper"

RSpec.describe Order, type: :model do
  describe "associations" do
    it { is_expected.to belong_to(:user) }
    it { is_expected.to belong_to(:customer).optional }
  end

  describe "validations" do
    subject(:order) { build(:order) }

    it { is_expected.to validate_presence_of(:status) }
    it { is_expected.to validate_presence_of(:currency) }

    it do
      is_expected.to validate_inclusion_of(:status).in_array(
        Order::STATUSES
      )
    end

    it do
      is_expected.to validate_numericality_of(:subtotal)
        .is_greater_than_or_equal_to(0)
    end

    it do
      is_expected.to validate_numericality_of(:total)
        .is_greater_than_or_equal_to(0)
    end
  end

  describe "factory" do
    it "has a valid factory" do
      expect(build(:order)).to be_valid
    end
  end

  describe "status transitions" do
    describe "#confirm!" do
      it "confirms a pending order" do
        order = create(:order, status: "pending")

        expect { order.confirm! }
          .to change(order, :status)
          .from("pending")
          .to("confirmed")
      end

      it "rejects confirmation of a non-pending order" do
        order = create(:order)
        order.confirm!
        order.ship!

        expect { order.confirm! }.to raise_error(
          ArgumentError,
          "Invalid order status transition"
        )
      end
    end

    describe "#ship!" do
      it "ships a confirmed order" do
        order = create(:order, status: "confirmed")

        expect { order.ship! }
          .to change(order, :status)
          .from("confirmed")
          .to("shipped")
      end

      it "rejects shipping a pending order" do
        order = create(:order, status: "pending")

        expect { order.ship! }
          .to raise_error(ArgumentError, "Invalid order status transition")
      end
    end

    describe "#deliver!" do
      it "delivers a shipped order" do
        order = create(:order)

        order.confirm!
        order.ship!

        expect { order.deliver! }.to change { order.reload.status }
          .from("shipped").to("delivered")
      end

      it "rejects delivery of a confirmed order" do
        order = create(:order, status: "confirmed")

        expect { order.deliver! }
          .to raise_error(ArgumentError, "Invalid order status transition")
      end
    end

    describe "#cancel!" do
      it "cancels a pending order" do
        order = create(:order, status: "pending")

        expect { order.cancel! }
          .to change(order, :status)
          .from("pending")
          .to("cancelled")
      end

      it "rejects cancellation of a confirmed order" do
        order = create(:order, status: "confirmed")

        expect { order.cancel! }
          .to raise_error(ArgumentError, "Invalid order status transition")
      end
    end

    describe "status transitions" do
      let(:order) { create(:order) }

      it "allows pending to confirmed" do
        order.status = "confirmed"

        expect(order).to be_valid
      end

      it "allows confirmed to shipped" do
        order.confirm!

        order.status = "shipped"

        expect(order).to be_valid
      end

      it "allows shipped to delivered" do
        order.confirm!
        order.ship!

        order.status = "delivered"

        expect(order).to be_valid
      end

      it "does not allow delivered to pending" do
        order.confirm!
        order.ship!
        order.deliver!

        order.status = "pending"

        expect(order).not_to be_valid
      end

      it "does not allow cancelled to confirmed" do
        order.cancel!

        order.status = "confirmed"

        expect(order).not_to be_valid
      end
    end
  end
end
