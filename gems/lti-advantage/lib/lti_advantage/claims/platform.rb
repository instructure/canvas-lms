require 'active_model'

module LtiAdvantage::Claims
  # Class represeting an LTI 1.3 message "tool_platform" claim.
  # http://purl.imsglobal.org/lti/claim/tool_platform
  class Platform
    include ActiveModel::Model

    attr_accessor :contact_email,
                  :description,
                  :guid,
                  :name,
                  :product_family_code,
                  :url,
                  :version
  end
end
