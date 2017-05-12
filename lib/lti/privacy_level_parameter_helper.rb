module Lti
  class PrivacyLevelParameterHelper
    EMAIL_ONLY = %w(Person.email.primary).freeze
    INLCUDE_NAME = %w(Person.name.given Person.name.full Person.name.family).freeze
    PUBLIC = (%w(Person.sourcedId CourseOffering.sourcedId) + EMAIL_ONLY + INLCUDE_NAME).freeze
    ANONYMOUS = %w(com.instructure.contextLabel).freeze

    SUPPORTED_PARAMETERS_HASH = {
      public: PUBLIC,
      email_only: EMAIL_ONLY,
      name_only: INLCUDE_NAME,
      anonymous: ANONYMOUS
    }.freeze

    def initialize(tool:, placement:, context:, collaboration: nil, opts: {})
      @tool = tool
      @placement = placement
      @context = context
      @collaboration = collaboration
      @opts = opts.merge({tool: tool, collaboration: collaboration})
    end

    def expanded_variables
      variable_expander.expand_variables!(@tool.set_custom_fields(@placement)).merge(parameter_hash)
    end

    def supported_parameters
      SUPPORTED_PARAMETERS_HASH[:anonymous] | SUPPORTED_PARAMETERS_HASH[@tool.workflow_state.to_sym]
    end

    private

    def parameter_hash
      variable_expander.enabled_capability_params(supported_parameters)
    end

    def variable_expander
      @_varaible_expander ||= begin
        Lti::VariableExpander.new(@opts[:domain_root_account],
                                  @context,
                                  @opts[:controller],
                                  @opts)
      end
    end
  end
end
