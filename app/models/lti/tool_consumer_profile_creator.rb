require 'ims/lti'

module Lti
  class ToolConsumerProfileCreator

    TCP_UUID = "339b6700-e4cb-47c5-a54f-3ee0064921a9".freeze # Hard coded until we start persisting the tcp

    ORIGINALITY_REPORT_SERVICE = 'vnd.Canvas.OriginalityReport'.freeze

    CAPABILITIES = %w(
          basic-lti-launch-request
          Canvas.api.domain
          LtiLink.custom.url
          ToolProxyBinding.custom.url
          ToolProxy.custom.url
          Canvas.placements.accountNavigation
          Canvas.placements.courseNavigation
          Canvas.placements.assignmentSelection
          Canvas.placements.linkSelection
          Canvas.placements.postGrades
          Canvas.placements.similarityDetection
          User.username
          vnd.Canvas.Person.email.sis
          ToolConsumerProfile.url
          Security.splitSecret
        ).concat(CapabilitiesHelper.supported_capabilities).freeze

    RESTRICTED_CAPABILITIES = %W(
      #{ORIGINALITY_REPORT_SERVICE}.url
    ).freeze

    SERVICES = [
      {
        id: 'ToolProxy.collection',
        endpoint: ->(context) { "api/lti/#{context.class.name.downcase}s/#{context.id}/tool_proxy" },
        format: ['application/vnd.ims.lti.v2.toolproxy+json'],
        action: ['POST']
      },
      {
        id: 'vnd.Canvas.authorization',
        endpoint: ->(context) { "api/lti/authorize" },
        format: ['application/json'],
        action: ['POST']
      },
      {
        id: 'ToolProxy.item',
        endpoint: 'api/lti/tool_proxy/{tool_proxy_guid}',
        format: ['application/vnd.ims.lti.v2.toolproxy+json'],
        action: ['GET']
      },
      {
        id: 'ToolProxySettings',
        endpoint: 'api/lti/tool_settings/tool_proxy/{tool_proxy_id}',
        format: ['application/vnd.ims.lti.v2.toolsettings+json', 'application/vnd.ims.lti.v2.toolsettings.simple+json'],
        action: ['GET', 'PUT']
      },
      {
        id: 'ToolProxyBindingSettings',
        endpoint: 'api/lti/tool_settings/bindings/{binding_id}',
        format: ['application/vnd.ims.lti.v2.toolsettings+json', 'application/vnd.ims.lti.v2.toolsettings.simple+json'],
        action: ['GET', 'PUT']
      },
      {
        id: 'LtiLinkSettings',
        endpoint: 'api/lti/tool_settings/links/{tool_proxy_id}',
        format: ['application/vnd.ims.lti.v2.toolsettings+json', 'application/vnd.ims.lti.v2.toolsettings.simple+json'],
        action: ['GET', 'PUT']
      },
    ]

    RESTRICTED_SERVICES = [
      {
        id: ORIGINALITY_REPORT_SERVICE,
        endpoint: 'api/v1/assignments/{assignment_id}/submissions/{submission_id}/originality_report',
        format: ['application/json'],
        action: ['POST', 'PUT', 'GET']
      }
    ].freeze

    def initialize(context, tcp_url)
      @context = context
      @tcp_url = tcp_url
      @root_account = context.root_account
      uri = URI.parse(@tcp_url)
      @domain = (uri.port == "80" || uri.port == "443") ? uri.host : "#{uri.host}:#{uri.port}"
      @scheme = uri.scheme
    end

    def create(developer_credentials = false)
      profile = IMS::LTI::Models::ToolConsumerProfile.new
      profile.id = @tcp_url
      profile.lti_version = IMS::LTI::Models::ToolConsumerProfile::LTI_VERSION_2P1
      profile.product_instance = create_product_instance
      profile.service_offered = services(developer_credentials)
      profile.capability_offered = CAPABILITIES.dup
      profile.capability_offered += RESTRICTED_CAPABILITIES.dup if developer_credentials
      profile.guid = TCP_UUID

      if @root_account.feature_enabled?(:lti2_rereg)
        profile.capability_offered << IMS::LTI::Models::Messages::ToolProxyReregistrationRequest::MESSAGE_TYPE
      end

      profile
    end

    private

    def create_product_instance
      product_instance = IMS::LTI::Models::ProductInstance.new
      product_instance.guid = @root_account.lti_guid
      product_instance.product_info = create_product_info
      product_instance.service_owner = create_service_owner
      product_instance
    end

    def create_product_info
      product_info = IMS::LTI::Models::ProductInfo.new
      product_info.create_product_name('Canvas by Instructure')
      product_info.product_version = 'none'
      product_info.product_family = create_product_family
      product_info
    end

    def create_product_family
      product_family = IMS::LTI::Models::ProductFamily.new
      product_family.code = 'canvas'
      product_family.vendor = create_vendor
      product_family
    end

    def create_vendor
      vendor = IMS::LTI::Models::Vendor.new
      vendor.code = 'https://instructure.com'
      vendor.create_vendor_name('Instructure')
      vendor.timestamp = Time.parse('2008-03-27 00:00:00 -0600')
      vendor
    end

    def create_service_owner
      service_owner = IMS::LTI::Models::ServiceOwner.new
      service_owner.create_service_owner_name(@root_account.name)
      service_owner.create_description(@root_account.name)
      service_owner
    end

    def services(developer_credentials = false)
      endpoint_slug = "#{@scheme}://#{@domain}/"
      authorized_services = SERVICES
      authorized_services += RESTRICTED_SERVICES if developer_credentials
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
