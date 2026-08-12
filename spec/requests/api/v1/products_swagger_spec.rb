# frozen_string_literal: true

require "swagger_helper"

RSpec.describe "Products API", type: :request do
  path "/api/v1/products" do
    get "List products" do
      tags "Products"
      produces "application/json"
      security [ bearerAuth: [] ]

      parameter name: :category_id,
                in: :query,
                type: :string,
                format: :uuid,
                required: false,
                description: "Filter products by category"

      parameter name: :search,
                in: :query,
                type: :string,
                required: false,
                description: "Search products by name or description"

      parameter name: :min_price,
                in: :query,
                type: :number,
                format: :float,
                required: false,
                description: "Minimum product price"

      parameter name: :max_price,
                in: :query,
                type: :number,
                format: :float,
                required: false,
                description: "Maximum product price"

      parameter name: :status,
                in: :query,
                type: :string,
                required: false,
                enum: %w[active inactive],
                description: "Filter products by status"

      parameter name: :sort_by,
                in: :query,
                type: :string,
                required: false,
                enum: %w[name price created_at],
                description: "Field used for sorting"

      parameter name: :sort_order,
                in: :query,
                type: :string,
                required: false,
                enum: %w[asc desc],
                description: "Sort direction"

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
                description: "Number of products per page"

      response "200", "products fetched successfully" do
        let(:user) { create(:user) }

        before do
          permission = create(
            :permission,
            name: "View Products",
            code: "products.read"
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

          create_list(:product, 2)
        end

        let(:Authorization) { sign_in(user) }

        schema(
          type: :object,
          properties: {
            success: {
              type: :boolean
            },
            message: {
              type: :string
            },
            data: {
              type: :object,
              properties: {
                products: {
                  type: :array,
                  items: {
                    type: :object,
                    properties: {
                      id: {
                        type: :string,
                        format: :uuid
                      },
                      name: {
                        type: :string
                      },
                      slug: {
                        type: :string
                      },
                      description: {
                        type: :string,
                        nullable: true
                      },
                      price: {
                        type: :string
                      },
                      status: {
                        type: :string,
                        enum: %w[active inactive]
                      },
                      category_id: {
                        type: :string,
                        format: :uuid
                      },
                      created_at: {
                        type: :string,
                        format: :"date-time"
                      },
                      updated_at: {
                        type: :string,
                        format: :"date-time"
                      },
                      category: {
                        type: :object,
                        properties: {
                          id: {
                            type: :string,
                            format: :uuid
                          },
                          name: {
                            type: :string
                          },
                          slug: {
                            type: :string
                          }
                        }
                      }
                    }
                  }
                },
                meta: {
                  type: :object,
                  properties: {
                    page: {
                      type: :integer
                    },
                    per_page: {
                      type: :integer
                    },
                    total: {
                      type: :integer
                    },
                    total_pages: {
                      type: :integer
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

        run_test! do |response|
          expect(response).to have_http_status(:ok)

          body = JSON.parse(response.body)

          expect(body["success"]).to be(true)
          expect(body["message"]).to eq(
            "Products fetched successfully."
          )
          expect(body["data"]["products"]).to be_an(Array)
          expect(body["data"]["meta"]).to include(
            "page",
            "per_page",
            "total",
            "total_pages"
          )
          expect(body["errors"]).to eq([])
        end
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

      response "422", "invalid price filter" do
        let(:user) { create(:user) }

        let(:min_price) { "abc" }
        let(:Authorization) { sign_in(user) }

        before do
          permission = create(
            :permission,
            name: "View Products",
            code: "products.read"
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

      response "422", "invalid price range" do
        let(:user) { create(:user) }

        let(:min_price) { 5000 }
        let(:max_price) { 1000 }
        let(:Authorization) { sign_in(user) }

        before do
          permission = create(
            :permission,
            name: "View Products",
            code: "products.read"
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

      response "422", "invalid product status" do
        let(:user) { create(:user) }

        let(:status) { "banana" }
        let(:Authorization) { sign_in(user) }

        before do
          permission = create(
            :permission,
            name: "View Products",
            code: "products.read"
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

    post "Create product" do
      tags "Products"
      consumes "application/json"
      produces "application/json"
      security [ bearerAuth: [] ]

      parameter name: :product,
                in: :body,
                required: true,
                schema: {
                  type: :object,
                  properties: {
                    product: {
                      type: :object,
                      properties: {
                        name: {
                          type: :string,
                          example: "MacBook Pro"
                        },
                        slug: {
                          type: :string,
                          example: "macbook-pro"
                        },
                        description: {
                          type: :string,
                          nullable: true,
                          example: "Professional laptop."
                        },
                        price: {
                          type: :string,
                          example: "1999.99"
                        },
                        status: {
                          type: :string,
                          enum: %w[active inactive],
                          example: "active"
                        },
                        category_id: {
                          type: :string,
                          format: :uuid,
                          example: "0e3edee2-6226-4a68-bb72-b9d4442b681f"
                        }
                      },
                      required: %w[
                        name
                        slug
                        price
                        status
                        category_id
                      ]
                    }
                  },
                  required: [ "product" ]
                }

      response "201", "product created successfully" do
        let(:user) { create(:user) }
        let(:category) { create(:category) }

        let(:product) do
          {
            product: {
              name: "MacBook Pro",
              slug: "macbook-pro",
              description: "Professional laptop.",
              price: "1999.99",
              status: "active",
              category_id: category.id
            }
          }
        end

        before do
          permission = create(
            :permission,
            name: "Create Products",
            code: "products.create"
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

        schema type: :object,
               properties: {
                 success: { type: :boolean },
                 message: { type: :string },
                 data: {
                   type: :object,
                   properties: {
                     product: {
                       type: :object,
                       properties: {
                         id: {
                           type: :string,
                           format: :uuid
                         },
                         name: { type: :string },
                         slug: { type: :string },
                         description: {
                           type: :string,
                           nullable: true
                         },
                         price: {
                           type: :string
                         },
                         status: {
                           type: :string
                         },
                         category_id: {
                           type: :string,
                           format: :uuid
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

        run_test! do |response|
          expect(response).to have_http_status(:created)

          body = JSON.parse(response.body)

          expect(body["success"]).to be(true)
          expect(body["message"]).to eq(
            "Product created successfully."
          )
          expect(body["data"]["product"]["name"]).to eq("MacBook Pro")
          expect(body["data"]["product"]["category_id"]).to eq(category.id)
          expect(body["errors"]).to eq([])
        end
      end

      response "401", "authentication failed" do
        let(:Authorization) { nil }

        let(:category) { create(:category) }

        let(:product) do
          {
            product: {
              name: "MacBook Pro",
              slug: "macbook-pro",
              description: "Professional laptop.",
              price: "1999.99",
              status: "active",
              category_id: category.id
            }
          }
        end

        run_test!
      end

      response "403", "authorization failed" do
        let(:user) { create(:user) }
        let(:Authorization) { sign_in(user) }

        let(:category) { create(:category) }

        let(:product) do
          {
            product: {
              name: "MacBook Pro",
              slug: "macbook-pro",
              description: "Professional laptop.",
              price: "1999.99",
              status: "active",
              category_id: category.id
            }
          }
        end

        run_test!
      end

      response "422", "invalid product" do
        let(:user) { create(:user) }
        let(:Authorization) { sign_in(user) }

        let(:category) { create(:category) }

        let(:product) do
          {
            product: {
              name: "",
              slug: "",
              price: "-100",
              status: "invalid",
              category_id: category.id
            }
          }
        end

        before do
          permission = create(
            :permission,
            name: "Create Products",
            code: "products.create"
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

  path "/api/v1/products/{id}" do
    get "Get product" do
      tags "Products"
      produces "application/json"
      security [ bearerAuth: [] ]

      parameter name: :id,
                in: :path,
                type: :string,
                format: :uuid,
                required: true,
                description: "Product ID"

      response "200", "product fetched successfully" do
        let(:user) { create(:user) }
        let(:product) { create(:product) }
        let(:id) { product.id }

        before do
          permission = create(
            :permission,
            name: "View Products",
            code: "products.read"
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

        schema type: :object,
               properties: {
                 success: {
                   type: :boolean
                 },
                 message: {
                   type: :string
                 },
                 data: {
                   type: :object,
                   properties: {
                     product: {
                       type: :object,
                       properties: {
                         id: {
                           type: :string,
                           format: :uuid
                         },
                         category_id: {
                           type: :string,
                           format: :uuid
                         },
                         created_at: {
                           type: :string,
                           format: :"date-time"
                         },
                         description: {
                           type: :string,
                           nullable: true
                         },
                         name: {
                           type: :string
                         },
                         price: {
                           type: :string,
                           example: "999.99"
                         },
                         slug: {
                           type: :string
                         },
                         status: {
                           type: :string,
                           enum: %w[active inactive]
                         },
                         updated_at: {
                           type: :string,
                           format: :"date-time"
                         },
                         category: {
                           type: :object,
                           properties: {
                             id: {
                               type: :string,
                               format: :uuid
                             },
                             name: {
                               type: :string
                             },
                             slug: {
                               type: :string
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

        run_test! do |response|
          expect(response).to have_http_status(:ok)

          body = JSON.parse(response.body)

          expect(body["success"]).to be(true)
          expect(body["message"]).to eq(
            "Product fetched successfully."
          )
          expect(body["data"]["product"]["id"]).to eq(product.id)
          expect(body["errors"]).to eq([])
        end
      end

      response "401", "authentication failed" do
        let(:Authorization) { nil }

        let(:id) { create(:product).id }

        run_test!
      end

      response "403", "authorization failed" do
        let(:user) { create(:user) }
        let(:product) { create(:product) }
        let(:id) { product.id }

        let(:Authorization) { sign_in(user) }

        run_test!
      end

      response "404", "product not found" do
        let(:user) { create(:user) }
        let(:id) { 999_999_999 }

        before do
          permission = create(
            :permission,
            name: "View Products",
            code: "products.read"
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

    patch "Update product" do
      tags "Products"
      consumes "application/json"
      produces "application/json"
      security [ bearerAuth: [] ]

      parameter name: :id,
                in: :path,
                type: :string,
                format: :uuid,
                required: true,
                description: "Product ID"

      parameter name: :product,
                in: :body,
                required: true,
                schema: {
                  type: :object,
                  properties: {
                    product: {
                      type: :object,
                      properties: {
                        name: {
                          type: :string,
                          example: "MacBook Pro M4"
                        },
                        slug: {
                          type: :string,
                          example: "macbook-pro-m4"
                        },
                        description: {
                          type: :string,
                          nullable: true,
                          example: "Updated professional laptop."
                        },
                        price: {
                          type: :string,
                          example: "2199.99"
                        },
                        status: {
                          type: :string,
                          enum: %w[active inactive],
                          example: "active"
                        },
                        category_id: {
                          type: :string,
                          format: :uuid,
                          example: "0e3edee2-6226-4a68-bb72-b9d4442b681f"
                        }
                      }
                    }
                  },
                  required: [ "product" ]
                }

      response "200", "product updated successfully" do
        let(:user) { create(:user) }
        let(:product_record) { create(:product) }
        let(:id) { product_record.id }

        let(:product) do
          {
            product: {
              name: "Updated MacBook Pro",
              description: "Updated professional laptop.",
              price: "2199.99",
              status: "active"
            }
          }
        end

        before do
          permission = create(
            :permission,
            name: "Update Products",
            code: "products.update"
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

        schema type: :object,
               properties: {
                 success: { type: :boolean },
                 message: { type: :string },
                 data: {
                   type: :object,
                   properties: {
                     product: {
                       type: :object
                     }
                   }
                 },
                 errors: {
                   type: :array
                 }
               }

        run_test! do |response|
          expect(response).to have_http_status(:ok)

          body = JSON.parse(response.body)

          expect(body["success"]).to be(true)
          expect(body["message"]).to eq(
            "Product updated successfully."
          )
          expect(body["data"]["product"]["id"]).to eq(product_record.id)
          expect(body["data"]["product"]["name"]).to eq(
            "Updated MacBook Pro"
          )
          expect(body["errors"]).to eq([])
        end
      end

      response "401", "authentication failed" do
        let(:Authorization) { nil }
        let(:id) { create(:product).id }

        let(:product) do
          {
            product: {
              name: "Updated Product"
            }
          }
        end

        run_test!
      end

      response "403", "authorization failed" do
        let(:user) { create(:user) }
        let(:product_record) { create(:product) }
        let(:id) { product_record.id }

        let(:product) do
          {
            product: {
              name: "Updated Product"
            }
          }
        end

        let(:Authorization) { sign_in(user) }

        run_test!
      end

      response "404", "product not found" do
        let(:user) { create(:user) }
        let(:id) { "00000000-0000-0000-0000-000000000000" }

        let(:product) do
          {
            product: {
              name: "Updated Product"
            }
          }
        end

        before do
          permission = create(
            :permission,
            name: "Update Products",
            code: "products.update"
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

      response "422", "invalid product" do
        let(:user) { create(:user) }
        let(:product_record) { create(:product) }
        let(:id) { product_record.id }

        let(:product) do
          {
            product: {
              name: "",
              price: "-100"
            }
          }
        end

        before do
          permission = create(
            :permission,
            name: "Update Products",
            code: "products.update"
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

    delete "Delete product" do
      tags "Products"
      produces "application/json"
      security [ bearerAuth: [] ]

      parameter name: :id,
                in: :path,
                type: :string,
                format: :uuid,
                required: true,
                description: "Product ID"

      response "200", "product deleted successfully" do
        let(:user) { create(:user) }
        let(:product_record) { create(:product) }
        let(:id) { product_record.id }

        before do
          permission = create(
            :permission,
            name: "Delete Products",
            code: "products.delete"
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

        run_test! do |response|
          expect(response).to have_http_status(:ok)
          expect(Product.exists?(product_record.id)).to be(false)
        end
      end

      response "401", "authentication failed" do
        let(:Authorization) { nil }
        let(:id) { create(:product).id }

        run_test!
      end

      response "403", "authorization failed" do
        let(:user) { create(:user) }
        let(:product_record) { create(:product) }
        let(:id) { product_record.id }

        let(:Authorization) { sign_in(user) }

        run_test!
      end

      response "404", "product not found" do
        let(:user) { create(:user) }
        let(:id) { "00000000-0000-0000-0000-000000000000" }

        before do
          permission = create(
            :permission,
            name: "Delete Products",
            code: "products.delete"
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
end
