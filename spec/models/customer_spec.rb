# frozen_string_literal: true

require "rails_helper"

RSpec.describe Customer, type: :model do
  subject(:customer) { build(:customer) }

  describe "associations" do
    it { is_expected.to have_many(:orders).dependent(:restrict_with_error) }
  end

  describe "validations" do
    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_presence_of(:email) }
    it { is_expected.to validate_uniqueness_of(:email) }
  end

  describe "factory" do
    it "has a valid factory" do
      expect(build(:customer)).to be_valid
    end
  end
end
