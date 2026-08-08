# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Authentication Me", type: :request do
  let(:me_path) { "/api/v1/auth/me" }

  let(:user) do
    User.create!(
      email: "test@commerceforge.dev",
      password: "Password@123",
      password_confirmation: "Password@123",
      jti: SecureRandom.uuid
    )
  end

  def login_and_get_token
    post "/api/v1/auth/login",
         params: {
           user: {
             email: user.email,
             password: "Password@123"
           }
         },
         as: :json

    expect(response).to have_http_status(:ok)

    response.headers["Authorization"]
  end

  describe "GET /api/v1/auth/me" do
    context "with a valid JWT" do
      it "returns the authenticated user" do
        token = login_and_get_token

        get me_path,
            headers: {
              "Authorization" => token,
              "Accept" => "application/json"
            }

        expect(response).to have_http_status(:ok)

        body = JSON.parse(response.body)

        expect(body).to eq(
          "success" => true,
          "message" => "Current user fetched successfully.",
          "data" => {
            "user" => {
              "id" => user.id,
              "email" => user.email
            }
          },
          "errors" => []
        )
      end
    end

    context "without a JWT" do
      it "rejects the request" do
        get me_path,
            headers: {
              "Accept" => "application/json"
            }

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

    context "with an invalid JWT" do
      it "rejects the request" do
        get me_path,
            headers: {
              "Authorization" => "Bearer invalid.jwt.token",
              "Accept" => "application/json"
            }

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

    context "with a revoked JWT" do
      it "rejects the request after logout" do
        token = login_and_get_token

        delete "/api/v1/auth/logout",
               headers: {
                 "Authorization" => token,
                 "Accept" => "application/json"
               }

        expect(response).to have_http_status(:ok)

        get me_path,
            headers: {
              "Authorization" => token,
              "Accept" => "application/json"
            }

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
end
