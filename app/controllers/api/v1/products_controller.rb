# frozen_string_literal: true

module Api
  module V1
    class ProductsController < BaseController
      before_action :authenticate_user!
      before_action :set_product, only: %i[show update destroy]

      def index
        authorize Product

        products = Product.includes(:category)

        if params[:category_id].present?
          products = products.where(category_id: params[:category_id])
        end

        if params[:search].present?
          search = "%#{params[:search]}%"

          products = products.where(
            "name ILIKE :search OR description ILIKE :search OR slug ILIKE :search",
            search: search
          )
        end

        min_price = parse_price_filter(params[:min_price], "Minimum")
        max_price = parse_price_filter(params[:max_price], "Maximum")

        if min_price && max_price && min_price > max_price
          render_error(
            message: "Minimum price cannot be greater than maximum price.",
            errors: [
              {
                code: "INVALID_PRICE_RANGE",
                message: "Minimum price cannot be greater than maximum price."
              }
            ],
            status: :unprocessable_content
          )

          return
        end

        if min_price
          products = products.where("price >= ?", min_price)
        end

        if max_price
          products = products.where("price <= ?", max_price)
        end

        if params[:status].present?
          unless Product::STATUSES.include?(params[:status])
            render_error(
              message: "Invalid product status.",
              errors: [
                {
                  code: "INVALID_PRODUCT_STATUS",
                  message: "Invalid product status."
                }
              ],
              status: :unprocessable_content
            )

            return
          end

          products = products.where(status: params[:status])
        end

        allowed_sort_columns = %w[name price created_at]
        allowed_sort_orders = %w[asc desc]

        sort_by = params.fetch(:sort_by, "created_at")
        sort_order = params.fetch(:sort_order, "desc")

        sort_by = "created_at" unless allowed_sort_columns.include?(sort_by)
        sort_order = "desc" unless allowed_sort_orders.include?(sort_order)

        products = products.order(sort_by => sort_order)

        page = params.fetch(:page, 1).to_i
        per_page = params.fetch(:per_page, 20).to_i

        page = 1 if page < 1
        per_page = 20 if per_page < 1
        per_page = 100 if per_page > 100

        pagy, products = pagy(
          :offset,
          products,
          page: page,
          limit: per_page
        )

        render_success(
          message: "Products fetched successfully.",
          data: {
            products: products.as_json(
              include: {
                category: {
                  only: %i[id name slug]
                }
              }
            ),
            meta: {
              page: pagy.page,
              per_page: pagy.limit,
              total: pagy.count,
              total_pages: pagy.pages
            }
          }
        )
      rescue ArgumentError => e
        render_error(
          message: e.message,
          errors: [
            {
              code: "INVALID_PRICE_FILTER",
              message: e.message
            }
          ],
          status: :unprocessable_content
        )
      end

      def show
        authorize @product

        render_success(
          message: "Product fetched successfully.",
          data: {
            product: @product.as_json(
              include: {
                category: {
                  only: %i[id name slug]
                }
              }
            )
          }
        )
      end

      def create
        product = Product.new(product_params)

        if product.category_id.present?
          product.category = Category.find(product.category_id)
        end

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

        params = product_params

        if params[:category_id].present?
          @product.category = Category.find(params[:category_id])
        end

        if @product.update(params)
          render_success(
            message: "Product updated successfully.",
            data: {
              product: @product.as_json(
                include: {
                  category: {
                    only: %i[id name slug]
                  }
                }
              )
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

        if @product.destroy
          render_success(
            message: "Product deleted successfully."
          )
        else
          render_error(
            message: "Product could not be deleted.",
            errors: @product.errors.full_messages,
            status: :unprocessable_content
          )
        end
      end

      private

      def set_product
        @product = Product.includes(:category).find(params[:id])
      end

      def product_params
        params.require(:product).permit(
          :name,
          :slug,
          :description,
          :price,
          :status,
          :category_id
        )
      end

      def parse_price_filter(value, name)
        return nil if value.blank?

        Float(value)
      rescue ArgumentError, TypeError
        raise ArgumentError, "#{name} price must be a valid number."
      end
    end
  end
end
