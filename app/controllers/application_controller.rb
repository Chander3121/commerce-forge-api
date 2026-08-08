class ApplicationController < ActionController::API
  respond_to :json

  private

  def render_success(data: {}, message: "Success", status: :ok)
    render json: {
      success: true,
      message: message,
      data: data,
      errors: []
    }, status: status
  end

  def render_error(message:, errors: [], status: :unprocessable_content)
    render json: {
      success: false,
      message: message,
      data: {},
      errors: errors
    }, status: status
  end
end
