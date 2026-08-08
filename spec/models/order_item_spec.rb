# frozen_string_literal: true

require "rails_helper"

RSpec.describe OrderItem, type: :model do
  describe "associations" do
    it { is_expected.to belong_to(:order) }
    it { is_expected.to belong_to(:product) }
  end

  describe "validations" do
    subject(:order_item) { build(:order_item) }

    it do
      is_expected.to validate_numericality_of(:quantity)
        .only_integer
        .is_greater_than(0)
    end

    it do
      is_expected.to validate_numericality_of(:unit_price)
        .is_greater_than_or_equal_to(0)
    end

    it do
      is_expected.to validate_numericality_of(:total_price)
        .is_greater_than_or_equal_to(0)
    end
  end

  describe "factory" do
    it "has a valid factory" do
      expect(build(:order_item)).to be_valid
    end
  end
end
