# frozen_string_literal: true

require "swagger_helper"

RSpec.describe "Categories API", type: :request do
  path "/api/v1/categories" do
    get "List categories" do
      tags "Categories"
      produces "application/json"
      security [ bearerAuth: [] ]

      response "200", "categories fetched successfully" do
        let(:user) { create(:user) }
        let!(:category) { create(:category) }

        before do
          permission = create(
            :permission,
            name: "View Categories",
            code: "categories.read"
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
                categories: {
                  type: :array,
                  items: {
                    type: :object
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
            "Categories fetched successfully."
          )
          expect(body["data"]["categories"]).to be_an(Array)
          expect(body["data"]["categories"].first["id"]).to eq(
            category.id
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
    end

    post "Create category" do
      tags "Categories"
      consumes "application/json"
      produces "application/json"
      security [ bearerAuth: [] ]

      parameter name: :category,
                in: :body,
                required: true,
                schema: {
                  type: :object,
                  properties: {
                    category: {
                      type: :object,
                      properties: {
                        name: {
                          type: :string,
                          example: "Electronics"
                        },
                        slug: {
                          type: :string,
                          example: "electronics"
                        },
                        description: {
                          type: :string,
                          nullable: true,
                          example: "Electronic products"
                        }
                      },
                      required: %w[name slug]
                    }
                  },
                  required: [ "category" ]
                }

      response "201", "category created successfully" do
        let(:user) { create(:user) }

        let(:category) do
          {
            category: {
              name: "Electronics",
              slug: "electronics",
              description: "Electronic products"
            }
          }
        end

        before do
          permission = create(
            :permission,
            name: "Create Categories",
            code: "categories.create"
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
                     category: {
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

        run_test!
      end

      response "401", "authentication failed" do
        let(:Authorization) { nil }

        let(:category) do
          {
            category: {
              name: "Electronics",
              slug: "electronics"
            }
          }
        end

        run_test!
      end

      response "403", "authorization failed" do
        let(:user) { create(:user) }

        let(:category) do
          {
            category: {
              name: "Electronics",
              slug: "electronics"
            }
          }
        end

        let(:Authorization) { sign_in(user) }

        run_test!
      end

      response "422", "category could not be created" do
        let(:user) { create(:user) }

        let(:category) do
          {
            category: {
              name: "",
              slug: ""
            }
          }
        end

        before do
          permission = create(
            :permission,
            name: "Create Categories",
            code: "categories.create"
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

  path "/api/v1/categories/{id}" do
    get "Get category" do
      tags "Categories"
      produces "application/json"
      security [ bearerAuth: [] ]

      parameter name: :id,
                in: :path,
                type: :string,
                format: :uuid,
                required: true,
                description: "Category ID"

      response "200", "category fetched successfully" do
        let(:user) { create(:user) }
        let(:category) { create(:category) }
        let(:id) { category.id }

        before do
          permission = create(
            :permission,
            name: "View Categories",
            code: "categories.read"
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
                     category: {
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

        run_test!
      end

      response "401", "authentication failed" do
        let(:Authorization) { nil }
        let(:id) { create(:category).id }

        run_test!
      end

      response "403", "authorization failed" do
        let(:user) { create(:user) }
        let(:id) { create(:category).id }

        let(:Authorization) { sign_in(user) }

        run_test!
      end

      response "404", "category not found" do
        let(:user) { create(:user) }
        let(:id) { "00000000-0000-0000-0000-000000000000" }

        before do
          permission = create(
            :permission,
            name: "View Categories",
            code: "categories.read"
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

    patch "Update category" do
      tags "Categories"
      consumes "application/json"
      produces "application/json"
      security [ bearerAuth: [] ]

      parameter name: :id,
                in: :path,
                type: :string,
                format: :uuid,
                required: true,
                description: "Category ID"

      parameter name: :category_params,
                in: :body,
                required: true,
                schema: {
                  type: :object,
                  properties: {
                    category: {
                      type: :object,
                      properties: {
                        name: {
                          type: :string,
                          example: "Updated Electronics"
                        },
                        slug: {
                          type: :string,
                          example: "updated-electronics"
                        },
                        description: {
                          type: :string,
                          nullable: true,
                          example: "Updated category description."
                        }
                      }
                    }
                  },
                  required: [ "category" ]
                }

      response "200", "category updated successfully" do
        let(:user) { create(:user) }
        let(:category) { create(:category) }
        let(:id) { category.id }

        let(:category_params) do
          {
            category: {
              name: "Updated Electronics",
              description: "Updated category description."
            }
          }
        end

        before do
          permission = create(
            :permission,
            name: "Update Categories",
            code: "categories.update"
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
                     category: {
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

        run_test!
      end

      response "401", "authentication failed" do
        let(:Authorization) { nil }
        let(:category) { create(:category) }
        let(:id) { category.id }

        let(:category_params) do
          {
            category: {
              name: "Updated Electronics"
            }
          }
        end

        run_test!
      end

      response "403", "authorization failed" do
        let(:user) { create(:user) }
        let(:category) { create(:category) }
        let(:id) { category.id }

        let(:category_params) do
          {
            category: {
              name: "Updated Electronics"
            }
          }
        end

        let(:Authorization) { sign_in(user) }

        run_test!
      end

      response "422", "category could not be updated" do
        let(:user) { create(:user) }

        let!(:existing_category) do
          create(
            :category,
            name: "Existing Electronics",
            slug: "electronics"
          )
        end

        let!(:category) do
          create(
            :category,
            name: "Books",
            slug: "books"
          )
        end

        let(:id) { category.id }

        let(:category_params) do
          {
            category: {
              slug: "electronics"
            }
          }
        end

        before do
          permission = create(
            :permission,
            name: "Update Categories",
            code: "categories.update"
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

    delete "Delete category" do
      tags "Categories"
      produces "application/json"
      security [ bearerAuth: [] ]

      parameter name: :id,
                in: :path,
                type: :string,
                format: :uuid,
                required: true,
                description: "Category ID"

      response "200", "category deleted successfully" do
        let(:user) { create(:user) }
        let!(:category) { create(:category) }
        let(:id) { category.id }

        before do
          permission = create(
            :permission,
            name: "Delete Categories",
            code: "categories.delete"
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
                 data: { type: :object },
                 errors: { type: :array }
               }

        run_test!
      end

      response "401", "authentication failed" do
        let!(:category) { create(:category) }
        let(:id) { category.id }
        let(:Authorization) { nil }

        run_test!
      end

      response "403", "authorization failed" do
        let(:user) { create(:user) }
        let!(:category) { create(:category) }
        let(:id) { category.id }

        let(:Authorization) { sign_in(user) }

        run_test!
      end

      response "422", "category could not be deleted" do
        let(:user) { create(:user) }
        let!(:category) { create(:category) }
        let(:id) { category.id }

        before do
          create(:product, category: category)

          permission = create(
            :permission,
            name: "Delete Categories",
            code: "categories.delete"
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
