module LtiAdvantage::Messages
  # Class represeting an LTI 1.3 LtiResourceLinkRequest.
  class ResourceLinkRequest < JwtMessage
    # Required claims for this message type
    REQUIRED_CLAIMS = superclass::REQUIRED_CLAIMS + %i[
      resource_link
    ].freeze

    # Claims to type check
    TYPED_ATTRIBUTES = superclass::TYPED_ATTRIBUTES.merge(
      resource_link: LtiAdvantage::Claims::ResourceLink
    )

    attr_accessor *REQUIRED_CLAIMS

    validates_presence_of *REQUIRED_CLAIMS
    validates_with LtiAdvantage::TypeValidator

    # Returns a new instance of LtiResourceLinkRequest.
    #
    # @param [Hash] attributes for message initialization.
    # @return [LtiResourceLinkRequest]
    def initialize(params = {})
      self.message_type = "LtiResourceLinkRequest"
      self.version = "1.3.0"
      super
    end

    def resource_link
      @resource_link ||= TYPED_ATTRIBUTES[:resource_link].new
    end
  end
end
