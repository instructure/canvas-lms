# frozen_string_literal: true

module LtiAdvantage
  module Messages
    require_relative "messages/jwt_message"
    require_relative "messages/login_request"
    require_relative "messages/resource_link_request"
    require_relative "messages/deep_linking_request"
    require_relative "messages/pns_notice"
    require_relative "messages/asset_processor_settings_request"
    require_relative "messages/report_review_request"
    require_relative "messages/eula_request"
  end
end
