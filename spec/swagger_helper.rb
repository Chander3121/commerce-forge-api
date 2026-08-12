# frozen_string_literal: true

require "rails_helper"

RSpec.configure do |config|
  config.openapi_root = Rails.root.join("swagger").to_s

  config.openapi_specs = {
    "v1/swagger.yaml" => {
      openapi: "3.0.1",
      info: {
        title: "Commerce Forge API",
        version: "v1",
        description: "Commerce Forge REST API"
      },
      paths: {},
      components: {
        securitySchemes: {
          bearerAuth: {
            type: :http,
            scheme: :bearer,
            bearerFormat: "JWT"
          }
        }
      },
      servers: [
        {
          url: "http://localhost:3000"
        }
      ]
    }
  }

  config.openapi_format = :yaml
end
