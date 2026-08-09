# frozen_string_literal: true

module Api
  module V1
    class CustomersController < BaseController
      before_action :authenticate_user!
      before_action :set_customer, only: %i[show update orders]

      def index
        authorize Customer

        customers = Customer.all

        if params[:search].present?
          search = "%#{params[:search]}%"

          customers = customers.where(
            "name ILIKE :search OR email ILIKE :search OR phone ILIKE :search",
            search: search
          )
        end

        sort_by = params.fetch(:sort_by, "created_at")
        sort_order = params.fetch(:sort_order, "desc")

        allowed_sort_columns = %w[name email phone created_at]
        allowed_sort_orders = %w[asc desc]

        sort_by = "created_at" unless allowed_sort_columns.include?(sort_by)
        sort_order = "desc" unless allowed_sort_orders.include?(sort_order)

        customers = customers.order(sort_by => sort_order)

        page = params.fetch(:page, 1).to_i
        per_page = params.fetch(:per_page, 20).to_i

        page = 1 if page < 1
        per_page = 20 if per_page < 1

        total = customers.count

        customers = customers
          .offset((page - 1) * per_page)
          .limit(per_page)

        total_pages = (total.to_f / per_page).ceil

        render_success(
          message: "Customers fetched successfully.",
          data: {
            customers: customers.as_json(
              only: %i[id name email phone created_at]
            ),
            meta: {
              page: page,
              per_page: per_page,
              total: total,
              total_pages: total_pages
            }
          }
        )
      end

      def show
        authorize @customer

        render_success(
          message: "Customer fetched successfully.",
          data: {
            customer: @customer.as_json(
              only: %i[id name email phone created_at]
            )
          }
        )
      end

      def orders
        authorize @customer

        orders = @customer.orders
                         .includes(:order_items)
                         .order(created_at: :desc)

        render_success(
          message: "Customer orders fetched successfully.",
          data: {
            orders: orders.as_json(
              include: {
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
        authorize @customer

        @customer.update!(customer_params)

        render_success(
          message: "Customer updated successfully.",
          data: {
            customer: @customer.as_json(
              only: %i[id name email phone created_at]
            )
          }
        )
      end

      private

      def set_customer
        @customer = Customer.find(params[:id])
      end

      def customer_params
        params.require(:customer).permit(:name, :email, :phone)
      end
    end
  end
end
