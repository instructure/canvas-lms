require 'ims/lti'

module Lti
  class ToolConsumerProfileCreator

    PRODUCT_INSTANCE_JSON = {
      guid: 'replace this',
      product_info: {
        product_version: 'none',
        product_family: {
          code: 'canvas',
          vendor: {
            code: 'https://instructure.com',
            vendor_name: {
              default_value: 'Instructure',
              key: 'vendor.name'
            }.freeze,
            timestamp: '2008-03-27T06:00:00Z'
          }.freeze
        }.freeze,
        product_name: {
          default_value: 'Canvas by Instructure',
          key: 'product.name'
        }.freeze
      }.freeze
    }.freeze


    def initialize(context, tcp_url, tcp_uuid: nil, developer_key: nil)
      @uuid = tcp_uuid || ToolConsumerProfile::DEFAULT_TCP_UUID
      @developer_key = developer_key
      @context = context
      @tcp_url = tcp_url
      @root_account = context.root_account
      uri = URI.parse(@tcp_url)
      @domain = (uri.port == "80" || uri.port == "443") ? uri.host : "#{uri.host}:#{uri.port}"
      @scheme = uri.scheme
    end

    def create
      profile = IMS::LTI::Models::ToolConsumerProfile.new
      profile.id = @tcp_url
      profile.lti_version = IMS::LTI::Models::ToolConsumerProfile::LTI_VERSION_2P0
      profile.product_instance = IMS::LTI::Models::ProductInstance.from_json(PRODUCT_INSTANCE_JSON.deep_dup)
      profile.product_instance.guid = @root_account.lti_guid
      profile.product_instance.service_owner = create_service_owner
      profile.service_offered = services
      profile.capability_offered = capabilities
      profile.guid = (tool_consumer_profile && tool_consumer_profile.uuid) || Lti::ToolConsumerProfile::DEFAULT_TCP_UUID

      # TODO: Extract this
      if @root_account.feature_enabled?(:lti2_rereg)
        profile.capability_offered << IMS::LTI::Models::Messages::ToolProxyReregistrationRequest::MESSAGE_TYPE
      end

      profile
    end

    private

    def capabilities
      caps = Lti::ToolConsumerProfile::DEFAULT_CAPABILITIES.dup
      caps += tool_consumer_profile.capabilities || [] if tool_consumer_profile
      caps
    end

    def tool_consumer_profile
      @_tool_consumer_profile ||= if @developer_key&.tool_consumer_profile&.uuid == @uuid
                                    Lti::ToolConsumerProfile.cached_find_by_developer_key(@developer_key)
                                  end
    end

    def create_service_owner
      service_owner = IMS::LTI::Models::ServiceOwner.new
      service_owner.create_service_owner_name(@root_account.name)
      service_owner.create_description(@root_account.name)
      service_owner
    end

    def services
      endpoint_slug = "#{@scheme}://#{@domain}/"
      authorized_services = Lti::ToolConsumerProfile::DEFAULT_SERVICES
      authorized_services += tool_consumer_profile.services || [] if tool_consumer_profile
      authorized_services.map do |service|
        endpoint = service[:endpoint].respond_to?(:call) ? service[:endpoint].call(@context) : service[:endpoint]
        reg_srv = IMS::LTI::Models::RestService.new
        reg_srv.id = "#{@tcp_url}##{service[:id]}"
        reg_srv.endpoint = "#{endpoint_slug}#{endpoint}"
        reg_srv.type = 'RestService'
        reg_srv.format = service[:format]
        reg_srv.action = service[:action]
        reg_srv
      end
    end

  end
end
