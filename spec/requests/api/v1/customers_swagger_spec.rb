# frozen_string_literal: true

require "swagger_helper"

RSpec.describe "Customers API", type: :request do
  path "/api/v1/customers" do
    get "List customers" do
      tags "Customers"
      produces "application/json"
      security [ bearerAuth: [] ]

      parameter name: :page,
                in: :query,
                type: :integer,
                required: false,
                default: 1,
                description: "Page number"

      parameter name: :per_page,
                in: :query,
                type: :integer,
                required: false,
                default: 20,
                maximum: 100,
                description: "Number of customers per page"

      parameter name: :sort_by,
                in: :query,
                type: :string,
                required: false,
                default: "created_at",
                enum: %w[name email phone created_at],
                description: "Field used for sorting"

      parameter name: :sort_order,
                in: :query,
                type: :string,
                required: false,
                default: "desc",
                enum: %w[asc desc],
                description: "Sort direction"

      parameter name: :search,
                in: :query,
                type: :string,
                required: false,
                description: "Search customers by name, email or phone"

      response "200", "customers fetched successfully" do
        let(:user) { create(:user) }

        before do
          permission = create(
            :permission,
            name: "View Customers",
            code: "customers.read"
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

          create(:customer)
        end

        let(:Authorization) { sign_in(user) }

        schema type: :object,
               properties: {
                 success: { type: :boolean },
                 message: { type: :string },
                 data: {
                   type: :object,
                   properties: {
                     customers: {
                       type: :array,
                       items: {
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
                           },
                           created_at: {
                             type: :string,
                             format: :"date-time"
                           }
                         }
                       }
                     },
                     meta: {
                       type: :object,
                       properties: {
                         page: { type: :integer },
                         per_page: { type: :integer },
                         total: { type: :integer },
                         total_pages: { type: :integer }
                       }
                     }
                   }
                 },
                 errors: {
                   type: :array
                 }
               }

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
  end

  path "/api/v1/customers/{id}" do
    get "Get customer" do
      tags "Customers"
      security [ bearerAuth: [] ]

      produces "application/json"

      parameter name: :id,
                in: :path,
                type: :string,
                format: :uuid,
                required: true,
                description: "Customer ID"

      response "200", "customer fetched successfully" do
        let(:user) { create(:user) }
        let(:customer) { create(:customer) }
        let(:id) { customer.id }

        let(:Authorization) { sign_in(user) }

        before do
          permission = create(
            :permission,
            name: "View Customers",
            code: "customers.read"
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
                    },
                    created_at: {
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
        let(:customer) { create(:customer) }
        let(:id) { customer.id }
        let(:Authorization) { nil }

        run_test!
      end

      response "403", "authorization failed" do
        let(:user) { create(:user) }
        let(:customer) { create(:customer) }
        let(:id) { customer.id }

        let(:Authorization) { sign_in(user) }

        run_test!
      end

      response "404", "customer not found" do
        let(:user) { create(:user) }
        let(:id) { SecureRandom.uuid }

        let(:Authorization) { sign_in(user) }

        run_test!
      end
    end

    patch "Update customer" do
      tags "Customers"
      security [ bearerAuth: [] ]

      consumes "application/json"
      produces "application/json"

      parameter name: :id,
                in: :path,
                type: :string,
                format: :uuid,
                required: true,
                description: "Customer ID"

      parameter name: :customer_params,
                in: :body,
                required: true,
                schema: {
                  type: :object,
                  properties: {
                    customer: {
                      type: :object,
                      properties: {
                        name: {
                          type: :string,
                          example: "Updated Customer"
                        },
                        email: {
                          type: :string,
                          format: :email,
                          example: "updated@commerceforge.dev"
                        },
                        phone: {
                          type: :string,
                          nullable: true,
                          example: "9999999999"
                        }
                      },
                      required: [ "customer" ]
                    }
                  }
                }

      response "200", "customer updated successfully" do
        let(:user) { create(:user) }
        let(:customer) { create(:customer) }
        let(:id) { customer.id }

        let(:customer_params) do
          {
            customer: {
              name: "Updated Customer",
              email: "updated@commerceforge.dev",
              phone: "9999999999"
            }
          }
        end

        let(:Authorization) { sign_in(user) }

        before do
          permission = create(
            :permission,
            name: "Update Customers",
            code: "customers.update"
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
                    },
                    created_at: {
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
        let(:customer) { create(:customer) }
        let(:id) { customer.id }
        let(:Authorization) { nil }

        let(:customer_params) do
          {
            customer: {
              name: "Updated Customer"
            }
          }
        end

        run_test!
      end

      response "403", "authorization failed" do
        let(:user) { create(:user) }
        let(:customer) { create(:customer) }
        let(:id) { customer.id }

        let(:Authorization) { sign_in(user) }

        let(:customer_params) do
          {
            customer: {
              name: "Updated Customer"
            }
          }
        end

        run_test!
      end

      response "404", "customer not found" do
        let(:user) { create(:user) }
        let(:id) { SecureRandom.uuid }

        let(:Authorization) { sign_in(user) }

        let(:customer_params) do
          {
            customer: {
              name: "Updated Customer"
            }
          }
        end

        before do
          permission = create(
            :permission,
            name: "Update Customers",
            code: "customers.update"
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

  path "/api/v1/customers/{id}/orders" do
    get "List customer orders" do
      tags "Customers"
      security [ bearerAuth: [] ]

      produces "application/json"

      parameter name: :id,
                in: :path,
                type: :string,
                format: :uuid,
                required: true,
                description: "Customer ID"

      response "200", "customer orders fetched successfully" do
        let(:user) { create(:user) }
        let(:customer) { create(:customer) }
        let(:id) { customer.id }

        let(:Authorization) { sign_in(user) }

        before do
          permission = create(
            :permission,
            name: "View Customers",
            code: "customers.read"
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

          order = create(
            :order,
            customer: customer,
            created_at: 1.day.ago
          )

          create(
            :order_item,
            order: order
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
                      order_items: {
                        type: :array,
                        items: {
                          type: :object,
                          properties: {
                            id: {
                              type: :string,
                              format: :uuid
                            },
                            product_id: {
                              type: :string,
                              format: :uuid
                            },
                            quantity: {
                              type: :integer
                            },
                            unit_price: {
                              type: :string
                            },
                            total_price: {
                              type: :string
                            }
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
        let(:customer) { create(:customer) }
        let(:id) { customer.id }
        let(:Authorization) { nil }

        run_test!
      end

      response "403", "authorization failed" do
        let(:user) { create(:user) }
        let(:customer) { create(:customer) }
        let(:id) { customer.id }

        let(:Authorization) { sign_in(user) }

        run_test!
      end

      response "404", "customer not found" do
        let(:user) { create(:user) }
        let(:id) { SecureRandom.uuid }

        let(:Authorization) { sign_in(user) }

        run_test!
      end
    end
  end
end
