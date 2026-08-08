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
          status: "active"
        }
      }
    end

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
      end
    end
  end
end
