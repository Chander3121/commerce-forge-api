# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Api::V1::Products", type: :request do
  describe "GET /api/v1/products" do
    let!(:product) { create(:product) }

    context "when user is not authenticated" do
      it "returns unauthorized" do
        get "/api/v1/products"

        expect(response).to have_http_status(:unauthorized)

        body = JSON.parse(response.body)

        expect(body).to eq(
          "success" => false,
          "message" => "Authentication failed.",
          "data" => {},
          "errors" => [
            {
              "code" => "AUTHENTICATION_FAILED",
              "message" => "Authentication failed."
            }
          ]
        )
      end
    end

    context "when user is authenticated" do
      context "when user has products.read permission" do
        let(:user) { create(:user) }

        before do
          role = create(:role)

          permission = create(
            :permission,
            name: "View Products",
            code: "products.read"
          )

          create(
            :role_permission,
            role: role,
            permission: permission
          )

          create(
            :user_role,
            user: user,
            role: role
          )
        end

        it "returns products" do
          get "/api/v1/products",
              headers: authenticated_headers(user)

          expect(response).to have_http_status(:ok)

          body = JSON.parse(response.body)

          expect(body["success"]).to be(true)
          expect(body["message"]).to eq("Products fetched successfully.")
          expect(body["data"]["products"]).to be_an(Array)
          expect(body["data"]["products"].first["id"]).to eq(product.id)
        end

        it "paginates products" do
          create_list(:product, 24)

          get "/api/v1/products",
              params: {
                page: 2,
                per_page: 10
              },
              headers: authenticated_headers(user)

          expect(response).to have_http_status(:ok)

          body = JSON.parse(response.body)

          expect(body["data"]["products"].size).to eq(10)
          expect(body["data"]["meta"]).to include(
            "page" => 2,
            "per_page" => 10,
            "total" => 25,
            "total_pages" => 3
          )
        end

        it "uses the default page size when per_page is invalid" do
          create_list(:product, 25)

          get "/api/v1/products",
              params: {
                page: 1,
                per_page: 0
              },
              headers: authenticated_headers(user)

          expect(response).to have_http_status(:ok)

          body = JSON.parse(response.body)

          expect(body["data"]["products"].size).to eq(20)
          expect(body["data"]["meta"]).to include(
            "page" => 1,
            "per_page" => 20,
            "total" => 26,
            "total_pages" => 2
          )
        end

        it "filters products by category" do
          category = create(:category)
          other_category = create(:category)

          create(:product, category: category)
          create(:product, category: category)
          create(:product, category: other_category)

          get "/api/v1/products",
              params: {
                category_id: category.id
              },
              headers: authenticated_headers(user)

          expect(response).to have_http_status(:ok)

          body = JSON.parse(response.body)

          products = body["data"]["products"]

          expect(products.size).to eq(2)
          expect(
            products.map { |product| product["category_id"] }.uniq
          ).to eq([ category.id.to_s ])
        end

        it "searches products by name" do
          create(
            :product,
            name: "MacBook Pro",
            slug: "macbook-pro"
          )

          create(
            :product,
            name: "iPhone 17",
            slug: "iphone-17"
          )

          get "/api/v1/products",
              params: {
                search: "MacBook"
              },
              headers: authenticated_headers(user)

          expect(response).to have_http_status(:ok)

          body = JSON.parse(response.body)

          products = body["data"]["products"]

          expect(products.size).to eq(1)
          expect(products.first["name"]).to eq("MacBook Pro")
        end

        it "combines category filtering with search" do
          category = create(:category)
          other_category = create(:category)

          create(
            :product,
            category: category,
            name: "White Shirt",
            slug: "white-shirt"
          )

          create(
            :product,
            category: category,
            name: "Black Shoes",
            slug: "black-shoes"
          )

          create(
            :product,
            category: other_category,
            name: "Blue Shirt",
            slug: "blue-shirt"
          )

          get "/api/v1/products",
              params: {
                category_id: category.id,
                search: "shirt"
              },
              headers: authenticated_headers(user)

          expect(response).to have_http_status(:ok)

          body = JSON.parse(response.body)

          products = body["data"]["products"]

          expect(products.size).to eq(1)
          expect(products.first["name"]).to eq("White Shirt")
          expect(products.first["category_id"]).to eq(category.id.to_s)
        end

        it "sorts products by price in ascending order" do
          create(:product, name: "Expensive", price: 3000)
          create(:product, name: "Cheap", price: 1000)

          get "/api/v1/products",
              params: {
                sort_by: "price",
                sort_order: "asc"
              },
              headers: authenticated_headers(user)

          expect(response).to have_http_status(:ok)

          body = JSON.parse(response.body)
          products = body["data"]["products"]

          prices = products.map { |product| product["price"].to_f }

          expect(prices).to eq(prices.sort)
        end

        it "falls back to default sorting when sort parameters are invalid" do
          old_product = create(
            :product,
            name: "Old Product",
            created_at: 2.days.ago
          )

          new_product = create(
            :product,
            name: "New Product",
            created_at: 1.day.ago
          )

          get "/api/v1/products",
              params: {
                sort_by: "password",
                sort_order: "invalid"
              },
              headers: authenticated_headers(user)

          expect(response).to have_http_status(:ok)

          body = JSON.parse(response.body)
          products = body["data"]["products"]

          expect(products.map { |product| product["id"] }).to eq(
            [ product.id, new_product.id, old_product.id ].map(&:to_s)
          )
        end

        it "filters products by price range" do
          create(:product, name: "Cheap Product", price: 500)
          create(:product, name: "Mid Product", price: 2500)
          create(:product, name: "Expensive Product", price: 8000)

          get "/api/v1/products",
              params: {
                min_price: 1000,
                max_price: 5000
              },
              headers: authenticated_headers(user)

          expect(response).to have_http_status(:ok)

          body = JSON.parse(response.body)

          products = body["data"]["products"]

          expect(products.map { |product| product["name"] }).to include(
            "Mid Product"
          )

          expect(products.map { |product| product["name"] }).not_to include(
            "Cheap Product",
            "Expensive Product"
          )
        end

        it "returns an error for an invalid minimum price" do
          get "/api/v1/products",
              params: {
                min_price: "abc"
              },
              headers: authenticated_headers(user)

          expect(response).to have_http_status(:unprocessable_content)

          body = JSON.parse(response.body)

          expect(body["success"]).to be(false)
          expect(body["errors"]).to include(
            "code" => "INVALID_PRICE_FILTER",
            "message" => "Minimum price must be a valid number."
          )
        end

        it "rejects a price range when minimum price is greater than maximum price" do
          get "/api/v1/products",
              params: {
                min_price: 5000,
                max_price: 1000
              },
              headers: authenticated_headers(user)

          expect(response).to have_http_status(:unprocessable_content)

          body = JSON.parse(response.body)

          expect(body["success"]).to be(false)
          expect(body["errors"]).to include(
            "code" => "INVALID_PRICE_RANGE",
            "message" => "Minimum price cannot be greater than maximum price."
          )
        end

        it "filters products by status" do
          create(:product, name: "Active Product", status: "active")
          create(:product, name: "Inactive Product", status: "inactive")

          get "/api/v1/products",
              params: {
                status: "active"
              },
              headers: authenticated_headers(user)

          expect(response).to have_http_status(:ok)

          body = JSON.parse(response.body)

          products = body["data"]["products"]

          expect(products.map { |product| product["name"] }).to include(
            "Active Product"
          )

          expect(products.map { |product| product["name"] }).not_to include(
            "Inactive Product"
          )
        end

        it "rejects an invalid product status" do
          get "/api/v1/products",
              params: {
                status: "banana"
              },
              headers: authenticated_headers(user)

          expect(response).to have_http_status(:unprocessable_content)

          body = JSON.parse(response.body)

          expect(body["success"]).to be(false)
          expect(body["errors"]).to include(
            "code" => "INVALID_PRODUCT_STATUS",
            "message" => "Invalid product status."
          )
        end

        it "returns product category details" do
          category = create(
            :category,
            name: "Electronics",
            slug: "electronics"
          )

          product = create(
            :product,
            category: category
          )

          get "/api/v1/products",
              headers: authenticated_headers(user)

          expect(response).to have_http_status(:ok)

          body = JSON.parse(response.body)

          returned_product = body["data"]["products"].find do |item|
            item["id"] == product.id.to_s
          end

          expect(returned_product["category"]).to include(
            "id" => category.id.to_s,
            "name" => "Electronics",
            "slug" => "electronics"
          )
        end
      end

      context "when user does not have products.read permission" do
        let(:user) { create(:user) }

        it "returns forbidden" do
          get "/api/v1/products",
              headers: authenticated_headers(user)

          expect(response).to have_http_status(:forbidden)

          body = JSON.parse(response.body)

          expect(body).to eq(
            "success" => false,
            "message" => "You are not authorized to perform this action.",
            "data" => {},
            "errors" => [
              {
                "code" => "AUTHORIZATION_FAILED",
                "message" => "You are not authorized to perform this action."
              }
            ]
          )
        end
      end
    end
  end

  describe "POST /api/v1/products" do
    let(:product_params) do
      {
        product: {
          name: "MacBook Pro",
          slug: "macbook-pro",
          description: "Professional laptop.",
          price: 1999.99,
          status: "active",
          category_id: category.id
        }
      }
    end

    let(:category) { create(:category) }

    context "when user is not authenticated" do
      it "returns unauthorized" do
        post "/api/v1/products",
             params: product_params,
             as: :json

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context "when user is authenticated" do
      context "when user does not have products.create permission" do
        let(:user) { create(:user) }

        it "returns forbidden" do
          post "/api/v1/products",
               params: product_params,
               headers: authenticated_headers(user),
               as: :json

          expect(response).to have_http_status(:forbidden)

          body = JSON.parse(response.body)

          expect(body["success"]).to be(false)
          expect(body["errors"]).to include(
            "code" => "AUTHORIZATION_FAILED",
            "message" => "You are not authorized to perform this action."
          )
        end
      end

      context "when user has products.create permission" do
        let(:user) { create(:user) }

        before do
          role = create(:role)

          permission = create(
            :permission,
            name: "Create Products",
            code: "products.create"
          )

          create(
            :role_permission,
            role: role,
            permission: permission
          )

          create(
            :user_role,
            user: user,
            role: role
          )
        end

        it "creates the product" do
          expect do
            post "/api/v1/products",
                 params: product_params,
                 headers: authenticated_headers(user),
                 as: :json
          end.to change(Product, :count).by(1)

          expect(response).to have_http_status(:created)

          body = JSON.parse(response.body)

          expect(body["success"]).to be(true)
          expect(body["message"]).to eq("Product created successfully.")
          expect(body["data"]["product"]["name"]).to eq("MacBook Pro")
          expect(body["data"]["product"]["category_id"]).to eq(category.id.to_s)
        end

        it "returns an error when product parameters are missing" do
          post "/api/v1/products",
               params: {},
               headers: authenticated_headers(user),
               as: :json

          expect(response).to have_http_status(:unprocessable_content)

          body = JSON.parse(response.body)

          expect(body).to eq(
            "success" => false,
            "message" => "Required parameter missing.",
            "data" => {},
            "errors" => [
              {
                "code" => "PARAMETER_MISSING",
                "message" => "Required parameter missing: product"
              }
            ]
          )
        end

        it "creates a product with a category" do
          category = create(:category)

          params = {
            product: {
              name: "Nike Air",
              slug: "nike-air",
              description: "Running shoes",
              price: 4999,
              status: "active",
              category_id: category.id
            }
          }

          expect {
            post "/api/v1/products",
                 params: params,
                 headers: authenticated_headers(user),
                 as: :json
          }.to change(Product, :count).by(1)

          expect(response).to have_http_status(:created)

          product = Product.order(:created_at).last

          expect(product.category_id).to eq(category.id)
        end

        it "returns not found when the category does not exist" do
          params = {
            product: {
              name: "Nike Air",
              slug: "nike-air-invalid-category",
              description: "Running shoes",
              price: 4999,
              status: "active",
              category_id: SecureRandom.uuid
            }
          }

          expect {
            post "/api/v1/products",
                 params: params,
                 headers: authenticated_headers(user),
                 as: :json
          }.not_to change(Product, :count)

          expect(response).to have_http_status(:not_found)

          body = JSON.parse(response.body)

          expect(body["errors"]).to include(
            "code" => "RESOURCE_NOT_FOUND",
            "message" => "Category not found."
          )
        end
      end
    end
  end

  describe "GET /api/v1/products/:id" do
    let!(:product) { create(:product) }

    context "when user is not authenticated" do
      it "returns unauthorized" do
        get "/api/v1/products/#{product.id}"

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context "when user is authenticated" do
      context "when user does not have products.read permission" do
        let(:user) { create(:user) }

        it "returns forbidden" do
          get "/api/v1/products/#{product.id}",
              headers: authenticated_headers(user)

          expect(response).to have_http_status(:forbidden)

          body = JSON.parse(response.body)

          expect(body["success"]).to be(false)
          expect(body["errors"]).to include(
            "code" => "AUTHORIZATION_FAILED",
            "message" => "You are not authorized to perform this action."
          )
        end
      end

      context "when user has products.read permission" do
        let(:user) { create(:user) }

        before do
          role = create(:role)

          permission = create(
            :permission,
            name: "View Products",
            code: "products.read"
          )

          create(
            :role_permission,
            role: role,
            permission: permission
          )

          create(
            :user_role,
            user: user,
            role: role
          )
        end

        it "returns the product" do
          get "/api/v1/products/#{product.id}",
              headers: authenticated_headers(user)

          expect(response).to have_http_status(:ok)

          body = JSON.parse(response.body)

          expect(body["success"]).to be(true)
          expect(body["message"]).to eq("Product fetched successfully.")
          expect(body["data"]["product"]["id"]).to eq(product.id)
          expect(body["data"]["product"]["name"]).to eq(product.name)
        end

        it "returns product category details" do
          category = create(
            :category,
            name: "Electronics",
            slug: "electronics"
          )

          product = create(
            :product,
            category: category
          )

          get "/api/v1/products/#{product.id}",
              headers: authenticated_headers(user)

          expect(response).to have_http_status(:ok)

          body = JSON.parse(response.body)

          expect(body["data"]["product"]["category"]).to include(
            "id" => category.id.to_s,
            "name" => "Electronics",
            "slug" => "electronics"
          )
        end
      end

      context "when product does not exist" do
        let(:user) { create(:user) }

        before do
          role = create(:role)

          permission = create(
            :permission,
            name: "View Products",
            code: "products.read"
          )

          create(
            :role_permission,
            role: role,
            permission: permission
          )

          create(
            :user_role,
            user: user,
            role: role
          )
        end

        it "returns not found" do
          get "/api/v1/products/#{SecureRandom.uuid}",
              headers: authenticated_headers(user)

          expect(response).to have_http_status(:not_found)

          body = JSON.parse(response.body)

          expect(body).to eq(
            "success" => false,
            "message" => "Product not found.",
            "data" => {},
            "errors" => [
              {
                "code" => "RESOURCE_NOT_FOUND",
                "message" => "Product not found."
              }
            ]
          )
        end
      end
    end
  end

  describe "PATCH /api/v1/products/:id" do
    let!(:product) { create(:product) }

    let(:product_params) do
      {
        product: {
          name: "Updated Product",
          price: 2499.99
        }
      }
    end

    context "when user is not authenticated" do
      it "returns unauthorized" do
        patch "/api/v1/products/#{product.id}",
              params: product_params,
              as: :json

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context "when user is authenticated" do
      context "when user does not have products.update permission" do
        let(:user) { create(:user) }

        it "returns forbidden" do
          patch "/api/v1/products/#{product.id}",
                params: product_params,
                headers: authenticated_headers(user),
                as: :json

          expect(response).to have_http_status(:forbidden)

          body = JSON.parse(response.body)

          expect(body["success"]).to be(false)
          expect(body["errors"]).to include(
            "code" => "AUTHORIZATION_FAILED",
            "message" => "You are not authorized to perform this action."
          )
        end
      end

      context "when user has products.update permission" do
        let(:user) { create(:user) }

        before do
          role = create(:role)

          permission = create(
            :permission,
            name: "Update Products",
            code: "products.update"
          )

          create(
            :role_permission,
            role: role,
            permission: permission
          )

          create(
            :user_role,
            user: user,
            role: role
          )
        end

        it "updates the product" do
          patch "/api/v1/products/#{product.id}",
                params: product_params,
                headers: authenticated_headers(user),
                as: :json

          expect(response).to have_http_status(:ok)

          expect(product.reload.name).to eq("Updated Product")
          expect(product.price).to eq(2499.99)

          body = JSON.parse(response.body)

          expect(body["success"]).to be(true)
          expect(body["message"]).to eq("Product updated successfully.")
          expect(body["data"]["product"]["id"]).to eq(product.id)
        end

        it "updates the product category" do
          old_category = create(:category)
          new_category = create(:category)

          product.update!(category: old_category)

          params = {
            product: {
              category_id: new_category.id
            }
          }

          patch "/api/v1/products/#{product.id}",
                params: params,
                headers: authenticated_headers(user),
                as: :json

          expect(response).to have_http_status(:ok)
          expect(product.reload.category_id).to eq(new_category.id)
        end

        it "returns not found when the new category does not exist" do
          old_category = create(:category)

          product.update!(category: old_category)

          params = {
            product: {
              category_id: SecureRandom.uuid
            }
          }

          patch "/api/v1/products/#{product.id}",
                params: params,
                headers: authenticated_headers(user),
                as: :json

          expect(response).to have_http_status(:not_found)

          body = JSON.parse(response.body)

          expect(body["errors"]).to include(
            "code" => "RESOURCE_NOT_FOUND",
            "message" => "Category not found."
          )

          expect(product.reload.category_id).to eq(old_category.id)
        end

        it "returns product category details after update" do
          old_category = create(:category)
          new_category = create(
            :category,
            name: "Electronics",
            slug: "electronics"
          )

          product.update!(category: old_category)

          patch "/api/v1/products/#{product.id}",
                params: {
                  product: {
                    category_id: new_category.id
                  }
                },
                headers: authenticated_headers(user),
                as: :json

          expect(response).to have_http_status(:ok)

          body = JSON.parse(response.body)

          expect(body["data"]["product"]["category"]).to include(
            "id" => new_category.id.to_s,
            "name" => "Electronics",
            "slug" => "electronics"
          )
        end
      end
    end
  end

  describe "DELETE /api/v1/products/:id" do
    let!(:product) { create(:product) }

    context "when user is not authenticated" do
      it "returns unauthorized" do
        delete "/api/v1/products/#{product.id}"

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context "when user is authenticated" do
      context "when user does not have products.delete permission" do
        let(:user) { create(:user) }

        it "returns forbidden" do
          delete "/api/v1/products/#{product.id}",
                 headers: authenticated_headers(user)

          expect(response).to have_http_status(:forbidden)

          body = JSON.parse(response.body)

          expect(body["success"]).to be(false)
          expect(body["errors"]).to include(
            "code" => "AUTHORIZATION_FAILED",
            "message" => "You are not authorized to perform this action."
          )
        end
      end

      context "when user has products.delete permission" do
        let(:user) { create(:user) }

        before do
          role = create(:role)

          permission = create(
            :permission,
            name: "Delete Products",
            code: "products.delete"
          )

          create(
            :role_permission,
            role: role,
            permission: permission
          )

          create(
            :user_role,
            user: user,
            role: role
          )
        end

        it "deletes the product" do
          expect do
            delete "/api/v1/products/#{product.id}",
                   headers: authenticated_headers(user)
          end.to change(Product, :count).by(-1)

          expect(response).to have_http_status(:ok)

          body = JSON.parse(response.body)

          expect(body["success"]).to be(true)
          expect(body["message"]).to eq("Product deleted successfully.")
          expect(body["data"]).to eq({})
        end

        it "returns not found when the product does not exist" do
          delete "/api/v1/products/#{SecureRandom.uuid}",
                 headers: authenticated_headers(user)

          expect(response).to have_http_status(:not_found)

          body = JSON.parse(response.body)

          expect(body["success"]).to be(false)
          expect(body["errors"]).to include(
            "code" => "RESOURCE_NOT_FOUND",
            "message" => "Product not found."
          )
        end

        it "does not delete a product that belongs to an order" do
          customer = create(:customer)

          order = create(
            :order,
            customer: customer,
            user: user
          )

          create(
            :order_item,
            order: order,
            product: product
          )

          expect {
            delete "/api/v1/products/#{product.id}",
                   headers: authenticated_headers(user)
          }.not_to change(Product, :count)

          expect(response).to have_http_status(:unprocessable_content)

          body = JSON.parse(response.body)

          expect(body["success"]).to be(false)
        end
      end
    end
  end
end
