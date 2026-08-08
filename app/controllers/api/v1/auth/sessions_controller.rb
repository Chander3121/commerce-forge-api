module Api
  module V1
    module Auth
      class SessionsController < Devise::SessionsController
        respond_to :json

        private

        def respond_with(resource, _opts = {})
          render_success(
            message: "Login successful.",
            data: {
              user: {
                id: resource.id,
                email: resource.email
              }
            }
          )
        end

        def respond_to_on_destroy(_resource)
          render_success(
            message: "Logout successful.",
            data: {}
          )
        end
      end
    end
  end
end
