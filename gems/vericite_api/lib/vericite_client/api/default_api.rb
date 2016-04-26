=begin
VeriCiteV1
=end

require "uri"

module VeriCiteClient
  class DefaultApi
    attr_accessor :api_client

    def initialize(api_client = ApiClient.default)
      @api_client = api_client
    end

    # 
    # Create/update assignment
    # @param context_id Context ID
    # @param assignment_id ID of assignment
    # @param consumer the consumer
    # @param consumer_secret the consumer secret
    # @param assignment_data 
    # @param [Hash] opts the optional parameters
    # @return [Array<ExternalContentUploadInfo>]
    def assignments_context_id_assignment_id_post(context_id, assignment_id, consumer, consumer_secret, assignment_data, opts = {})
      data, status_code, headers = assignments_context_id_assignment_id_post_with_http_info(context_id, assignment_id, consumer, consumer_secret, assignment_data, opts)
      return data, status_code, headers
    end

    # 
    # Create/update assignment
    # @param context_id Context ID
    # @param assignment_id ID of assignment
    # @param consumer the consumer
    # @param consumer_secret the consumer secret
    # @param assignment_data 
    # @param [Hash] opts the optional parameters
    # @return [Array<(Array<ExternalContentUploadInfo>, Fixnum, Hash)>] Array<ExternalContentUploadInfo> data, response status code and response headers
    def assignments_context_id_assignment_id_post_with_http_info(context_id, assignment_id, consumer, consumer_secret, assignment_data, opts = {})
      if @api_client.config.debugging
        @api_client.config.logger.debug "Calling API: DefaultApi#assignments_context_id_assignment_id_post ..."
      end
      
      # verify the required parameter 'context_id' is set
      fail "Missing the required parameter 'context_id' when calling assignments_context_id_assignment_id_post" if context_id.nil?
      
      # verify the required parameter 'assignment_id' is set
      fail "Missing the required parameter 'assignment_id' when calling assignments_context_id_assignment_id_post" if assignment_id.nil?
      
      # verify the required parameter 'consumer' is set
      fail "Missing the required parameter 'consumer' when calling assignments_context_id_assignment_id_post" if consumer.nil?
      
      # verify the required parameter 'consumer_secret' is set
      fail "Missing the required parameter 'consumer_secret' when calling assignments_context_id_assignment_id_post" if consumer_secret.nil?
      
      # verify the required parameter 'assignment_data' is set
      fail "Missing the required parameter 'assignment_data' when calling assignments_context_id_assignment_id_post" if assignment_data.nil?
      
      # resource path
      local_var_path = "/assignments/{contextID}/{assignmentID}".sub('{format}','json').sub('{' + 'contextID' + '}', context_id.to_s).sub('{' + 'assignmentID' + '}', assignment_id.to_s)

      # query parameters
      query_params = {}

      # header parameters
      header_params = {}

      # HTTP header 'Accept' (if needed)
      _header_accept = []
      _header_accept_result = @api_client.select_header_accept(_header_accept) and header_params['Accept'] = _header_accept_result

      # HTTP header 'Content-Type'
      _header_content_type = []
      header_params['Content-Type'] = @api_client.select_header_content_type(_header_content_type)
      header_params[:'consumer'] = consumer
      header_params[:'consumerSecret'] = consumer_secret

      # form parameters
      form_params = {}

      # http body (model)
      post_body = @api_client.object_to_http_body(assignment_data)
      
      auth_names = []
      data, status_code, headers = @api_client.call_api(:POST, local_var_path,
        :header_params => header_params,
        :query_params => query_params,
        :form_params => form_params,
        :body => post_body,
        :auth_names => auth_names,
        :return_type => 'Array<ExternalContentUploadInfo>')
      if @api_client.config.debugging
        @api_client.config.logger.debug "API called: DefaultApi#assignments_context_id_assignment_id_post\nData: #{data.inspect}\nStatus code: #{status_code}\nHeaders: #{headers}"
      end
      return data, status_code, headers
    end

    # 
    # Retrieves scores for the reports
    # @param context_id Context ID
    # @param consumer the consumer
    # @param consumer_secret the consumer secret
    # @param [Hash] opts the optional parameters
    # @option opts [String] :assignment_id ID of assignment
    # @option opts [String] :user_id ID of user
    # @option opts [String] :external_content_id external content id
    # @return [Array<ReportScoreReponse>]
    def reports_scores_context_id_get(context_id, consumer, consumer_secret, opts = {})
      data, status_code, headers = reports_scores_context_id_get_with_http_info(context_id, consumer, consumer_secret, opts)
      return data, status_code, headers
    end

    # 
    # Retrieves scores for the reports
    # @param context_id Context ID
    # @param consumer the consumer
    # @param consumer_secret the consumer secret
    # @param [Hash] opts the optional parameters
    # @option opts [String] :assignment_id ID of assignment
    # @option opts [String] :user_id ID of user
    # @option opts [String] :external_content_id external content id
    # @return [Array<(Array<ReportScoreReponse>, Fixnum, Hash)>] Array<ReportScoreReponse> data, response status code and response headers
    def reports_scores_context_id_get_with_http_info(context_id, consumer, consumer_secret, opts = {})
      if @api_client.config.debugging
        @api_client.config.logger.debug "Calling API: DefaultApi#reports_scores_context_id_get ..."
      end
      
      # verify the required parameter 'context_id' is set
      fail "Missing the required parameter 'context_id' when calling reports_scores_context_id_get" if context_id.nil?
      
      # verify the required parameter 'consumer' is set
      fail "Missing the required parameter 'consumer' when calling reports_scores_context_id_get" if consumer.nil?
      
      # verify the required parameter 'consumer_secret' is set
      fail "Missing the required parameter 'consumer_secret' when calling reports_scores_context_id_get" if consumer_secret.nil?
      
      # resource path
      local_var_path = "/reports/scores/{contextID}".sub('{format}','json').sub('{' + 'contextID' + '}', context_id.to_s)

      # query parameters
      query_params = {}
      query_params[:'assignmentID'] = opts[:'assignment_id'] if opts[:'assignment_id']
      query_params[:'userID'] = opts[:'user_id'] if opts[:'user_id']
      query_params[:'externalContentID'] = opts[:'external_content_id'] if opts[:'external_content_id']

      # header parameters
      header_params = {}

      # HTTP header 'Accept' (if needed)
      _header_accept = []
      _header_accept_result = @api_client.select_header_accept(_header_accept) and header_params['Accept'] = _header_accept_result

      # HTTP header 'Content-Type'
      _header_content_type = []
      header_params['Content-Type'] = @api_client.select_header_content_type(_header_content_type)
      header_params[:'consumer'] = consumer
      header_params[:'consumerSecret'] = consumer_secret

      # form parameters
      form_params = {}

      # http body (model)
      post_body = nil
      
      auth_names = []
      data, status_code, headers = @api_client.call_api(:GET, local_var_path,
        :header_params => header_params,
        :query_params => query_params,
        :form_params => form_params,
        :body => post_body,
        :auth_names => auth_names,
        :return_type => 'Array<ReportScoreReponse>')
      if @api_client.config.debugging
        @api_client.config.logger.debug "API called: DefaultApi#reports_scores_context_id_get\nData: #{data.inspect}\nStatus code: #{status_code}\nHeaders: #{headers}"
      end
      return data, status_code, headers
    end

    # 
    # Request a file submission
    # @param context_id Context ID
    # @param assignment_id ID of assignment
    # @param user_id ID of user
    # @param consumer the consumer
    # @param consumer_secret the consumer secret
    # @param report_meta_data 
    # @param [Hash] opts the optional parameters
    # @return [Array<ExternalContentUploadInfo>]
    def reports_submit_request_context_id_assignment_id_user_id_post(context_id, assignment_id, user_id, consumer, consumer_secret, report_meta_data, opts = {})
      data, status_code, headers = reports_submit_request_context_id_assignment_id_user_id_post_with_http_info(context_id, assignment_id, user_id, consumer, consumer_secret, report_meta_data, opts)
      return data, status_code, headers
    end

    # 
    # Request a file submission
    # @param context_id Context ID
    # @param assignment_id ID of assignment
    # @param user_id ID of user
    # @param consumer the consumer
    # @param consumer_secret the consumer secret
    # @param report_meta_data 
    # @param [Hash] opts the optional parameters
    # @return [Array<(Array<ExternalContentUploadInfo>, Fixnum, Hash)>] Array<ExternalContentUploadInfo> data, response status code and response headers
    def reports_submit_request_context_id_assignment_id_user_id_post_with_http_info(context_id, assignment_id, user_id, consumer, consumer_secret, report_meta_data, opts = {})
      if @api_client.config.debugging
        @api_client.config.logger.debug "Calling API: DefaultApi#reports_submit_request_context_id_assignment_id_user_id_post ..."
      end
      
      # verify the required parameter 'context_id' is set
      fail "Missing the required parameter 'context_id' when calling reports_submit_request_context_id_assignment_id_user_id_post" if context_id.nil?
      
      # verify the required parameter 'assignment_id' is set
      fail "Missing the required parameter 'assignment_id' when calling reports_submit_request_context_id_assignment_id_user_id_post" if assignment_id.nil?
      
      # verify the required parameter 'user_id' is set
      fail "Missing the required parameter 'user_id' when calling reports_submit_request_context_id_assignment_id_user_id_post" if user_id.nil?
      
      # verify the required parameter 'consumer' is set
      fail "Missing the required parameter 'consumer' when calling reports_submit_request_context_id_assignment_id_user_id_post" if consumer.nil?
      
      # verify the required parameter 'consumer_secret' is set
      fail "Missing the required parameter 'consumer_secret' when calling reports_submit_request_context_id_assignment_id_user_id_post" if consumer_secret.nil?
      
      # verify the required parameter 'report_meta_data' is set
      fail "Missing the required parameter 'report_meta_data' when calling reports_submit_request_context_id_assignment_id_user_id_post" if report_meta_data.nil?
      
      # resource path
      local_var_path = "/reports/submit/request/{contextID}/{assignmentID}/{userID}".sub('{format}','json').sub('{' + 'contextID' + '}', context_id.to_s).sub('{' + 'assignmentID' + '}', assignment_id.to_s).sub('{' + 'userID' + '}', user_id.to_s)

      # query parameters
      query_params = {}

      # header parameters
      header_params = {}

      # HTTP header 'Accept' (if needed)
      _header_accept = []
      _header_accept_result = @api_client.select_header_accept(_header_accept) and header_params['Accept'] = _header_accept_result

      # HTTP header 'Content-Type'
      _header_content_type = []
      header_params['Content-Type'] = @api_client.select_header_content_type(_header_content_type)
      header_params[:'consumer'] = consumer
      header_params[:'consumerSecret'] = consumer_secret

      # form parameters
      form_params = {}

      # http body (model)
      post_body = @api_client.object_to_http_body(report_meta_data)
      
      auth_names = []
      data, status_code, headers = @api_client.call_api(:POST, local_var_path,
        :header_params => header_params,
        :query_params => query_params,
        :form_params => form_params,
        :body => post_body,
        :auth_names => auth_names,
        :return_type => 'Array<ExternalContentUploadInfo>')
      if @api_client.config.debugging
        @api_client.config.logger.debug "API called: DefaultApi#reports_submit_request_context_id_assignment_id_user_id_post\nData: #{data.inspect}\nStatus code: #{status_code}\nHeaders: #{headers}"
      end
      return data, status_code, headers
    end

    # 
    # Retrieves URLS for the reports
    # @param context_id Context ID
    # @param assignment_id_filter ID of assignment to filter results on
    # @param consumer the consumer
    # @param consumer_secret the consumer secret
    # @param token_user ID of user who will view the report
    # @param token_user_role role of user who will view the report
    # @param [Hash] opts the optional parameters
    # @option opts [String] :user_id_filter ID of user to filter results on
    # @option opts [String] :external_content_id_filter external content id to filter results on
    # @return [Array<ReportURLLinkReponse>]
    def reports_urls_context_id_get(context_id, assignment_id_filter, consumer, consumer_secret, token_user, token_user_role, opts = {})
      data, status_code, headers = reports_urls_context_id_get_with_http_info(context_id, assignment_id_filter, consumer, consumer_secret, token_user, token_user_role, opts)
      return data, status_code, headers
    end

    # 
    # Retrieves URLS for the reports
    # @param context_id Context ID
    # @param assignment_id_filter ID of assignment to filter results on
    # @param consumer the consumer
    # @param consumer_secret the consumer secret
    # @param token_user ID of user who will view the report
    # @param token_user_role role of user who will view the report
    # @param [Hash] opts the optional parameters
    # @option opts [String] :user_id_filter ID of user to filter results on
    # @option opts [String] :external_content_id_filter external content id to filter results on
    # @return [Array<(Array<ReportURLLinkReponse>, Fixnum, Hash)>] Array<ReportURLLinkReponse> data, response status code and response headers
    def reports_urls_context_id_get_with_http_info(context_id, assignment_id_filter, consumer, consumer_secret, token_user, token_user_role, opts = {})
      if @api_client.config.debugging
        @api_client.config.logger.debug "Calling API: DefaultApi#reports_urls_context_id_get ..."
      end
      
      # verify the required parameter 'context_id' is set
      fail "Missing the required parameter 'context_id' when calling reports_urls_context_id_get" if context_id.nil?
      
      # verify the required parameter 'assignment_id_filter' is set
      fail "Missing the required parameter 'assignment_id_filter' when calling reports_urls_context_id_get" if assignment_id_filter.nil?
      
      # verify the required parameter 'consumer' is set
      fail "Missing the required parameter 'consumer' when calling reports_urls_context_id_get" if consumer.nil?
      
      # verify the required parameter 'consumer_secret' is set
      fail "Missing the required parameter 'consumer_secret' when calling reports_urls_context_id_get" if consumer_secret.nil?
      
      # verify the required parameter 'token_user' is set
      fail "Missing the required parameter 'token_user' when calling reports_urls_context_id_get" if token_user.nil?
      
      # verify the required parameter 'token_user_role' is set
      fail "Missing the required parameter 'token_user_role' when calling reports_urls_context_id_get" if token_user_role.nil?
      
      # resource path
      local_var_path = "/reports/urls/{contextID}".sub('{format}','json').sub('{' + 'contextID' + '}', context_id.to_s)

      # query parameters
      query_params = {}
      query_params[:'assignmentIDFilter'] = assignment_id_filter
      query_params[:'tokenUser'] = token_user
      query_params[:'tokenUserRole'] = token_user_role
      query_params[:'userIDFilter'] = opts[:'user_id_filter'] if opts[:'user_id_filter']
      query_params[:'externalContentIDFilter'] = opts[:'external_content_id_filter'] if opts[:'external_content_id_filter']

      # header parameters
      header_params = {}

      # HTTP header 'Accept' (if needed)
      _header_accept = []
      _header_accept_result = @api_client.select_header_accept(_header_accept) and header_params['Accept'] = _header_accept_result

      # HTTP header 'Content-Type'
      _header_content_type = []
      header_params['Content-Type'] = @api_client.select_header_content_type(_header_content_type)
      header_params[:'consumer'] = consumer
      header_params[:'consumerSecret'] = consumer_secret

      # form parameters
      form_params = {}

      # http body (model)
      post_body = nil
      
      auth_names = []
      data, status_code, headers = @api_client.call_api(:GET, local_var_path,
        :header_params => header_params,
        :query_params => query_params,
        :form_params => form_params,
        :body => post_body,
        :auth_names => auth_names,
        :return_type => 'Array<ReportURLLinkReponse>')
      if @api_client.config.debugging
        @api_client.config.logger.debug "API called: DefaultApi#reports_urls_context_id_get\nData: #{data.inspect}\nStatus code: #{status_code}\nHeaders: #{headers}"
      end
      return data, status_code, headers
    end
  end
end
