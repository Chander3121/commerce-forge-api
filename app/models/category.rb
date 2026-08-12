# frozen_string_literal: true

class Category < ApplicationRecord
  validates :name, presence: true
  validates :slug, presence: true, uniqueness: true
  has_many :products, dependent: :restrict_with_error
end
