# frozen_string_literal: true

class Order < ApplicationRecord
  belongs_to :user
  belongs_to :customer, optional: true

  has_many :order_items, dependent: :restrict_with_error
  has_many :products, through: :order_items

  STATUSES = %w[
    pending
    confirmed
    processing
    shipped
    delivered
    cancelled
  ].freeze

  validates :status, presence: true, inclusion: { in: STATUSES }
  validates :subtotal, numericality: { greater_than_or_equal_to: 0 }
  validates :total, numericality: { greater_than_or_equal_to: 0 }
  validates :currency, presence: true
  validate  :valid_status_transition, if: :will_save_change_to_status?

  scope :pending, -> { where(status: "pending") }
  scope :confirmed, -> { where(status: "confirmed") }
  scope :shipped, -> { where(status: "shipped") }
  scope :delivered, -> { where(status: "delivered") }
  scope :cancelled, -> { where(status: "cancelled") }

  def confirm!
    transition_to!("confirmed", from: "pending")
  end

  def process!
    transition_to!("processing", from: "confirmed")
  end

  def ship!
    transition_to!("shipped", from: "processing")
  end

  def deliver!
    transition_to!("delivered", from: "shipped")
  end

  def cancel!
    transition_to!("cancelled", from: "pending")
  end

  private

  def transition_to!(new_status, from:)
    raise ArgumentError, "Invalid order status transition" unless status == from

    update!(status: new_status)
  end

  def valid_status_transition
    allowed_transitions = {
      "pending" => %w[confirmed cancelled],
      "confirmed" => %w[processing cancelled],
      "processing" => %w[shipped cancelled],
      "shipped" => %w[delivered],
      "delivered" => [],
      "cancelled" => []
    }

    allowed_statuses = allowed_transitions.fetch(status_was, [])

    return if allowed_statuses.include?(status)

    errors.add(
      :status,
      "cannot transition from #{status_was} to #{status}"
    )
  end
end
