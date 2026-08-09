# frozen_string_literal: true

class Customer < ApplicationRecord
  has_many :orders, dependent: :restrict_with_error

  validates :name, presence: true
  validates :email, presence: true, uniqueness: true
end
