module Lti
  class LtiOutboundAdapter
    cattr_writer :consumer_instance_class

    def self.consumer_instance_class
      @@consumer_instance_class || LtiOutbound::LTIConsumerInstance
    end

    def initialize(tool, user, context)
      @tool = tool
      @user = user
      @context = context

      if @context.respond_to? :root_account
        @root_account = @context.root_account
      elsif @tool.context.respond_to? :root_account
        @root_account = @tool.context.root_account
      else
        raise('Root account required for generating LTI content')
      end
    end

    # @argument opts
    #   resource_type:
    #   selected_html: selected text to be sent to the tool provider as text
    #   launch_url: a specific launch url for this launch
    #   link_code: the resource_link_id for this launch
    #   overrides
    #   custom_substitutions: hash of translations values for custom variable
    #      substitutions where the key is what we are translating from, and the value
    #      is what we are translating to
    def prepare_tool_launch(return_url, opts = {})
      resource_type = opts[:resource_type]
      selected_html = opts[:selected_html]
      launch_url = opts[:launch_url] || default_launch_url(resource_type)
      link_code = opts[:link_code] || default_link_code
      @overrides = opts[:overrides] || {}

      variable_substitutor = LtiOutbound::VariableSubstitutor.new

      lti_context = Lti::LtiContextCreator.new(@context, @tool).convert
      lti_user = Lti::LtiUserCreator.new(@user, @root_account, @tool, @context, variable_substitutor).convert if @user
      lti_tool = Lti::LtiToolCreator.new(@tool).convert
      lti_account = Lti::LtiAccountCreator.new(@context, @tool).convert

      #Account
      variable_substitutor.add_substitution('$Canvas.account.id', lti_account.id)
      variable_substitutor.add_substitution('$Canvas.account.name', lti_account.name)
      variable_substitutor.add_substitution('$Canvas.account.sisSourceId', lti_account.sis_source_id)
      #Consumer Instance
      variable_substitutor.add_substitution('$Canvas.root_account.id', lti_context.consumer_instance.id)
      variable_substitutor.add_substitution('$Canvas.root_account.sisSourceId', lti_context.consumer_instance.sis_source_id)
      #Course
      if lti_context.is_a? LtiOutbound::LTICourse
        variable_substitutor.add_substitution('$Canvas.course.id', lti_context.id)
        variable_substitutor.add_substitution('$Canvas.course.sisSourceId', lti_context.sis_source_id)
      end
      # temporary until lti 2 infrastructure is in place
      lti_helper = Lti::SubstitutionsHelper.new(@context, @root_account, @user)
      variable_substitutor.add_substitution('$Canvas.xuser.allRoles', lti_helper.all_roles)

      if opts[:custom_substitutions]
        opts[:custom_substitutions].each do |key, value|
          variable_substitutor.add_substitution(key, value)
        end
      end

      @tool_launch = LtiOutbound::ToolLaunch.new(
          {
              url: launch_url,
              link_code: link_code,
              return_url: return_url,
              resource_type: resource_type,
              selected_html: selected_html,
              outgoing_email_address: HostUrl.outgoing_email_address,
              context: lti_context,
              user: lti_user,
              tool: lti_tool,
              account: lti_account,
              :variable_substitutor => variable_substitutor
          }
      )
      self
    end

    def generate_post_payload
      raise('Called generate_post_payload before calling prepare_tool_launch') unless @tool_launch
      @tool_launch.generate(@overrides)
    end

    def generate_post_payload_for_assignment(assignment, outcome_service_url, legacy_outcome_service_url)
      raise('Called generate_post_payload_for_assignment before calling prepare_tool_launch') unless @tool_launch
      lti_assignment = Lti::LtiAssignmentCreator.new(assignment, encode_source_id(assignment)).convert
      @tool_launch.for_assignment!(lti_assignment, outcome_service_url, legacy_outcome_service_url)
      generate_post_payload
    end

    def generate_post_payload_for_homework_submission(assignment)
      raise('Called generate_post_payload_for_homework_submission before calling prepare_tool_launch') unless @tool_launch
      lti_assignment = Lti::LtiAssignmentCreator.new(assignment).convert
      @tool_launch.for_homework_submission!(lti_assignment)
      generate_post_payload
    end

    def launch_url
      raise('Called launch_url before calling prepare_tool_launch') unless @tool_launch
      @tool_launch.url
    end

    private
    def default_launch_url(resource_type = nil)
      resource_type ? @tool.extension_setting(resource_type, :url) : @tool.url
    end

    def default_link_code
      @tool.opaque_identifier_for(@context)
    end

    # this is the lis_result_sourcedid field in the launch, and the
    # sourcedGUID/sourcedId in BLTI basic outcome requests.
    # it's a secure signature of the (tool, course, assignment, user). Combined with
    # the pre-determined shared secret that the tool signs requests with, this
    # ensures that only this launch of the tool can modify the score.
    def encode_source_id(assignment)
      @tool.shard.activate do
        payload = [@tool.id, @context.id, assignment.id, @user.id].join('-')
        "#{payload}-#{Canvas::Security.hmac_sha1(payload)}"
      end
    end
  end
end
