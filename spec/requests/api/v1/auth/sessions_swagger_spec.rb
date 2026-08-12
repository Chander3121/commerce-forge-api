# frozen_string_literal: true

require "swagger_helper"

RSpec.describe "Authentication Sessions API", type: :request do
  path "/api/v1/auth/login" do
    post "Login user" do
      tags "Authentication"
      consumes "application/json"
      produces "application/json"

      parameter name: :credentials,
                in: :body,
                required: true,
                schema: {
                  type: :object,
                  properties: {
                    user: {
                      type: :object,
                      properties: {
                        email: {
                          type: :string,
                          format: :email,
                          example: "test@commerceforge.dev"
                        },
                        password: {
                          type: :string,
                          format: :password,
                          example: "Password@123"
                        }
                      },
                      required: %w[email password]
                    }
                  },
                  required: [ "user" ]
                }

      response "200", "login successful" do
        let(:user) do
          User.create!(
            email: "swagger-login@commerceforge.dev",
            password: "Password@123",
            password_confirmation: "Password@123",
            jti: SecureRandom.uuid
          )
        end

        let(:credentials) do
          {
            user: {
              email: user.email,
              password: "Password@123"
            }
          }
        end

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
                     user: {
                       type: :object,
                       properties: {
                         id: {
                           type: :string,
                           format: :uuid
                         },
                         email: {
                           type: :string,
                           format: :email
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
          body = JSON.parse(response.body)

          expect(body["success"]).to be(true)
          expect(body["message"]).to eq("Login successful.")
          expect(body["data"]["user"]["id"]).to eq(user.id)
          expect(body["data"]["user"]["email"]).to eq(user.email)
          expect(body["errors"]).to eq([])

          expect(response.headers["Authorization"]).to start_with("Bearer ")
        end
      end

      response "401", "authentication failed" do
        let(:credentials) do
          {
            user: {
              email: "unknown@commerceforge.dev",
              password: "WrongPassword@123"
            }
          }
        end

        run_test! do |response|
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
    end
  end

  path "/api/v1/auth/logout" do
    delete "Logout user" do
      tags "Authentication"
      produces "application/json"
      security [ bearerAuth: [] ]

      response "200", "logout successful" do
        let(:user) do
          User.create!(
            email: "swagger-logout@commerceforge.dev",
            password: "Password@123",
            password_confirmation: "Password@123",
            jti: SecureRandom.uuid
          )
        end

        let(:Authorization) do
          post "/api/v1/auth/login",
               params: {
                 user: {
                   email: user.email,
                   password: "Password@123"
                 }
               },
               as: :json

          response.headers.fetch("Authorization")
        end

        schema type: :object,
               properties: {
                 success: {
                   type: :boolean
                 },
                 message: {
                   type: :string
                 },
                 data: {
                   type: :object
                 },
                 errors: {
                   type: :array
                 }
               }

        run_test! do |response|
          body = JSON.parse(response.body)

          expect(body).to eq(
            "success" => true,
            "message" => "Logout successful.",
            "data" => {},
            "errors" => []
          )
        end
      end
    end
  end
end
