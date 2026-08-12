# frozen_string_literal: true

require "swagger_helper"

RSpec.describe "Authentication Me API", type: :request do
  path "/api/v1/auth/me" do
    get "Get current authenticated user" do
      tags "Authentication"
      produces "application/json"
      security [ bearerAuth: [] ]

      response "200", "authenticated user" do
        let(:user) do
          User.create!(
            email: "swagger@commerceforge.dev",
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

          expect(response).to have_http_status(:ok)
          expect(body["success"]).to be(true)
          expect(body["message"]).to eq(
            "Current user fetched successfully."
          )
          expect(body["data"]["user"]["id"]).to eq(user.id)
          expect(body["data"]["user"]["email"]).to eq(user.email)
          expect(body["errors"]).to eq([])
        end
      end

      response "401", "authentication failed" do
        let(:Authorization) { nil }

        run_test!
      end
    end
  end
end
