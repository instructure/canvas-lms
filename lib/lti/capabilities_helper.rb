module Lti
  class CapabilitiesHelper
    SUPPORTED_CAPABILITIES = %w(ToolConsumerInstance.guid
                                CourseSection.sourcedId
                                Membership.role
                                Person.email.primary
                                Person.name.given
                                Person.name.family
                                Person.name.full
                                Person.sourcedId
                                User.id
                                User.image
                                Message.documentTarget
                                Message.locale
                                Context.id
                                vnd.Canvas.root_account.uuid).freeze

    def self.supported_capabilities
      SUPPORTED_CAPABILITIES
    end

    def self.filter_capabilities(enabled_capability)
      enabled_capability & SUPPORTED_CAPABILITIES
    end

    def self.capability_params_hash(enabled_capability, variable_expander)
      variable_expander.enabled_capability_params(filter_capabilities(enabled_capability))
    end
  end
end
