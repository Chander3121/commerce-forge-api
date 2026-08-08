# frozen_string_literal: true

module Core
  module Authentication
    class FailureApp < Devise::FailureApp
      def respond
        render_authentication_error
      end

      private

      def render_authentication_error
        message = "Authentication failed."

        body = {
          success: false,
          message: message,
          data: {},
          errors: [
            {
              code: "AUTHENTICATION_FAILED",
              message: message
            }
          ]
        }.to_json

        self.status = :unauthorized
        self.content_type = "application/json"
        self.response_body = [ body ]
      end
    end
  end
end
