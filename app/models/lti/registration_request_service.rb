require 'ims/lti'

module Lti
  class RegistrationRequestService

    def self.retrieve_registration_password(context, guid)
      Rails.cache.read(req_cache_key(context, guid))
    end

    def self.create_request(context, tc_profile_url, return_url)
      registration_request = IMS::LTI::Models::Messages::RegistrationRequest.new(
        lti_version: IMS::LTI::Models::LTIModel::LTI_VERSION_2P0,
        launch_presentation_document_target: IMS::LTI::Models::Messages::Message::LAUNCH_TARGET_IFRAME,
        tc_profile_url: tc_profile_url,
      )
      reg_key, reg_password = registration_request.generate_key_and_password
      registration_request.launch_presentation_return_url = return_url.call(reg_key)
      cache_registration(context, reg_key, reg_password)

      registration_request
    end

    def self.cache_registration(context, reg_key, reg_password)
      Rails.cache.write(req_cache_key(context, reg_key), reg_password, :expires_in => 1.hour)
    end

    def self.req_cache_key(context, reg_key)
      ['lti_registration_request', context.class.name, context.global_id,  reg_key].cache_key
    end

  end
end