# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Authentication Sessions", type: :request do
  let(:user) do
    User.create!(
      email: "test@commerceforge.dev",
      password: "Password@123",
      password_confirmation: "Password@123",
      jti: SecureRandom.uuid
    )
  end

  let(:login_path) { "/api/v1/auth/login" }
  let(:logout_path) { "/api/v1/auth/logout" }

  describe "POST /api/v1/auth/login" do
    context "with valid credentials" do
      it "authenticates the user and returns a JWT" do
        post login_path,
             params: {
               user: {
                 email: user.email,
                 password: "Password@123"
               }
             },
             as: :json

        expect(response).to have_http_status(:ok)

        body = JSON.parse(response.body)

        expect(body).to include(
          "success" => true,
          "message" => "Login successful."
        )

        expect(body["data"]["user"]).to include(
          "id" => user.id,
          "email" => user.email
        )

        expect(body["errors"]).to eq([])

        expect(response.headers["Authorization"]).to start_with("Bearer ")
      end
    end

    context "with invalid password" do
      it "rejects the authentication request" do
        post login_path,
             params: {
               user: {
                 email: user.email,
                 password: "WrongPassword@123"
               }
             },
             as: :json

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

    context "with unknown email" do
      it "rejects the authentication request" do
        post login_path,
             params: {
               user: {
                 email: "unknown@commerceforge.dev",
                 password: "Password@123"
               }
             },
             as: :json

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
  end

  describe "DELETE /api/v1/auth/logout" do
    it "logs out the authenticated user" do
      post login_path,
           params: {
             user: {
               email: user.email,
               password: "Password@123"
             }
           },
           as: :json

      token = response.headers["Authorization"]

      expect(token).to start_with("Bearer ")

      delete logout_path,
             headers: {
               "Authorization" => token,
               "Accept" => "application/json"
             }

      expect(response).to have_http_status(:ok)

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
