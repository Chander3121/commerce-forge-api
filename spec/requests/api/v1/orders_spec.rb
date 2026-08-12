# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Api::V1::Orders", type: :request do
  describe "GET /api/v1/orders" do
    let(:user) { create(:user) }
    let!(:customer) { create(:customer) }
    let!(:order) { create(:order, user: user, customer: customer) }

    context "when user is not authenticated" do
      it "returns unauthorized" do
        get "/api/v1/orders"

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context "when user is authenticated" do
      context "when user does not have orders.read permission" do
        let(:user) { create(:user) }

        it "returns forbidden" do
          get "/api/v1/orders",
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

      context "when user has orders.read permission" do
        let(:user) { create(:user) }

        before do
          role = create(:role)

          permission = create(
            :permission,
            name: "View Orders",
            code: "orders.read"
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

        it "returns orders" do
          get "/api/v1/orders",
              headers: authenticated_headers(user)

          expect(response).to have_http_status(:ok)

          body = JSON.parse(response.body)

          expect(body["success"]).to be(true)
          expect(body["message"]).to eq("Orders fetched successfully.")
          expect(body["data"]["orders"]).to be_an(Array)

          returned_order = body["data"]["orders"].first

          expect(returned_order["customer"]["id"]).to eq(order.customer.id)
          expect(returned_order["customer"]["name"]).to eq(order.customer.name)
          expect(returned_order["customer"]["email"]).to eq(order.customer.email)
          expect(returned_order["customer"]["phone"]).to eq(order.customer.phone)
        end

        it "does not return orders belonging to another user" do
          another_user = create(:user)

          another_order = create(
            :order,
            user: another_user,
            customer: customer
          )

          get "/api/v1/orders",
              headers: authenticated_headers(user)

          expect(response).to have_http_status(:ok)

          body = JSON.parse(response.body)

          returned_order_ids = body["data"]["orders"].map do |returned_order|
            returned_order["id"]
          end

          expect(returned_order_ids).to include(order.id)
          expect(returned_order_ids).not_to include(another_order.id)
        end

        it "returns all orders for an admin user" do
          admin_role = create(:role, slug: "admin")

          create(
            :user_role,
            user: user,
            role: admin_role
          )

          another_user = create(:user)

          another_order = create(
            :order,
            user: another_user,
            customer: customer
          )

          get "/api/v1/orders",
              headers: authenticated_headers(user)

          expect(response).to have_http_status(:ok)

          body = JSON.parse(response.body)

          returned_order_ids = body["data"]["orders"].map do |returned_order|
            returned_order["id"]
          end

          expect(returned_order_ids).to include(order.id)
          expect(returned_order_ids).to include(another_order.id)
        end
      end
    end
  end

  describe "POST /api/v1/orders" do
    let(:product) { create(:product, price: 500) }
    let(:customer) { create(:customer) }

    let(:order_params) do
      {
        order: {
          customer_id: customer.id,
          items: [
            {
              product_id: product.id,
              quantity: 2
            }
          ]
        }
      }
    end

    context "when user is not authenticated" do
      it "returns unauthorized" do
        post "/api/v1/orders",
             params: order_params,
             as: :json

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context "when user is authenticated" do
      context "when user does not have orders.create permission" do
        let(:user) { create(:user) }

        it "returns forbidden" do
          post "/api/v1/orders",
               params: order_params,
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

      context "when user has orders.create permission" do
        let(:user) { create(:user) }

        before do
          role = create(:role)

          permission = create(
            :permission,
            name: "Create Orders",
            code: "orders.create"
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

        it "creates the order" do
          expect do
            post "/api/v1/orders",
                 params: order_params,
                 headers: authenticated_headers(user),
                 as: :json
          end.to change(Order, :count).by(1)

          expect(response).to have_http_status(:created)

          body = JSON.parse(response.body)

          expect(body["success"]).to be(true)
          expect(body["message"]).to eq("Order created successfully.")

          order = Order.last

          expect(order.user).to eq(user)
          expect(order.customer).to eq(customer)
          expect(order.status).to eq("pending")
          expect(order.subtotal).to eq(1000)
          expect(order.total).to eq(1000)

          expect(order.order_items.count).to eq(1)

          item = order.order_items.first

          expect(item.product).to eq(product)
          expect(item.quantity).to eq(2)
          expect(item.unit_price).to eq(500)
          expect(item.total_price).to eq(1000)
        end

        it "uses the product price instead of the client supplied price" do
          malicious_params = {
            order: {
              customer_id: customer.id,
              items: [
                {
                  product_id: product.id,
                  quantity: 2,
                  unit_price: 1,
                  total_price: 2
                }
              ]
            }
          }

          post "/api/v1/orders",
               params: malicious_params,
               headers: authenticated_headers(user),
               as: :json

          expect(response).to have_http_status(:created)

          order = Order.last
          item = order.order_items.first

          expect(item.unit_price).to eq(500)
          expect(item.total_price).to eq(1000)
          expect(order.subtotal).to eq(1000)
          expect(order.total).to eq(1000)
        end

        it "returns unprocessable entity for invalid quantity" do
          invalid_params = {
            order: {
              customer_id: customer.id,
              items: [
                {
                  product_id: product.id,
                  quantity: 0
                }
              ]
            }
          }

          post "/api/v1/orders",
               params: invalid_params,
               headers: authenticated_headers(user),
               as: :json

          expect(response).to have_http_status(:unprocessable_content)

          body = JSON.parse(response.body)

          expect(body["success"]).to be(false)
          expect(body["message"]).to eq("Quantity must be greater than 0")
          expect(body["errors"]).to include(
            "code" => "INVALID_ORDER",
            "message" => "Quantity must be greater than 0"
          )
        end

        it "returns not found when the product does not exist" do
          invalid_params = {
            order: {
              customer_id: customer.id,
              items: [
                {
                  product_id: SecureRandom.uuid,
                  quantity: 1
                }
              ]
            }
          }

          expect {
            post "/api/v1/orders",
                 params: invalid_params,
                 headers: authenticated_headers(user),
                 as: :json
          }.not_to change(Order, :count)

          expect(response).to have_http_status(:not_found)

          body = JSON.parse(response.body)

          expect(body["success"]).to be(false)
          expect(body["errors"]).to include(
            "code" => "RESOURCE_NOT_FOUND",
            "message" => "Product not found."
          )
        end
      end
    end
  end

  describe "GET /api/v1/orders/:id" do
    let!(:customer) { create(:customer) }
    let!(:order) { create(:order, user: user, customer: customer) }

    context "when user is not authenticated" do
      let(:user) { create(:user) }

      it "returns unauthorized" do
        get "/api/v1/orders/#{order.id}"

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context "when user is authenticated" do
      context "when user does not have orders.read permission" do
        let(:user) { create(:user) }

        it "returns forbidden" do
          get "/api/v1/orders/#{order.id}",
              headers: authenticated_headers(user)

          expect(response).to have_http_status(:forbidden)
        end
      end

      context "when user has orders.read permission" do
        let(:user) { create(:user) }

        before do
          role = create(:role)

          permission = create(
            :permission,
            name: "View Orders",
            code: "orders.read"
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

        it "returns the user's order" do
          get "/api/v1/orders/#{order.id}",
              headers: authenticated_headers(user)

          expect(response).to have_http_status(:ok)

          body = JSON.parse(response.body)

          expect(body["success"]).to be(true)
          expect(body["message"]).to eq("Order fetched successfully.")
          expect(body["data"]["order"]["id"]).to eq(order.id)

          returned_order = body["data"]["order"]

          expect(returned_order["customer"]["id"]).to eq(order.customer.id)
          expect(returned_order["customer"]["name"]).to eq(order.customer.name)
          expect(returned_order["customer"]["email"]).to eq(order.customer.email)
          expect(returned_order["customer"]["phone"]).to eq(order.customer.phone)
        end

        it "does not allow access to another user's order" do
          another_user = create(:user)
          another_order = create(:order, user: another_user)

          get "/api/v1/orders/#{another_order.id}",
              headers: authenticated_headers(user)

          expect(response).to have_http_status(:forbidden)
        end

        it "allows an admin to access another user's order" do
          admin_role = create(:role, slug: "admin")

          create(
            :user_role,
            user: user,
            role: admin_role
          )

          another_user = create(:user)
          another_order = create(
            :order,
            user: another_user,
            customer: customer
          )

          get "/api/v1/orders/#{another_order.id}",
              headers: authenticated_headers(user)

          expect(response).to have_http_status(:ok)

          body = JSON.parse(response.body)

          expect(body["success"]).to be(true)
          expect(body["data"]["order"]["id"]).to eq(another_order.id)
        end
      end
    end
  end

  describe "POST /api/v1/orders/:id/confirm" do
    let(:user) { create(:user) }
    let!(:order) { create(:order, user: user, status: "pending") }

    context "when user is not authenticated" do
      it "returns unauthorized" do
        post "/api/v1/orders/#{order.id}/confirm"

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context "when user is authenticated" do
      context "when user does not have orders.update permission" do
        let(:user) { create(:user) }

        it "returns forbidden" do
          post "/api/v1/orders/#{order.id}/confirm",
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

      context "when user has orders.update permission" do
        let(:user) { create(:user) }

        before do
          role = create(:role)

          permission = create(
            :permission,
            name: "Update Orders",
            code: "orders.update"
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

        it "confirms the order" do
          post "/api/v1/orders/#{order.id}/confirm",
               headers: authenticated_headers(user)

          expect(response).to have_http_status(:ok)

          body = JSON.parse(response.body)

          expect(body["success"]).to be(true)
          expect(body["message"]).to eq(
            "Order confirmed successfully."
          )

          expect(order.reload.status).to eq("confirmed")
        end

        it "does not allow managing another user's order" do
          another_user = create(:user)

          another_order = create(
            :order,
            user: another_user,
            status: "pending"
          )

          post "/api/v1/orders/#{another_order.id}/confirm",
               headers: authenticated_headers(user)

          expect(response).to have_http_status(:forbidden)

          expect(another_order.reload.status).to eq("pending")
        end

        it "returns an error when the order cannot be confirmed from its current status" do
          order.update_column(:status, "confirmed")

          post "/api/v1/orders/#{order.id}/confirm",
               headers: authenticated_headers(user)

          expect(response).to have_http_status(:unprocessable_content)

          body = JSON.parse(response.body)

          expect(body["success"]).to be(false)
          expect(body["message"]).to eq("Invalid order status transition")
          expect(body["errors"]).to include(
            "code" => "INVALID_ORDER",
            "message" => "Invalid order status transition"
          )

          expect(order.reload.status).to eq("confirmed")
        end
      end
    end
  end

  describe "POST /api/v1/orders/:id/process" do
    let(:user) { create(:user) }
    let!(:order) { create(:order, user: user, status: "confirmed") }

    context "when user is not authenticated" do
      it "returns unauthorized" do
        post "/api/v1/orders/#{order.id}/process"

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context "when user is authenticated" do
      context "when user does not have orders.update permission" do
        let(:user) { create(:user) }

        it "returns forbidden" do
          post "/api/v1/orders/#{order.id}/process",
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

      context "when user has orders.update permission" do
        let(:user) { create(:user) }

        before do
          role = create(:role)

          permission = create(
            :permission,
            name: "Update Orders",
            code: "orders.update"
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

        it "moves the order to processing" do
          post "/api/v1/orders/#{order.id}/process",
               headers: authenticated_headers(user)

          expect(response).to have_http_status(:ok)

          body = JSON.parse(response.body)

          expect(body["success"]).to be(true)
          expect(body["message"]).to eq(
            "Order moved to processing successfully."
          )

          expect(order.reload.status).to eq("processing")
        end

        it "returns an error when the order cannot be processed from its current status" do
          order.update_column(:status, "pending")

          post "/api/v1/orders/#{order.id}/process",
               headers: authenticated_headers(user)

          expect(response).to have_http_status(:unprocessable_content)

          body = JSON.parse(response.body)

          expect(body["success"]).to be(false)
          expect(body["message"]).to eq("Invalid order status transition")
          expect(body["errors"]).to include(
            "code" => "INVALID_ORDER",
            "message" => "Invalid order status transition"
          )

          expect(order.reload.status).to eq("pending")
        end
      end
    end
  end

  describe "POST /api/v1/orders/:id/ship" do
    let(:user) { create(:user) }
    let!(:order) do
      order = create(:order, user: user, status: "pending")
      order.confirm!
      order.process!
      order
    end

    context "when user is not authenticated" do
      it "returns unauthorized" do
        post "/api/v1/orders/#{order.id}/ship"

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context "when user is authenticated" do
      context "when user does not have orders.update permission" do
        let(:user) { create(:user) }

        it "returns forbidden" do
          post "/api/v1/orders/#{order.id}/ship",
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

      context "when user has orders.update permission" do
        let(:user) { create(:user) }

        before do
          role = create(:role)

          permission = create(
            :permission,
            name: "Update Orders",
            code: "orders.update"
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

        it "ships the order" do
          post "/api/v1/orders/#{order.id}/ship",
               headers: authenticated_headers(user)

          expect(response).to have_http_status(:ok)

          body = JSON.parse(response.body)

          expect(body["success"]).to be(true)
          expect(body["message"]).to eq(
            "Order shipped successfully."
          )

          expect(order.reload.status).to eq("shipped")
        end

        it "returns an error when the order cannot be shipped from its current status" do
          order.update_column(:status, "confirmed")

          post "/api/v1/orders/#{order.id}/ship",
               headers: authenticated_headers(user)

          expect(response).to have_http_status(:unprocessable_content)

          body = JSON.parse(response.body)

          expect(body["success"]).to be(false)
          expect(body["message"]).to eq("Invalid order status transition")
          expect(body["errors"]).to include(
            "code" => "INVALID_ORDER",
            "message" => "Invalid order status transition"
          )

          expect(order.reload.status).to eq("confirmed")
        end
      end
    end
  end

  describe "POST /api/v1/orders/:id/deliver" do
    let(:user) { create(:user) }
    let!(:order) do
      order = create(:order, user: user, status: "pending")
      order.confirm!
      order.process!
      order.ship!
      order
    end

    context "when user is not authenticated" do
      it "returns unauthorized" do
        post "/api/v1/orders/#{order.id}/deliver"

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context "when user is authenticated" do
      context "when user does not have orders.update permission" do
        let(:user) { create(:user) }

        it "returns forbidden" do
          post "/api/v1/orders/#{order.id}/deliver",
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

      context "when user has orders.update permission" do
        let(:user) { create(:user) }

        before do
          role = create(:role)

          permission = create(
            :permission,
            name: "Update Orders",
            code: "orders.update"
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

        it "delivers the order" do
          post "/api/v1/orders/#{order.id}/deliver",
               headers: authenticated_headers(user)

          expect(response).to have_http_status(:ok)

          body = JSON.parse(response.body)

          expect(body["success"]).to be(true)
          expect(body["message"]).to eq(
            "Order delivered successfully."
          )

          expect(order.reload.status).to eq("delivered")
        end

        it "returns an error when the order cannot be delivered from its current status" do
          order.update_column(:status, "processing")

          post "/api/v1/orders/#{order.id}/deliver",
               headers: authenticated_headers(user)

          expect(response).to have_http_status(:unprocessable_content)

          body = JSON.parse(response.body)

          expect(body["success"]).to be(false)
          expect(body["message"]).to eq("Invalid order status transition")
          expect(body["errors"]).to include(
            "code" => "INVALID_ORDER",
            "message" => "Invalid order status transition"
          )

          expect(order.reload.status).to eq("processing")
        end
      end
    end
  end

  describe "POST /api/v1/orders/:id/cancel" do
    let(:user) { create(:user) }
    let!(:order) { create(:order, user: user, status: "pending") }

    context "when user is not authenticated" do
      it "returns unauthorized" do
        post "/api/v1/orders/#{order.id}/cancel"

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context "when user is authenticated" do
      context "when user does not have orders.update permission" do
        let(:user) { create(:user) }

        it "returns forbidden" do
          post "/api/v1/orders/#{order.id}/cancel",
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

      context "when user has orders.update permission" do
        let(:user) { create(:user) }

        before do
          role = create(:role)

          permission = create(
            :permission,
            name: "Update Orders",
            code: "orders.update"
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

        it "cancels the order" do
          post "/api/v1/orders/#{order.id}/cancel",
               headers: authenticated_headers(user)

          expect(response).to have_http_status(:ok)

          body = JSON.parse(response.body)

          expect(body["success"]).to be(true)
          expect(body["message"]).to eq(
            "Order cancelled successfully."
          )

          expect(order.reload.status).to eq("cancelled")
        end

        it "returns unprocessable entity when the order cannot be cancelled" do
          order.confirm!

          post "/api/v1/orders/#{order.id}/cancel",
               headers: authenticated_headers(user)

          expect(response).to have_http_status(:unprocessable_content)

          body = JSON.parse(response.body)

          expect(body["success"]).to be(false)
        end
      end
    end
  end

  describe "PATCH /api/v1/orders/:id" do
    let!(:order) { create(:order, user: user) }

    let(:order_params) do
      {
        order: {
          status: "confirmed"
        }
      }
    end

    context "when user is not authenticated" do
      let(:user) { create(:user) }

      it "returns unauthorized" do
        patch "/api/v1/orders/#{order.id}",
              params: order_params,
              as: :json

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context "when user is authenticated" do
      context "when user does not have orders.update permission" do
        let(:user) { create(:user) }

        it "returns forbidden" do
          patch "/api/v1/orders/#{order.id}",
                params: order_params,
                headers: authenticated_headers(user),
                as: :json

          expect(response).to have_http_status(:forbidden)
        end
      end

      context "when user has orders.update permission" do
        let(:user) { create(:user) }

        before do
          role = create(:role)

          permission = create(
            :permission,
            name: "Update Orders",
            code: "orders.update"
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

        it "does not allow status to be updated directly" do
          patch "/api/v1/orders/#{order.id}",
                params: order_params,
                headers: authenticated_headers(user),
                as: :json

          expect(response).to have_http_status(:unprocessable_content)

          expect(order.reload.status).to eq("pending")
        end

        it "updates the order customer" do
          old_customer = create(:customer)
          new_customer = create(:customer)

          order.update!(customer: old_customer)

          patch "/api/v1/orders/#{order.id}",
                params: {
                  order: {
                    customer_id: new_customer.id
                  }
                },
                headers: authenticated_headers(user),
                as: :json

          expect(response).to have_http_status(:ok)

          expect(order.reload.customer_id).to eq(new_customer.id)

          body = JSON.parse(response.body)

          expect(body["success"]).to be(true)
          expect(body["message"]).to eq("Order updated successfully.")
          expect(body["data"]["order"]["customer_id"]).to eq(new_customer.id)
        end

        it "does not allow an authorized user to update another user's order" do
          other_user = create(:user)
          other_order = create(:order, user: other_user)

          new_customer = create(:customer)
          original_customer_id = other_order.customer_id

          patch "/api/v1/orders/#{other_order.id}",
                params: {
                  order: {
                    customer_id: new_customer.id
                  }
                },
                headers: authenticated_headers(user),
                as: :json

          expect(response).to have_http_status(:forbidden)

          expect(other_order.reload.customer_id).to eq(original_customer_id)

          body = JSON.parse(response.body)

          expect(body["success"]).to be(false)
          expect(body["errors"]).to include(
            "code" => "AUTHORIZATION_FAILED",
            "message" => "You are not authorized to perform this action."
          )
        end

        it "does not allow protected order fields to be updated" do
          original_subtotal = order.subtotal
          original_total = order.total
          original_user_id = order.user_id
          original_currency = order.currency

          patch "/api/v1/orders/#{order.id}",
                params: {
                  order: {
                    subtotal: 1,
                    total: 1,
                    user_id: create(:user).id,
                    currency: "USD",
                    status: "confirmed"
                  }
                },
                headers: authenticated_headers(user),
                as: :json

          expect(response).to have_http_status(:unprocessable_content)

          order.reload

          expect(order.subtotal).to eq(original_subtotal)
          expect(order.total).to eq(original_total)
          expect(order.user_id).to eq(original_user_id)
          expect(order.currency).to eq(original_currency)
          expect(order.status).to eq("pending")
        end

        it "does not allow financial fields to be updated" do
          original_subtotal = order.subtotal
          original_total = order.total
          original_user_id = order.user_id
          original_currency = order.currency

          patch "/api/v1/orders/#{order.id}",
                params: {
                  order: {
                    subtotal: 1,
                    total: 1,
                    user_id: create(:user).id,
                    currency: "USD"
                  }
                },
                headers: authenticated_headers(user),
                as: :json

          expect(response).to have_http_status(:ok)

          order.reload

          expect(order.subtotal).to eq(original_subtotal)
          expect(order.total).to eq(original_total)
          expect(order.user_id).to eq(original_user_id)
          expect(order.currency).to eq(original_currency)
        end
      end
    end
  end
end
