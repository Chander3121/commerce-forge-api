# frozen_string_literal: true

require "rails_helper"

RSpec.describe Product, type: :model do
  describe "validations" do
    subject(:product) { build(:product) }

    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_presence_of(:slug) }
    it { is_expected.to validate_uniqueness_of(:slug) }
    it { is_expected.to validate_presence_of(:price) }
    it { is_expected.to validate_numericality_of(:price).is_greater_than_or_equal_to(0) }
    it { is_expected.to validate_presence_of(:status) }
    it { is_expected.to validate_inclusion_of(:status).in_array(Product::STATUSES) }
  end

  describe "factory" do
    it "has a valid factory" do
      expect(build(:product)).to be_valid
    end
  end
end
