# frozen_string_literal: true

class Product < ApplicationRecord
  STATUSES = %w[active inactive archived].freeze

  validates :name, presence: true
  validates :slug, presence: true, uniqueness: true
  validates :price, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :status, presence: true, inclusion: { in: STATUSES }
end
