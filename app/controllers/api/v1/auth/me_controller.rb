module Api
  module V1
    module Auth
      class MeController < Api::V1::BaseController
        before_action :authenticate_user!

        def show
          render_success(
            message: "Current user fetched successfully.",
            data: {
              user: {
                id: current_user.id,
                email: current_user.email
              }
            }
          )
        end
      end
    end
  end
end
