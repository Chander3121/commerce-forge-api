# frozen_string_literal: true

module Api
  module V1
    class CategoriesController < BaseController
      before_action :authenticate_user!
      before_action :set_category, only: %i[ show update destroy ]

      def index
        authorize Category

        categories = Category.order(created_at: :desc)

        render_success(
          message: "Categories fetched successfully.",
          data: {
            categories: categories
          }
        )
      end

      def show
        authorize @category

        render_success(
          message: "Category fetched successfully.",
          data: {
            category: @category
          }
        )
      end

      def create
        category = Category.new(category_params)

        authorize category

        if category.save
          render_success(
            message: "Category created successfully.",
            data: {
              category: category
            },
            status: :created
          )
        else
          render_error(
            message: "Category could not be created.",
            errors: category.errors.full_messages
          )
        end
      end

      def update
        authorize @category

        if @category.update(category_params)
          render_success(
            message: "Category updated successfully.",
            data: {
              category: @category
            }
          )
        else
          render_error(
            message: "Category could not be updated.",
            errors: @category.errors.full_messages
          )
        end
      end

      def destroy
        authorize @category

        @category.destroy!

        render_success(
          message: "Category deleted successfully."
        )
      end

      private

      def set_category
        @category = Category.find(params[:id])
      end

      def category_params
        params.require(:category).permit(
          :name,
          :slug,
          :description
        )
      end
    end
  end
end
