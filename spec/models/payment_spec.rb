# frozen_string_literal: true

require "rails_helper"

RSpec.describe Payment, type: :model do
  describe "associations" do
    it { is_expected.to belong_to(:order) }
  end

  describe "validations" do
    subject(:payment) { build(:payment) }

    it { is_expected.to validate_presence_of(:amount) }
    it { is_expected.to validate_presence_of(:currency) }
    it { is_expected.to validate_presence_of(:status) }
    it { is_expected.to validate_presence_of(:gateway) }

    it { is_expected.to validate_presence_of(:idempotency_key) }

    it do
      is_expected.to validate_uniqueness_of(:idempotency_key)
    end

    it do
      is_expected.to validate_inclusion_of(:status).in_array(
        Payment::STATUSES
      )
    end

    it do
      is_expected.to validate_numericality_of(:amount)
        .is_greater_than(0)
    end
  end

  describe "successful payment uniqueness" do
    it "does not allow more than one succeeded payment for the same order" do
      order = create(:order)

      create(
        :payment,
        order: order,
        status: "succeeded"
      )

      expect {
        create(
          :payment,
          order: order,
          status: "succeeded"
        )
      }.to raise_error(ActiveRecord::RecordNotUnique)
    end
  end

  describe "factory" do
    it "has a valid factory" do
      expect(build(:payment)).to be_valid
    end
  end

  describe "status transitions" do
    describe "#process!" do
      it "moves a pending payment to processing" do
        payment = create(:payment, status: "pending")

        expect { payment.process! }
          .to change(payment, :status)
          .from("pending")
          .to("processing")
      end

      it "rejects processing a non-pending payment" do
        payment = create(:payment, status: "succeeded")

        expect { payment.process! }
          .to raise_error(
            ArgumentError,
            "Invalid payment status transition"
          )
      end
    end

    describe "#succeed!" do
      it "moves a processing payment to succeeded" do
        payment = create(:payment, status: "pending")
        payment.process!

        expect { payment.succeed! }
          .to change(payment, :status)
          .from("processing")
          .to("succeeded")
      end

      it "rejects succeeding a pending payment" do
        payment = create(:payment, status: "pending")

        expect { payment.succeed! }
          .to raise_error(
            ArgumentError,
            "Invalid payment status transition"
          )
      end
    end

    describe "#fail!" do
      it "moves a processing payment to failed" do
        payment = create(:payment, status: "pending")
        payment.process!

        expect { payment.fail! }
          .to change(payment, :status)
          .from("processing")
          .to("failed")
      end

      it "rejects failing a pending payment" do
        payment = create(:payment, status: "pending")

        expect { payment.fail! }
          .to raise_error(
            ArgumentError,
            "Invalid payment status transition"
          )
      end
    end
  end
end
