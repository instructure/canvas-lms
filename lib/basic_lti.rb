module BasicLTI
  def self.explicit_signature_settings(timestamp, nonce)
    @timestamp = timestamp
    @nonce = nonce
  end
  
  def self.generate_params(params, url, key, secret)
    require 'uri'
    require 'oauth'
    require 'oauth/consumer'
    uri = URI.parse(url)

    if uri.port == uri.default_port
      host = uri.host
    else
      host = "#{uri.host}:#{uri.port}"
    end

    consumer = OAuth::Consumer.new(key, secret, {
      :site => "#{uri.scheme}://#{host}",
      :signature_method => "HMAC-SHA1"
    })

    path = uri.path
    path = '/' if path.empty?
    if !uri.query.blank?
      CGI.parse(uri.query).each do |query_key, query_values|
        unless params[query_key]
          params[query_key] = query_values.first
        end
      end
    end
    options = {
                :scheme           => 'body',
                :timestamp        => @timestamp,
                :nonce            => @nonce
              }
    request = consumer.create_signed_request(:post, path, nil, options, params)

    # the request is made by a html form in the user's browser, so we
    # want to revert the escapage and return the hash of post parameters ready
    # for embedding in a html view
    hash = {}
    request.body.split(/&/).each do |param|
      key, val = param.split(/=/).map{|v| CGI.unescape(v) }
      hash[key] = val
    end
    hash
  end
  
  def self.generate(*args)
    BasicLTI::ToolLaunch.new(*args).generate
  end

  class ToolLaunch < Struct.new(:url, :tool, :user, :context, :link_code, :return_url, :resource_type, :hash)

    def initialize(options)
      self.url = options[:url]                     || raise("URL required for generating Basic LTI content")
      self.tool = options[:tool]                   || raise("Tool required for generating Basic LTI content")
      self.user = options[:user]                   || raise("User required for generating Basic LTI content")
      self.context = options[:context]             || raise("Context required for generating Basic LTI content")
      self.link_code = options[:link_code]         || raise("Link Code required for generating Basic LTI content")
      self.return_url = options[:return_url]       || raise("Return URL required for generating Basic LTI content")
      self.resource_type = options[:resource_type]
      self.hash = {}
    end

    def for_assignment!(assignment, outcome_service_url, legacy_outcome_service_url)
      hash['lis_result_sourcedid'] = BasicLTI::BasicOutcomes.encode_source_id(tool, context, assignment, user)
      hash['lis_outcome_service_url'] = outcome_service_url
      hash['ext_ims_lis_basic_outcome_url'] = legacy_outcome_service_url
      if tool.public?
        hash['custom_canvas_assignment_id'] = assignment.id
      end
    end

    def generate
      hash['lti_message_type'] = 'basic-lti-launch-request'
      hash['lti_version'] = 'LTI-1p0'
      hash['resource_link_id'] = link_code
      hash['resource_link_title'] = tool.name
      hash['user_id'] = user.opaque_identifier(:asset_string)
      hash['roles'] = user.lti_role_types(context).join(',') # AccountAdmin, Student, Faculty or Observer
      if tool.include_name?
        hash['lis_person_name_given'] = user.first_name
        hash['lis_person_name_family'] = user.last_name
        hash['lis_person_name_full'] = user.name
      end
      if tool.include_email?
        hash['lis_person_contact_email_primary'] = user.email
      end
      if tool.public?
        hash['custom_canvas_user_id'] = user.id
        if context.respond_to?(:root_account)
          pseudo = user.sis_pseudonym_for(context)
        elsif tool.context && tool.context.respond_to?(:root_account)
          pseudo = user.sis_pseudonym_for(tool.context)
        end
        if pseudo
          hash['lis_person_sourcedid'] = pseudo.sis_user_id if pseudo.sis_user_id
          hash['custom_canvas_user_login_id'] = pseudo.unique_id
        end
        if context.is_a?(Course)
          hash['custom_canvas_course_id'] = context.id
          hash['lis_course_offering_sourcedid'] = context.sis_source_id if context.sis_source_id
        elsif context.is_a?(Account)
          hash['custom_canvas_account_id'] = context.id
          hash['custom_canvas_account_sis_id'] = context.sis_source_id if context.sis_source_id
        end
      end

      # need to set the locale here (instead of waiting for the first call to
      # I18n.t like we usually do), because otherwise we'll have the wrong code
      # for the launch_presentation_locale.
      I18n.set_locale_with_localizer

      hash['context_id'] = context.opaque_identifier(:asset_string)
      hash['context_title'] = context.name
      hash['context_label'] = context.course_code if context.respond_to?(:course_code)
      hash['launch_presentation_locale'] = I18n.locale || I18n.default_locale.to_s
      hash['launch_presentation_document_target'] = 'iframe'
      hash['launch_presentation_width'] = 600
      hash['launch_presentation_height'] = 400
      hash['launch_presentation_return_url'] = return_url
      root_context = (context.respond_to?(:root_account) && context.root_account) || context
      hash['tool_consumer_instance_guid'] = "#{root_context.opaque_identifier(:asset_string)}.#{HostUrl.context_host(context)}"
      hash['tool_consumer_instance_name'] = root_context.name
      hash['tool_consumer_instance_contact_email'] = HostUrl.outgoing_email_address # TODO: find a better email address to use here
      hash['tool_consumer_info_product_family_code'] = 'canvas'
      hash['tool_consumer_info_version'] = 'cloud'
      tool.set_custom_fields(hash, resource_type)
      if resource_type == 'editor_button'
        hash['selection_directive'] = 'embed_content'
      elsif resource_type == 'resource_selection'
        hash['selection_directive'] = 'select_link'
      end

      hash['oauth_callback'] = 'about:blank'
      BasicLTI.generate_params(hash, url, tool.consumer_key, tool.shared_secret)
    end

  end
end
