# frozen_string_literal: true

module Api
  module V1
    class ProductsController < BaseController
      before_action :authenticate_user!
      before_action :set_product, only: %i[show update destroy]

      def index
        authorize Product

        products = Product.order(created_at: :desc)

        render_success(
          message: "Products fetched successfully.",
          data: {
            products: products
          }
        )
      end

      def show
        authorize @product

        render_success(
          message: "Product fetched successfully.",
          data: {
            product: @product
          }
        )
      end

      def create
        product = Product.new(product_params)

        authorize product

        if product.save
          render_success(
            message: "Product created successfully.",
            data: {
              product: product
            },
            status: :created
          )
        else
          render_error(
            message: "Product could not be created.",
            errors: product.errors.full_messages
          )
        end
      end

      def update
        authorize @product

        if @product.update(product_params)
          render_success(
            message: "Product updated successfully.",
            data: {
              product: @product
            }
          )
        else
          render_error(
            message: "Product could not be updated.",
            errors: @product.errors.full_messages
          )
        end
      end

      def destroy
        authorize @product

        @product.destroy!

        render_success(
          message: "Product deleted successfully."
        )
      end

      private

      def set_product
        @product = Product.find(params[:id])
      end

      def product_params
        params.require(:product).permit(
          :name,
          :slug,
          :description,
          :price,
          :status
        )
      end
    end
  end
end
