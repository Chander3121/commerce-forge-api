# frozen_string_literal: true

module Api
  module V1
    class OrdersController < BaseController
      before_action :authenticate_user!
      before_action :set_order, only: %i[show update cancel]

      def index
        authorize Order

        orders = Order.includes(:order_items, :customer).order(created_at: :desc)

        render_success(
          message: "Orders fetched successfully.",
          data: {
            orders: orders.as_json(
              include: {
                customer: {
                  only: %i[id name email phone]
                },
                order_items: {
                  only: %i[id product_id quantity unit_price total_price]
                }
              },
              only: %i[id user_id customer_id status subtotal total currency created_at]
            )
          }
        )
      end

      def create
        authorize Order

        customer = Customer.find(params[:order][:customer_id])

        order = Orders::Create.new(
          user: current_user,
          customer: customer,
          items: order_items_params
        ).call

        render_success(
          message: "Order created successfully.",
          data: {
            order: order.as_json(
              include: {
                order_items: {
                  only: %i[id product_id quantity unit_price total_price]
                }
              },
              only: %i[id user_id status subtotal total currency created_at]
            )
          },
          status: :created
        )
      rescue ArgumentError => e
        render_error(
          message: e.message,
          errors: [
            {
              code: "INVALID_ORDER",
              message: e.message
            }
          ],
          status: :unprocessable_entity
        )
      end

      def show
        authorize @order

        render_success(
          message: "Order fetched successfully.",
          data: {
            order: @order.as_json(
              include: {
                customer: {
                  only: %i[id name email phone]
                },
                order_items: {
                  only: %i[id product_id quantity unit_price total_price]
                }
              },
              only: %i[id user_id customer_id status subtotal total currency created_at]
            )
          }
        )
      end

      def update
        authorize @order

        @order.update!(order_update_params)

        render_success(
          message: "Order updated successfully.",
          data: {
            order: @order
          }
        )
      rescue ActiveRecord::RecordInvalid => e
        render_error(
          message: e.record.errors.full_messages.to_sentence,
          errors: [
            {
              code: "INVALID_ORDER",
              message: e.record.errors.full_messages.to_sentence
            }
          ],
          status: :unprocessable_entity
        )
      end

      def cancel
        authorize @order

        @order.cancel!

        render_success(
          message: "Order cancelled successfully.",
          data: {
            order: @order
          }
        )
      rescue ArgumentError => e
        render_error(
          message: e.message,
          errors: [
            {
              code: "INVALID_ORDER_TRANSITION",
              message: e.message
            }
          ],
          status: :unprocessable_entity
        )
      end

      private

      def set_order
        @order = Order.includes(:order_items).find(params[:id])
      end

      def order_items_params
        params.require(:order).require(:items).map do |item|
          {
            product: Product.find(item.require(:product_id)),
            quantity: item.require(:quantity).to_i
          }
        end
      end

      def order_customer_id
        params.require(:order).fetch(:customer_id)
      end

      def order_update_params
        params.require(:order).permit(:status)
      end
    end
  end
end
