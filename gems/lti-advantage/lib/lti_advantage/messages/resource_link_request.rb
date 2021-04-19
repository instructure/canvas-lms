# frozen_string_literal: true

module LtiAdvantage::Messages
  # Class represeting an LTI 1.3 LtiResourceLinkRequest.
  class ResourceLinkRequest < JwtMessage
    MESSAGE_TYPE = "LtiResourceLinkRequest"

    # Claims to type check
    TYPED_ATTRIBUTES = superclass::TYPED_ATTRIBUTES.merge(
      resource_link: LtiAdvantage::Claims::ResourceLink
    )

    attr_accessor *(REQUIRED_CLAIMS + [:resource_link])

    validates_presence_of *REQUIRED_CLAIMS
    validates_with LtiAdvantage::TypeValidator

    # Returns a new instance of LtiResourceLinkRequest.
    #
    # @param [Hash] attributes for message initialization.
    # @return [LtiResourceLinkRequest]
    def initialize(params = {})
      self.message_type = MESSAGE_TYPE
      self.version = "1.3.0"
      super
    end

    def resource_link
      @resource_link ||= TYPED_ATTRIBUTES[:resource_link].new
    end
  end
end
