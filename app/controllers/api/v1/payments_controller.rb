# frozen_string_literal: true

module Api
  module V1
    class PaymentsController < BaseController
      before_action :authenticate_user!
      before_action :set_order

      def create
        order = Order.find(params[:order_id])

        authorize order, :update?

        idempotency_key = request.headers["Idempotency-Key"]

        if idempotency_key.blank?
          return render_error(
            message: "Idempotency-Key header is required.",
            errors: [
              {
                code: "IDEMPOTENCY_KEY_REQUIRED",
                message: "Idempotency-Key header is required."
              }
            ],
            status: :unprocessable_content
          )
        end

        payment = Payments::Create.new(
          order: order,
          gateway: params[:gateway] || "razorpay",
          idempotency_key: idempotency_key
        ).call

        payment = Payments::Process.new(
          payment: payment,
          gateway: Payments::RazorpayGateway.new
        ).call

        if payment.status == "failed"
          return render_error(
            message: payment.failure_message,
            errors: [
              {
                code: payment.failure_code,
                message: payment.failure_message
              }
            ],
            status: :unprocessable_content
          )
        end

        render_success(
          message: "Payment processed successfully.",
          data: {
            payment: payment.as_json(
              only: %i[
                id
                order_id
                amount
                currency
                status
                gateway
                gateway_transaction_id
                paid_at
              ]
            )
          }
        )
      rescue ArgumentError => e
        render_error(
          message: e.message,
          errors: [
            {
              code: "PAYMENT_FAILED",
              message: e.message
            }
          ],
          status: :unprocessable_content
        )
      end

      private

      def set_order
        @order = Order.find(params[:order_id])
      end
    end
  end
end
