# frozen_string_literal: true

require "rails_helper"

RSpec.describe Category, type: :model do
  describe "validations" do
    subject(:category) { build(:category) }

    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_presence_of(:slug) }
    it { is_expected.to validate_uniqueness_of(:slug) }
  end

  describe "factory" do
    it "has a valid factory" do
      expect(build(:category)).to be_valid
    end
  end

  it "has many products" do
    association = described_class.reflect_on_association(:products)

    expect(association).not_to be_nil
    expect(association.macro).to eq(:has_many)
  end
end
