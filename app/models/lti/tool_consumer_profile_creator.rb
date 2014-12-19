module Lti
  class ToolConsumerProfileCreator

    def initialize(context, tcp_url)
      @context = context
      @tcp_url = tcp_url
      @root_account = context.root_account
      uri = URI.parse(@tcp_url)
      @domain = uri.host
      @scheme = uri.scheme
    end

    def create
      profile = IMS::LTI::Models::ToolConsumerProfile.new
      profile.id = @tcp_url
      profile.lti_version = IMS::LTI::Models::ToolConsumerProfile::LTI_VERSION_2P0
      profile.product_instance = create_product_instance
      profile.service_offered  = [ create_tp_registration_service, create_tp_item_service, create_tp_settings_service, create_binding_settings_service, create_link_settings_service ]
      profile.capability_offered = capabilities

      profile
    end

    private

    def create_product_instance
      product_instance = IMS::LTI::Models::ProductInstance.new
      product_instance.guid = @root_account.lti_guid
      product_instance.product_info = create_product_info
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

    def create_tp_registration_service
      reg_srv = IMS::LTI::Models::RestService.new
      reg_srv.id = "#{@tcp_url}#ToolProxy.collection"
      reg_srv.endpoint = "#{@scheme}://#{@domain}/api/lti/#{@context.class.name.downcase}s/#{@context.id}/tool_proxy"
      reg_srv.type = 'RestService'
      reg_srv.format = ['application/vnd.ims.lti.v2.toolproxy+json']
      reg_srv.action = 'POST'
      reg_srv
    end

    def create_tp_item_service
      reg_srv = IMS::LTI::Models::RestService.new
      reg_srv.id = "#{@tcp_url}#ToolProxy.item"
      reg_srv.endpoint = "#{@scheme}://#{@domain}/api/lti/tool_settings/tool_proxy/{tool_proxy_id}"
      reg_srv.type = 'RestService'
      reg_srv.format = ["application/vnd.ims.lti.v2.toolproxy+json"]
      reg_srv.action = ['GET']
      reg_srv
    end

    def create_tp_settings_service
      reg_srv = IMS::LTI::Models::RestService.new
      reg_srv.id = "#{@tcp_url}#ToolProxySettings"
      reg_srv.endpoint = "#{@scheme}://#{@domain}/api/lti/tool_settings/tool_proxy/{tool_proxy_id}"
      reg_srv.type = 'RestService'
      reg_srv.format = ['application/vnd.ims.lti.v2.toolsettings+json', 'application/vnd.ims.lti.v2.toolsettings.simple+json']
      reg_srv.action = ['GET', 'PUT']
      reg_srv
    end

    def create_binding_settings_service
      reg_srv = IMS::LTI::Models::RestService.new
      reg_srv.id = "#{@tcp_url}#ToolProxyBindingSettings"
      reg_srv.endpoint = "#{@scheme}://#{@domain}/api/lti/tool_settings/bindings/{binding_id}"
      reg_srv.type = 'RestService'
      reg_srv.format = ['application/vnd.ims.lti.v2.toolsettings+json', 'application/vnd.ims.lti.v2.toolsettings.simple+json']
      reg_srv.action = ['GET', 'PUT']
      reg_srv
    end

    def create_link_settings_service
      reg_srv = IMS::LTI::Models::RestService.new
      reg_srv.id = "#{@tcp_url}#LtiLinkSettings"
      reg_srv.endpoint = "#{@scheme}://#{@domain}/api/lti/tool_settings/links/{tool_proxy_id}"
      reg_srv.type = 'RestService'
      reg_srv.format = ['application/vnd.ims.lti.v2.toolsettings+json', 'application/vnd.ims.lti.v2.toolsettings.simple+json']
      reg_srv.action = ['GET', 'PUT']
      reg_srv
    end

    def capabilities
      %w( basic-lti-launch-request
          Canvas.api.domain
          LtiLink.custom.url
          ToolProxyBinding.custom.url
          ToolProxy.custom.url
          Canvas.placements.account-nav
          Canvas.placements.course-nav
        )
    end

  end
end