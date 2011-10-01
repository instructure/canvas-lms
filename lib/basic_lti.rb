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
    request = consumer.send(:create_http_request, :post, path, params)
    options = {
                :request_uri      => request.send(:oauth_full_request_uri, consumer.http),
                :consumer         => consumer,
                :token            => nil,
                :scheme           => 'body',
                :signature_method => 'HMAC-SHA1',
                :timestamp        => @timestamp,
                :nonce            => @nonce
              }
    options[:uri] = options[:request_uri]
    request.oauth!(consumer.http, consumer, nil, options)
    hash = {}
    request.body.split(/&/).each do |param|
      key, val = param.split(/=/).map{|v| URI.unescape(v) }
      hash[key] = val
    end
    hash
  end
  
  def self.generate(url, tool, user, context, link_code, return_url)
    hash = {}
    hash['lti_message_type'] = 'basic-lti-launch-request'
    hash['lti_version'] = 'LTI-1p0'
    hash['resource_link_id'] = link_code
    hash['resource_link_title'] = tool.name
    hash['user_id'] = user.opaque_identifier(:asset_string)
    hash['roles'] = user.lti_role_types.join(',') # AccountAdmin, Student, Faculty or Observer
    if tool.include_name?
      last, other = user.last_name_first.split(/,/, 2)
      hash['lis_person_name_given'] = other
      hash['lis_person_name_family'] = last
      hash['lis_person_name_full'] = user.name
    end
    if tool.include_email?
      hash['lis_person_contact_email_primary'] = user.email
    end
    if tool.public?
      hash['custom_canvas_user_id'] = user.id
      hash['custom_canvas_course_id'] = context.id
    end
    hash['context_id'] = context.opaque_identifier(:asset_string)
    hash['context_title'] = context.name
    hash['context_label'] = context.course_code rescue nil
    hash['launch_presentation_local'] = 'en-US' # TODO: I18N
    hash['launch_presentation_document_target'] = 'iframe'
    hash['launch_presentation_width'] = 600
    hash['launch_presentation_height'] = 400
    hash['launch_presentation_return_url'] = return_url
    hash['tool_consumer_instance_guid'] = "#{(context.root_account || context).opaque_identifier(:asset_string)}.#{HostUrl.context_host(context)}"
    hash['tool_consumer_instance_name'] = (context.root_account || context).name
    hash['tool_consumer_instance_contact_email'] = HostUrl.outgoing_email_address # TODO: find a better email address to use here
    (tool.settings[:custom_fields] || {}).each do |key, val|
      hash[key] = val if key.match(/\Acustom_/)
    end
    
    hash['oauth_callback'] = 'about:blank'
    generate_params(hash, url, tool.consumer_key, tool.shared_secret)
  end
end
