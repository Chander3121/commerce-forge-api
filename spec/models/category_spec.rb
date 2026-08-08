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
end
