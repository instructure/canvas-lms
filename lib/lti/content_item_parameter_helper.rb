module Lti
  class ContentItemParameterHelper
    SUPPORTED_PARAMETERS = %w(com.instructure.contextLabel).freeze

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

    private

    def parameter_hash
      variable_expander.enabled_capability_params(SUPPORTED_PARAMETERS)
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
