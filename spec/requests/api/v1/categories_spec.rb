# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Api::V1::Categories", type: :request do
  describe "GET /api/v1/categories" do
    let!(:category) { create(:category) }

    context "when user is not authenticated" do
      it "returns unauthorized" do
        get "/api/v1/categories"

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
      context "when user has categories.read permission" do
        let(:user) { create(:user) }

        before do
          role = create(:role)

          permission = create(
            :permission,
            name: "View Categories",
            code: "categories.read"
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

        it "returns categories" do
          get "/api/v1/categories",
              headers: authenticated_headers(user)

          expect(response).to have_http_status(:ok)

          body = JSON.parse(response.body)

          expect(body["success"]).to be(true)
          expect(body["message"]).to eq("Categories fetched successfully.")
          expect(body["data"]["categories"]).to be_an(Array)
          expect(body["data"]["categories"].first["id"]).to eq(category.id)
        end
      end

      context "when user does not have categories.read permission" do
        let(:user) { create(:user) }

        it "returns forbidden" do
          get "/api/v1/categories",
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

  describe "GET /api/v1/categories/:id" do
    let!(:category) { create(:category) }

    context "when user is not authenticated" do
      it "returns unauthorized" do
        get "/api/v1/categories/#{category.id}"

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context "when user is authenticated" do
      context "when user does not have categories.read permission" do
        let(:user) { create(:user) }

        it "returns forbidden" do
          get "/api/v1/categories/#{category.id}",
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

      context "when user has categories.read permission" do
        let(:user) { create(:user) }

        before do
          role = create(:role)

          permission = create(
            :permission,
            name: "View Categories",
            code: "categories.read"
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

        it "returns the category" do
          get "/api/v1/categories/#{category.id}",
              headers: authenticated_headers(user)

          expect(response).to have_http_status(:ok)

          body = JSON.parse(response.body)

          expect(body["success"]).to be(true)
          expect(body["message"]).to eq("Category fetched successfully.")
          expect(body["data"]["category"]["id"]).to eq(category.id)
          expect(body["data"]["category"]["name"]).to eq(category.name)
        end
      end

      context "when category does not exist" do
        let(:user) { create(:user) }

        before do
          role = create(:role)

          permission = create(
            :permission,
            name: "View Categories",
            code: "categories.read"
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
          get "/api/v1/categories/#{SecureRandom.uuid}",
              headers: authenticated_headers(user)

          expect(response).to have_http_status(:not_found)

          body = JSON.parse(response.body)

          expect(body).to eq(
            "success" => false,
            "message" => "Category not found.",
            "data" => {},
            "errors" => [
              {
                "code" => "RESOURCE_NOT_FOUND",
                "message" => "Category not found."
              }
            ]
          )
        end
      end
    end
  end

  describe "POST /api/v1/categories" do
    let(:category_params) do
      {
        category: {
          name: "Electronics",
          slug: "electronics",
          description: "Electronic products."
        }
      }
    end

    context "when user is not authenticated" do
      it "returns unauthorized" do
        post "/api/v1/categories",
             params: category_params,
             as: :json

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context "when user is authenticated" do
      context "when user does not have categories.create permission" do
        let(:user) { create(:user) }

        it "returns forbidden" do
          post "/api/v1/categories",
               params: category_params,
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

      context "when user has categories.create permission" do
        let(:user) { create(:user) }

        before do
          role = create(:role)

          permission = create(
            :permission,
            name: "Create Categories",
            code: "categories.create"
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

        it "creates the category" do
          expect do
            post "/api/v1/categories",
                 params: category_params,
                 headers: authenticated_headers(user),
                 as: :json
          end.to change(Category, :count).by(1)

          expect(response).to have_http_status(:created)

          body = JSON.parse(response.body)

          expect(body["success"]).to be(true)
          expect(body["message"]).to eq("Category created successfully.")
          expect(body["data"]["category"]["name"]).to eq("Electronics")
          expect(body["data"]["category"]["slug"]).to eq("electronics")
        end
      end
    end
  end

  describe "PATCH /api/v1/categories/:id" do
    let!(:category) { create(:category) }

    let(:category_params) do
      {
        category: {
          name: "Updated Electronics",
          description: "Updated category description."
        }
      }
    end

    context "when user is not authenticated" do
      it "returns unauthorized" do
        patch "/api/v1/categories/#{category.id}",
              params: category_params,
              as: :json

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context "when user is authenticated" do
      context "when user does not have categories.update permission" do
        let(:user) { create(:user) }

        it "returns forbidden" do
          patch "/api/v1/categories/#{category.id}",
                params: category_params,
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

      context "when user has categories.update permission" do
        let(:user) { create(:user) }

        before do
          role = create(:role)

          permission = create(
            :permission,
            name: "Update Categories",
            code: "categories.update"
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

        it "updates the category" do
          patch "/api/v1/categories/#{category.id}",
                params: category_params,
                headers: authenticated_headers(user),
                as: :json

          expect(response).to have_http_status(:ok)

          category.reload

          expect(category.name).to eq("Updated Electronics")
          expect(category.description).to eq("Updated category description.")

          body = JSON.parse(response.body)

          expect(body["success"]).to be(true)
          expect(body["message"]).to eq("Category updated successfully.")
          expect(body["data"]["category"]["id"]).to eq(category.id)
        end
      end
    end
  end

  describe "DELETE /api/v1/categories/:id" do
    let!(:category) { create(:category) }

    context "when user is not authenticated" do
      it "returns unauthorized" do
        delete "/api/v1/categories/#{category.id}"

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context "when user is authenticated" do
      context "when user does not have categories.delete permission" do
        let(:user) { create(:user) }

        it "returns forbidden" do
          delete "/api/v1/categories/#{category.id}",
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

      context "when user has categories.delete permission" do
        let(:user) { create(:user) }

        before do
          role = create(:role)

          permission = create(
            :permission,
            name: "Delete Categories",
            code: "categories.delete"
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

        it "deletes the category" do
          expect do
            delete "/api/v1/categories/#{category.id}",
                   headers: authenticated_headers(user)
          end.to change(Category, :count).by(-1)

          expect(response).to have_http_status(:ok)

          body = JSON.parse(response.body)

          expect(body["success"]).to be(true)
          expect(body["message"]).to eq("Category deleted successfully.")
          expect(body["data"]).to eq({})
        end
      end
    end
  end
end
