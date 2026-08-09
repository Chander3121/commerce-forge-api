# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Api::V1::Customers", type: :request do
  describe "GET /api/v1/customers" do
    let!(:customer) { create(:customer) }

    context "when user is not authenticated" do
      it "returns unauthorized" do
        get "/api/v1/customers"

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context "when user is authenticated" do
      context "when user does not have customers.read permission" do
        let(:user) { create(:user) }

        it "returns forbidden" do
          get "/api/v1/customers",
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

      context "when user has customers.read permission" do
        let(:user) { create(:user) }

        before do
          role = create(:role)

          permission = create(
            :permission,
            name: "View Customers",
            code: "customers.read"
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

        it "returns customers" do
          get "/api/v1/customers",
              headers: authenticated_headers(user)

          expect(response).to have_http_status(:ok)

          body = JSON.parse(response.body)

          expect(body["success"]).to be(true)
          expect(body["message"]).to eq("Customers fetched successfully.")
          expect(body["data"]["customers"]).to be_an(Array)

          returned_customer = body["data"]["customers"].first

          expect(returned_customer["id"]).to eq(customer.id)
          expect(returned_customer["name"]).to eq(customer.name)
          expect(returned_customer["email"]).to eq(customer.email)
        end

        it "paginates customers" do
          create_list(:customer, 25)

          get "/api/v1/customers",
              params: {
                page: 1,
                per_page: 10
              },
              headers: authenticated_headers(user)

          expect(response).to have_http_status(:ok)

          body = JSON.parse(response.body)

          expect(body["data"]["customers"].size).to eq(10)

          expect(body["data"]["meta"]["page"]).to eq(1)
          expect(body["data"]["meta"]["per_page"]).to eq(10)
          expect(body["data"]["meta"]["total"]).to eq(26)
          expect(body["data"]["meta"]["total_pages"]).to eq(3)
        end

        it "returns the second page of customers" do
          create_list(:customer, 25)

          get "/api/v1/customers",
              params: {
                page: 2,
                per_page: 10
              },
              headers: authenticated_headers(user)

          expect(response).to have_http_status(:ok)

          body = JSON.parse(response.body)

          expect(body["data"]["customers"].size).to eq(10)
          expect(body["data"]["meta"]["page"]).to eq(2)
        end

        it "uses the default per_page when per_page is invalid" do
          create_list(:customer, 5)

          get "/api/v1/customers",
              params: {
                page: 1,
                per_page: 0
              },
              headers: authenticated_headers(user)

          expect(response).to have_http_status(:ok)

          body = JSON.parse(response.body)

          expect(body["data"]["meta"]["per_page"]).to eq(20)
        end

        it "uses page 1 when page is invalid" do
          create_list(:customer, 25)

          get "/api/v1/customers",
              params: {
                page: 0,
                per_page: 10
              },
              headers: authenticated_headers(user)

          expect(response).to have_http_status(:ok)

          body = JSON.parse(response.body)

          expect(body["data"]["customers"].size).to eq(10)
          expect(body["data"]["meta"]["page"]).to eq(1)
        end

        it "sorts customers by name ascending" do
          create(:customer, name: "Zoya")
          create(:customer, name: "Amit")

          get "/api/v1/customers",
              params: {
                sort_by: "name",
                sort_order: "asc"
              },
              headers: authenticated_headers(user)

          expect(response).to have_http_status(:ok)

          body = JSON.parse(response.body)

          customers = body["data"]["customers"]

          names = customers.map { |customer| customer["name"] }

          expect(names).to eq(names.sort)
        end

        it "sorts customers by name descending" do
          create(:customer, name: "Amit")
          create(:customer, name: "Zoya")

          get "/api/v1/customers",
              params: {
                sort_by: "name",
                sort_order: "desc"
              },
              headers: authenticated_headers(user)

          expect(response).to have_http_status(:ok)

          body = JSON.parse(response.body)

          customers = body["data"]["customers"]

          names = customers.map { |customer| customer["name"] }

          expect(names).to eq(names.sort.reverse)
        end

        it "uses default sorting for an invalid sort field" do
          first_customer = create(:customer, name: "Zoya")
          second_customer = create(:customer, name: "Amit")

          get "/api/v1/customers",
              params: {
                sort_by: "invalid_column",
                sort_order: "asc"
              },
              headers: authenticated_headers(user)

          expect(response).to have_http_status(:ok)

          body = JSON.parse(response.body)

          customers = body["data"]["customers"]

          expect(customers).to be_an(Array)
        end

        it "uses default sorting for an invalid sort order" do
          get "/api/v1/customers",
              params: {
                sort_by: "name",
                sort_order: "invalid"
              },
              headers: authenticated_headers(user)

          expect(response).to have_http_status(:ok)

          body = JSON.parse(response.body)

          customers = body["data"]["customers"]

          expect(customers).to be_an(Array)
        end

        it "filters customers by name" do
          matching_customer = create(
            :customer,
            name: "Rahul Sharma"
          )

          create(
            :customer,
            name: "Amit Kumar"
          )

          get "/api/v1/customers",
              params: { search: "Rahul" },
              headers: authenticated_headers(user)

          expect(response).to have_http_status(:ok)

          body = JSON.parse(response.body)

          customers = body["data"]["customers"]

          expect(customers.size).to eq(1)
          expect(customers.first["id"]).to eq(matching_customer.id)
        end

        it "filters customers by email" do
          matching_customer = create(
            :customer,
            email: "rahul@example.com"
          )

          create(
            :customer,
            email: "amit@example.com"
          )

          get "/api/v1/customers",
              params: { search: "rahul@example.com" },
              headers: authenticated_headers(user)

          expect(response).to have_http_status(:ok)

          body = JSON.parse(response.body)

          customers = body["data"]["customers"]

          expect(customers.size).to eq(1)
          expect(customers.first["id"]).to eq(matching_customer.id)
        end

        it "filters customers by phone" do
          matching_customer = create(
            :customer,
            phone: "9123456789"
          )

          create(
            :customer,
            phone: "9876543210"
          )

          get "/api/v1/customers",
              params: { search: "9123456789" },
              headers: authenticated_headers(user)

          expect(response).to have_http_status(:ok)

          body = JSON.parse(response.body)

          customers = body["data"]["customers"]

          expect(customers.size).to eq(1)
          expect(customers.first["id"]).to eq(matching_customer.id)
        end

        it "performs case-insensitive search" do
          matching_customer = create(
            :customer,
            name: "Rahul Sharma"
          )

          get "/api/v1/customers",
              params: { search: "RAHUL" },
              headers: authenticated_headers(user)

          expect(response).to have_http_status(:ok)

          body = JSON.parse(response.body)

          customers = body["data"]["customers"]

          expect(customers.size).to eq(1)
          expect(customers.first["id"]).to eq(matching_customer.id)
        end

        it "performs partial search" do
          matching_customer = create(
            :customer,
            name: "Rahul Sharma"
          )

          get "/api/v1/customers",
              params: { search: "Rah" },
              headers: authenticated_headers(user)

          expect(response).to have_http_status(:ok)

          body = JSON.parse(response.body)

          customers = body["data"]["customers"]

          expect(customers.size).to eq(1)
          expect(customers.first["id"]).to eq(matching_customer.id)
        end
      end
    end
  end

  describe "GET /api/v1/customers/:id" do
    let!(:customer) { create(:customer) }

    context "when user is not authenticated" do
      it "returns unauthorized" do
        get "/api/v1/customers/#{customer.id}"

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context "when user is authenticated" do
      context "when user does not have customers.read permission" do
        let(:user) { create(:user) }

        it "returns forbidden" do
          get "/api/v1/customers/#{customer.id}",
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

      context "when user has customers.read permission" do
        let(:user) { create(:user) }

        before do
          role = create(:role)

          permission = create(
            :permission,
            name: "View Customers",
            code: "customers.read"
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

        it "returns the customer" do
          get "/api/v1/customers/#{customer.id}",
              headers: authenticated_headers(user)

          expect(response).to have_http_status(:ok)

          body = JSON.parse(response.body)

          expect(body["success"]).to be(true)
          expect(body["message"]).to eq("Customer fetched successfully.")

          returned_customer = body["data"]["customer"]

          expect(returned_customer["id"]).to eq(customer.id)
          expect(returned_customer["name"]).to eq(customer.name)
          expect(returned_customer["email"]).to eq(customer.email)
          expect(returned_customer["phone"]).to eq(customer.phone)
        end
      end
    end

    context "when customer does not exist" do
      let(:user) { create(:user) }

      it "returns not found" do
        get "/api/v1/customers/#{SecureRandom.uuid}",
            headers: authenticated_headers(user)

        expect(response).to have_http_status(:not_found)
      end
    end
  end

  describe "GET /api/v1/customers/:id/orders" do
    let!(:customer) { create(:customer) }

    context "when user is not authenticated" do
      it "returns unauthorized" do
        get "/api/v1/customers/#{customer.id}/orders"

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context "when user is authenticated" do
      context "when user does not have customers.read permission" do
        let(:user) { create(:user) }

        it "returns forbidden" do
          get "/api/v1/customers/#{customer.id}/orders",
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

      context "when user has customers.read permission" do
        let(:user) { create(:user) }

        before do
          role = create(:role)

          permission = create(
            :permission,
            name: "View Customers",
            code: "customers.read"
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

        it "returns the customer's orders" do
          order = create(
            :order,
            customer: customer,
            created_at: 1.day.ago
          )

          create(
            :order_item,
            order: order
          )

          create(
            :order,
            customer: customer,
            created_at: 2.days.ago
          )

          create(
            :order,
            created_at: 3.days.ago
          )

          get "/api/v1/customers/#{customer.id}/orders",
              headers: authenticated_headers(user)

          expect(response).to have_http_status(:ok)

          body = JSON.parse(response.body)

          expect(body["success"]).to be(true)
          expect(body["message"]).to eq(
            "Customer orders fetched successfully."
          )

          orders = body["data"]["orders"]

          expect(orders.size).to eq(2)
          expect(orders.first["id"]).to eq(order.id)

          expect(orders.first["order_items"]).to be_an(Array)
          expect(orders.first["order_items"].size).to eq(1)

          item = orders.first["order_items"].first

          expect(item["quantity"]).to eq(2)
          expect(item["unit_price"].to_f).to eq(500.0)
          expect(item["total_price"].to_f).to eq(1000.0)
        end
      end
    end
  end

  describe "PATCH /api/v1/customers/:id" do
    let!(:customer) { create(:customer) }

    let(:customer_params) do
      {
        customer: {
          name: "Updated Customer",
          email: "updated@commerceforge.dev",
          phone: "9999999999"
        }
      }
    end

    context "when user is not authenticated" do
      it "returns unauthorized" do
        patch "/api/v1/customers/#{customer.id}",
              params: customer_params,
              as: :json

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context "when user is authenticated" do
      context "when user does not have customers.update permission" do
        let(:user) { create(:user) }

        it "returns forbidden" do
          patch "/api/v1/customers/#{customer.id}",
                params: customer_params,
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

      context "when user has customers.update permission" do
        let(:user) { create(:user) }

        before do
          role = create(:role)

          permission = create(
            :permission,
            name: "Update Customers",
            code: "customers.update"
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

        it "updates the customer" do
          patch "/api/v1/customers/#{customer.id}",
                params: customer_params,
                headers: authenticated_headers(user),
                as: :json

          expect(response).to have_http_status(:ok)

          customer.reload

          expect(customer.name).to eq("Updated Customer")
          expect(customer.email).to eq("updated@commerceforge.dev")
          expect(customer.phone).to eq("9999999999")

          body = JSON.parse(response.body)

          expect(body["success"]).to be(true)
          expect(body["message"]).to eq("Customer updated successfully.")
          expect(body["data"]["customer"]["id"]).to eq(customer.id)
        end
      end
    end
  end
end
