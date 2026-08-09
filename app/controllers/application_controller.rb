# frozen_string_literal: true

class ApplicationController < ActionController::API
  include Pundit::Authorization

  respond_to :json

  rescue_from Pundit::NotAuthorizedError, with: :render_authorization_error
  rescue_from ActiveRecord::RecordNotFound, with: :render_not_found

  private

  def render_success(data: {}, message: "Success", status: :ok)
    render json: {
      success: true,
      message: message,
      data: data,
      errors: []
    }, status: status
  end

  def render_error(
    message:,
    errors: [],
    status: :unprocessable_content
  )
    render json: {
      success: false,
      message: message,
      data: {},
      errors: errors
    }, status: status
  end

  def render_authorization_error(_exception)
    render_error(
      message: "You are not authorized to perform this action.",
      errors: [
        {
          code: "AUTHORIZATION_FAILED",
          message: "You are not authorized to perform this action."
        }
      ],
      status: :forbidden
    )
  end

  def render_not_found(exception)
    resource_name = exception.model.to_s.underscore.humanize

    render_error(
      message: "#{resource_name} not found.",
      errors: [
        {
          code: "RESOURCE_NOT_FOUND",
          message: "#{resource_name} not found."
        }
      ],
      status: :not_found
    )
  end
end
