# frozen_string_literal: true

# Test-only routes for Selenium tests with mock LTI tool
# Only loaded when running Selenium tests in test environment
if Rails.env.test? && (ENV["SELENIUM"] || ENV["TEST_ENV_NUMBER"])
  Rails.application.routes.append do
    post "/test/mock_lti/ui", to: "test/mock_lti#ui"
    post "/test/mock_lti/login", to: "test/mock_lti#login"
    get "/test/mock_lti/jwks", to: "test/mock_lti#jwks"
    post "/test/mock_lti/subscription_handler", to: "test/mock_lti#subscription_handler"
  end

  Rails.logger.info "Selenium test-only routes registered for mock LTI tool"
end
