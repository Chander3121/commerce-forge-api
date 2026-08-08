# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Api::V1::Orders", type: :request do
  describe "GET /api/v1/orders" do
    let!(:order) { create(:order) }

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
        end
      end
    end
  end

  describe "POST /api/v1/orders" do
    let(:product) { create(:product, price: 500) }

    let(:order_params) do
      {
        order: {
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

          expect(response).to have_http_status(:unprocessable_entity)

          body = JSON.parse(response.body)

          expect(body["success"]).to be(false)
          expect(body["message"]).to eq("Quantity must be greater than 0")
          expect(body["errors"]).to include(
            "code" => "INVALID_ORDER",
            "message" => "Quantity must be greater than 0"
          )
        end
      end
    end
  end

  describe "GET /api/v1/orders/:id" do
    let!(:order) { create(:order, user: user) }

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
        end

        it "does not allow access to another user's order" do
          another_user = create(:user)
          another_order = create(:order, user: another_user)

          get "/api/v1/orders/#{another_order.id}",
              headers: authenticated_headers(user)

          expect(response).to have_http_status(:forbidden)
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

        it "updates the order" do
          patch "/api/v1/orders/#{order.id}",
                params: order_params,
                headers: authenticated_headers(user),
                as: :json

          expect(response).to have_http_status(:ok)

          expect(order.reload.status).to eq("confirmed")

          body = JSON.parse(response.body)

          expect(body["success"]).to be(true)
          expect(body["message"]).to eq("Order updated successfully.")
        end
      end
    end
  end

  describe "POST /api/v1/orders/:id/cancel" do
    let!(:order) { create(:order, user: user) }

    context "when user is not authenticated" do
      let(:user) { create(:user) }

      it "returns unauthorized" do
        post "/api/v1/orders/#{order.id}/cancel"

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context "when user is authenticated" do
      context "when user does not have orders.cancel permission" do
        let(:user) { create(:user) }

        it "returns forbidden" do
          post "/api/v1/orders/#{order.id}/cancel",
               headers: authenticated_headers(user)

          expect(response).to have_http_status(:forbidden)
        end
      end

      context "when user has orders.cancel permission" do
        let(:user) { create(:user) }

        before do
          role = create(:role)

          permission = create(
            :permission,
            name: "Cancel Orders",
            code: "orders.cancel"
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

        it "cancels a pending order" do
          post "/api/v1/orders/#{order.id}/cancel",
               headers: authenticated_headers(user)

          expect(response).to have_http_status(:ok)
          expect(order.reload.status).to eq("cancelled")

          body = JSON.parse(response.body)

          expect(body["success"]).to be(true)
          expect(body["message"]).to eq("Order cancelled successfully.")
        end

        it "returns unprocessable entity when order cannot be cancelled" do
          order.confirm!

          post "/api/v1/orders/#{order.id}/cancel",
               headers: authenticated_headers(user)

          expect(response).to have_http_status(:unprocessable_entity)
          expect(order.reload.status).to eq("confirmed")
        end
      end
    end
  end
end
