# frozen_string_literal: true

module RequestAuthentication
  def sign_in(user)
    post "/api/v1/auth/login",
         params: {
           user: {
             email: user.email,
             password: "Password@123"
           }
         },
         as: :json

    expect(response).to have_http_status(:ok)

    response.headers.fetch("Authorization")
  end

  def authenticated_headers(user)
    {
      "Authorization" => sign_in(user)
    }
  end
end
