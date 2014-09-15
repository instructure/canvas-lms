module Lti
  class ToolConsumerProfileCreator

    def initialize(account, tcp_url, tp_registration_url)
      @root_account = account.root_account
      @tcp_url = tcp_url
      @tp_registration_url = tp_registration_url
    end

    def create
      profile = IMS::LTI::Models::ToolConsumerProfile.new
      profile.id = @tcp_url
      profile.lti_version = IMS::LTI::Models::ToolConsumerProfile::LTI_VERSION_2P0
      profile.product_instance = create_product_instance
      profile.service_offered  = [create_tp_registration_service]
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
      reg_srv.endpoint = @tp_registration_url
      reg_srv.type = 'RestService'
      reg_srv.format = ['application/vnd.ims.lti.v2.toolproxy+json']
      reg_srv.action = 'POST'
      reg_srv
    end

    def capabilities
      ['basic-lti-launch-request']
    end

  end
end