# frozen_string_literal: true

class Payment < ApplicationRecord
  belongs_to :order

  STATUSES = %w[
    pending
    processing
    succeeded
    failed
  ].freeze

  validates :amount, presence: true
  validates :amount, numericality: { greater_than: 0 }
  validates :currency, presence: true
  validates :status, presence: true, inclusion: { in: STATUSES }
  validates :idempotency_key, presence: true, uniqueness: true
  validates :gateway, presence: true

  validate :valid_status_transition, if: :will_save_change_to_status?

  def process!
    transition_to!("processing", from: "pending")
  end

  def succeed!
    transition_to!("succeeded", from: "processing")
  end

  def fail!
    transition_to!("failed", from: "processing")
  end

  private

  def transition_to!(new_status, from:)
    raise ArgumentError, "Invalid payment status transition" unless status == from

    update!(status: new_status)
  end

  def valid_status_transition
    return if new_record?

    allowed_transitions = {
      "pending" => %w[processing],
      "processing" => %w[succeeded failed],
      "succeeded" => [],
      "failed" => []
    }

    allowed_statuses = allowed_transitions.fetch(status_was, [])

    return if allowed_statuses.include?(status)

    errors.add(
      :status,
      "cannot transition from #{status_was} to #{status}"
    )
  end
end
