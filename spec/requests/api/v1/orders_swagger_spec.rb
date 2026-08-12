# frozen_string_literal: true

require "swagger_helper"

RSpec.describe "Orders API", type: :request do
  path "/api/v1/orders" do
    get "List orders" do
      tags "Orders"
      security [ bearerAuth: [] ]

      produces "application/json"

      response "200", "orders fetched successfully" do
        let(:user) { create(:user) }
        let!(:customer) { create(:customer) }
        let!(:order) { create(:order, user: user, customer: customer) }

        let(:Authorization) { sign_in(user) }

        before do
          permission = create(
            :permission,
            name: "View Orders",
            code: "orders.read"
          )

          role = create(:role)

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

        schema(
          type: :object,
          properties: {
            success: { type: :boolean },
            message: { type: :string },
            data: {
              type: :object,
              properties: {
                orders: {
                  type: :array,
                  items: {
                    type: :object,
                    properties: {
                      id: {
                        type: :string,
                        format: :uuid
                      },
                      customer: {
                        type: :object,
                        properties: {
                          id: {
                            type: :string,
                            format: :uuid
                          },
                          name: { type: :string },
                          email: {
                            type: :string,
                            format: :email
                          },
                          phone: {
                            type: :string,
                            nullable: true
                          }
                        }
                      }
                    }
                  }
                }
              }
            },
            errors: {
              type: :array
            }
          }
        )

        run_test!
      end

      response "401", "authentication failed" do
        let(:Authorization) { nil }

        run_test!
      end

      response "403", "authorization failed" do
        let(:user) { create(:user) }

        let(:Authorization) { sign_in(user) }

        run_test!
      end
    end

    post "Create order" do
      tags "Orders"
      security [ bearerAuth: [] ]

      consumes "application/json"
      produces "application/json"

      parameter name: :order_params,
                in: :body,
                required: true,
                schema: {
                  type: :object,
                  properties: {
                    order: {
                      type: :object,
                      properties: {
                        customer_id: {
                          type: :string,
                          format: :uuid,
                          example: "0e3edee2-6226-4a68-bb72-b9d4442b681f"
                        },
                        items: {
                          type: :array,
                          items: {
                            type: :object,
                            properties: {
                              product_id: {
                                type: :string,
                                format: :uuid,
                                example: "1f4edee2-6226-4a68-bb72-b9d4442b681f"
                              },
                              quantity: {
                                type: :integer,
                                example: 2
                              }
                            },
                            required: %w[product_id quantity]
                          }
                        }
                      },
                      required: %w[customer_id items]
                    }
                  },
                  required: [ :order ]
                }

      response "201", "order created successfully" do
        let(:user) { create(:user) }
        let(:customer) { create(:customer) }
        let(:product) { create(:product, price: 500) }

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

        let(:Authorization) { sign_in(user) }

        before do
          permission = create(
            :permission,
            name: "Create Orders",
            code: "orders.create"
          )

          role = create(:role)

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

        schema(
          type: :object,
          properties: {
            success: { type: :boolean },
            message: { type: :string },
            data: {
              type: :object,
              properties: {
                order: {
                  type: :object,
                  properties: {
                    id: {
                      type: :string,
                      format: :uuid
                    },
                    user_id: {
                      type: :string,
                      format: :uuid
                    },
                    customer_id: {
                      type: :string,
                      format: :uuid
                    },
                    status: {
                      type: :string
                    },
                    subtotal: {
                      type: :string
                    },
                    total: {
                      type: :string
                    },
                    currency: {
                      type: :string
                    },
                    created_at: {
                      type: :string,
                      format: :"date-time"
                    },
                    updated_at: {
                      type: :string,
                      format: :"date-time"
                    }
                  }
                }
              }
            },
            errors: {
              type: :array
            }
          }
        )

        run_test!
      end

      response "401", "authentication failed" do
        let(:Authorization) { nil }

        let(:order_params) do
          {
            order: {
              customer_id: SecureRandom.uuid,
              items: [
                {
                  product_id: SecureRandom.uuid,
                  quantity: 1
                }
              ]
            }
          }
        end

        run_test!
      end

      response "403", "authorization failed" do
        let(:user) { create(:user) }

        let(:customer) { create(:customer) }
        let(:product) { create(:product, price: 500) }

        let(:order_params) do
          {
            order: {
              customer_id: customer.id,
              items: [
                {
                  product_id: product.id,
                  quantity: 1
                }
              ]
            }
          }
        end

        let(:Authorization) { sign_in(user) }

        run_test!
      end

      response "422", "invalid order" do
        let(:user) { create(:user) }
        let(:customer) { create(:customer) }
        let(:product) { create(:product, price: 500) }

        let(:order_params) do
          {
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
        end

        before do
          permission = create(
            :permission,
            name: "Create Orders",
            code: "orders.create"
          )

          role = create(:role)

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

        let(:Authorization) { sign_in(user) }

        run_test!
      end

      response "404", "product not found" do
        let(:user) { create(:user) }
        let(:customer) { create(:customer) }

        let(:order_params) do
          {
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
        end

        before do
          permission = create(
            :permission,
            name: "Create Orders",
            code: "orders.create"
          )

          role = create(:role)

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

        let(:Authorization) { sign_in(user) }

        run_test!
      end
    end
  end

  path "/api/v1/orders/{id}" do
    get "Get order" do
      tags "Orders"
      security [ bearerAuth: [] ]

      produces "application/json"

      parameter name: :id,
                in: :path,
                required: true,
                description: "Order ID",
                schema: {
                  type: :string,
                  format: :uuid
                }

      response "200", "order fetched successfully" do
        let(:user) { create(:user) }
        let!(:customer) { create(:customer) }
        let!(:order) { create(:order, user: user, customer: customer) }
        let(:id) { order.id }

        let(:Authorization) { sign_in(user) }

        before do
          permission = create(
            :permission,
            name: "View Orders",
            code: "orders.read"
          )

          role = create(:role)

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

        schema(
          type: :object,
          properties: {
            success: { type: :boolean },
            message: { type: :string },
            data: {
              type: :object,
              properties: {
                order: {
                  type: :object,
                  properties: {
                    id: {
                      type: :string,
                      format: :uuid
                    },
                    user_id: {
                      type: :string,
                      format: :uuid
                    },
                    customer_id: {
                      type: :string,
                      format: :uuid
                    },
                    status: {
                      type: :string
                    },
                    subtotal: {
                      type: :string
                    },
                    total: {
                      type: :string
                    },
                    currency: {
                      type: :string
                    },
                    created_at: {
                      type: :string,
                      format: :"date-time"
                    },
                    updated_at: {
                      type: :string,
                      format: :"date-time"
                    },
                    customer: {
                      type: :object,
                      properties: {
                        id: {
                          type: :string,
                          format: :uuid
                        },
                        name: { type: :string },
                        email: {
                          type: :string,
                          format: :email
                        },
                        phone: {
                          type: :string,
                          nullable: true
                        }
                      }
                    }
                  }
                }
              }
            },
            errors: {
              type: :array
            }
          }
        )

        run_test!
      end

      response "401", "authentication failed" do
        let(:user) { create(:user) }
        let(:id) { SecureRandom.uuid }
        let(:Authorization) { nil }

        run_test!
      end

      response "403", "authorization failed" do
        let(:user) { create(:user) }
        let!(:customer) { create(:customer) }
        let!(:order) { create(:order, user: user, customer: customer) }
        let(:id) { order.id }

        let(:Authorization) { sign_in(user) }

        run_test!
      end
    end

    patch "Update order" do
      tags "Orders"
      security [ bearerAuth: [] ]

      parameter name: :id,
                in: :path,
                type: :string,
                format: :uuid,
                required: true,
                description: "Order ID"

      parameter name: :order_params,
                in: :body,
                required: true,
                schema: {
                  type: :object,
                  properties: {
                    order: {
                      type: :object,
                      properties: {
                        customer_id: {
                          type: :string,
                          format: :uuid
                        }
                      },
                      required: [ :customer_id ]
                    }
                  },
                  required: [ :order ]
                }

      consumes "application/json"
      produces "application/json"

      response "200", "order updated successfully" do
        let(:user) { create(:user) }
        let!(:order) { create(:order, user: user) }
        let(:id) { order.id }

        let(:order_params) do
          {
            order: {
              customer_id: create(:customer).id
            }
          }
        end

        let(:Authorization) { sign_in(user) }

        before do
          permission = create(
            :permission,
            name: "Update Orders",
            code: "orders.update"
          )

          role = create(:role)

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

        consumes "application/json"

        schema(
          type: :object,
          properties: {
            success: { type: :boolean },
            message: { type: :string },
            data: {
              type: :object,
              properties: {
                order: {
                  type: :object,
                  properties: {
                    id: {
                      type: :string,
                      format: :uuid
                    },
                    user_id: {
                      type: :string,
                      format: :uuid
                    },
                    customer_id: {
                      type: :string,
                      format: :uuid
                    },
                    status: { type: :string },
                    subtotal: { type: :string },
                    total: { type: :string },
                    currency: { type: :string },
                    created_at: {
                      type: :string,
                      format: :"date-time"
                    },
                    updated_at: {
                      type: :string,
                      format: :"date-time"
                    }
                  }
                }
              }
            },
            errors: { type: :array }
          }
        )

        run_test!
      end

      response "401", "authentication failed" do
        let(:user) { create(:user) }
        let!(:order) { create(:order, user: user) }

        let(:id) { order.id }

        let(:order_params) do
          {
            order: {
              customer_id: create(:customer).id
            }
          }
        end

        let(:Authorization) { nil }

        run_test!
      end

      response "403", "authorization failed" do
        let(:user) { create(:user) }
        let!(:order) { create(:order, user: user) }

        let(:id) { order.id }

        let(:order_params) do
          {
            order: {
              customer_id: create(:customer).id
            }
          }
        end

        let(:Authorization) { sign_in(user) }

        run_test!
      end

      response "422", "invalid order update" do
        let(:user) { create(:user) }
        let!(:order) { create(:order, user: user) }

        let(:id) { order.id }

        let(:order_params) do
          {
            order: {
              status: "confirmed"
            }
          }
        end

        let(:Authorization) { sign_in(user) }

        before do
          permission = create(
            :permission,
            name: "Update Orders",
            code: "orders.update"
          )

          role = create(:role)

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

        run_test!
      end
    end
  end

  path "/api/v1/orders/{id}/confirm" do
    post "Confirm order" do
      tags "Orders"
      security [ bearerAuth: [] ]

      produces "application/json"

      parameter name: :id,
                in: :path,
                required: true,
                description: "Order ID",
                schema: {
                  type: :string,
                  format: :uuid
                }

      response "200", "order confirmed successfully" do
        let(:user) { create(:user) }
        let!(:order) { create(:order, user: user, status: "pending") }
        let(:id) { order.id }

        let(:Authorization) { sign_in(user) }

        before do
          permission = create(
            :permission,
            name: "Update Orders",
            code: "orders.update"
          )

          role = create(:role)

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

        schema(
          type: :object,
          properties: {
            success: { type: :boolean },
            message: { type: :string },
            data: {
              type: :object
            },
            errors: {
              type: :array
            }
          }
        )

        run_test!
      end

      response "401", "authentication failed" do
        let(:id) { SecureRandom.uuid }
        let(:Authorization) { nil }

        run_test!
      end

      response "403", "authorization failed" do
        let(:user) { create(:user) }
        let!(:order) { create(:order, user: user, status: "pending") }
        let(:id) { order.id }

        let(:Authorization) { sign_in(user) }

        run_test!
      end

      response "422", "invalid order status transition" do
        let(:user) { create(:user) }
        let!(:order) { create(:order, user: user, status: "confirmed") }
        let(:id) { order.id }

        before do
          permission = create(
            :permission,
            name: "Update Orders",
            code: "orders.update"
          )

          role = create(:role)

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

        let(:Authorization) { sign_in(user) }

        run_test!
      end
    end
  end

  path "/api/v1/orders/{id}/process" do
    post "Process order" do
      tags "Orders"
      security [ bearerAuth: [] ]

      produces "application/json"

      parameter name: :id,
                in: :path,
                required: true,
                description: "Order ID",
                schema: {
                  type: :string,
                  format: :uuid
                }

      response "200", "order moved to processing successfully" do
        let(:user) { create(:user) }
        let!(:order) { create(:order, user: user, status: "confirmed") }
        let(:id) { order.id }

        let(:Authorization) { sign_in(user) }

        before do
          permission = create(
            :permission,
            name: "Update Orders",
            code: "orders.update"
          )

          role = create(:role)

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

        schema(
          type: :object,
          properties: {
            success: { type: :boolean },
            message: { type: :string },
            data: {
              type: :object
            },
            errors: {
              type: :array
            }
          }
        )

        run_test!
      end

      response "401", "authentication failed" do
        let(:id) { SecureRandom.uuid }
        let(:Authorization) { nil }

        run_test!
      end

      response "403", "authorization failed" do
        let(:user) { create(:user) }
        let!(:order) { create(:order, user: user, status: "confirmed") }
        let(:id) { order.id }

        let(:Authorization) { sign_in(user) }

        run_test!
      end

      response "422", "invalid order status transition" do
        let(:user) { create(:user) }
        let!(:order) { create(:order, user: user, status: "pending") }
        let(:id) { order.id }

        before do
          permission = create(
            :permission,
            name: "Update Orders",
            code: "orders.update"
          )

          role = create(:role)

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

        let(:Authorization) { sign_in(user) }

        run_test!
      end
    end
  end

  path "/api/v1/orders/{id}/ship" do
    post "Ship order" do
      tags "Orders"
      security [ bearerAuth: [] ]

      parameter(
        name: :id,
        in: :path,
        type: :string,
        format: :uuid,
        required: true,
        description: "Order ID"
      )

      produces "application/json"

      response "200", "order shipped successfully" do
        let(:user) { create(:user) }

        let!(:order) do
          order = create(:order, user: user, status: "pending")
          order.confirm!
          order.process!
          order
        end

        let(:id) { order.id }
        let(:Authorization) { sign_in(user) }

        before do
          permission = create(
            :permission,
            name: "Update Orders",
            code: "orders.update"
          )

          role = create(:role)

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

        schema(
          type: :object,
          properties: {
            success: { type: :boolean },
            message: { type: :string },
            data: {
              type: :object
            },
            errors: {
              type: :array
            }
          }
        )

        run_test!
      end

      response "401", "authentication failed" do
        let(:Authorization) { nil }
        let(:id) { SecureRandom.uuid }

        run_test!
      end

      response "403", "authorization failed" do
        let(:user) { create(:user) }
        let!(:order) do
          order = create(:order, user: user, status: "pending")
          order.confirm!
          order.process!
          order
        end

        let(:id) { order.id }
        let(:Authorization) { sign_in(user) }

        run_test!
      end

      response "422", "invalid order status transition" do
        let(:user) { create(:user) }

        let!(:order) do
          order = create(:order, user: user, status: "pending")
          order.confirm!
          order.process!
          order
        end

        let(:id) { order.id }

        before do
          order.update_column(:status, "confirmed")

          permission = create(
            :permission,
            name: "Update Orders",
            code: "orders.update"
          )

          role = create(:role)

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

        let(:Authorization) { sign_in(user) }

        run_test!
      end
    end
  end

  path "/api/v1/orders/{id}/deliver" do
    post "Deliver order" do
      tags "Orders"
      security [ bearerAuth: [] ]

      parameter name: :id,
                in: :path,
                type: :string,
                format: :uuid,
                required: true,
                description: "Order ID"

      produces "application/json"

      response "200", "order delivered successfully" do
        let(:user) { create(:user) }

        let!(:order) do
          order = create(
            :order,
            user: user,
            status: "pending"
          )

          order.confirm!
          order.process!
          order.ship!

          order
        end

        let(:id) { order.id }
        let(:Authorization) { sign_in(user) }

        before do
          permission = create(
            :permission,
            name: "Update Orders",
            code: "orders.update"
          )

          role = create(:role)

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

        schema(
          type: :object,
          properties: {
            success: { type: :boolean },
            message: { type: :string },
            data: { type: :object },
            errors: { type: :array }
          }
        )

        run_test!
      end

      response "401", "authentication failed" do
        let(:user) { create(:user) }

        let!(:order) do
          order = create(
            :order,
            user: user,
            status: "pending"
          )

          order.confirm!
          order.process!
          order.ship!

          order
        end

        let(:id) { order.id }
        let(:Authorization) { nil }

        run_test!
      end

      response "403", "authorization failed" do
        let(:user) { create(:user) }

        let!(:order) do
          order = create(
            :order,
            user: user,
            status: "pending"
          )

          order.confirm!
          order.process!
          order.ship!

          order
        end

        let(:id) { order.id }
        let(:Authorization) { sign_in(user) }

        run_test!
      end

      response "422", "invalid order status transition" do
        let(:user) { create(:user) }

        let!(:order) do
          order = create(
            :order,
            user: user,
            status: "pending"
          )

          order.confirm!
          order.process!

          order
        end

        let(:id) { order.id }
        let(:Authorization) { sign_in(user) }

        before do
          permission = create(
            :permission,
            name: "Update Orders",
            code: "orders.update"
          )

          role = create(:role)

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

        run_test!
      end
    end
  end

  path "/api/v1/orders/{id}/cancel" do
    post "Cancel order" do
      tags "Orders"
      security [ bearerAuth: [] ]

      parameter name: :id,
                in: :path,
                type: :string,
                format: :uuid,
                required: true,
                description: "Order ID"

      produces "application/json"

      response "200", "order cancelled successfully" do
        let(:user) { create(:user) }
        let!(:order) do
          create(
            :order,
            user: user,
            status: "pending"
          )
        end

        let(:id) { order.id }
        let(:Authorization) { sign_in(user) }

        before do
          permission = create(
            :permission,
            name: "Update Orders",
            code: "orders.update"
          )

          role = create(:role)

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

        schema(
          type: :object,
          properties: {
            success: { type: :boolean },
            message: { type: :string },
            data: { type: :object },
            errors: { type: :array }
          }
        )

        run_test!
      end

      response "401", "authentication failed" do
        let(:user) { create(:user) }

        let!(:order) do
          create(
            :order,
            user: user,
            status: "pending"
          )
        end

        let(:id) { order.id }
        let(:Authorization) { nil }

        run_test!
      end

      response "403", "authorization failed" do
        let(:user) { create(:user) }

        let!(:order) do
          create(
            :order,
            user: user,
            status: "pending"
          )
        end

        let(:id) { order.id }
        let(:Authorization) { sign_in(user) }

        run_test!
      end

      response "422", "invalid order status transition" do
        let(:user) { create(:user) }

        let!(:order) do
          order = create(
            :order,
            user: user,
            status: "pending"
          )

          order.confirm!

          order
        end

        let(:id) { order.id }
        let(:Authorization) { sign_in(user) }

        before do
          permission = create(
            :permission,
            name: "Update Orders",
            code: "orders.update"
          )

          role = create(:role)

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

        run_test!
      end
    end
  end
end
