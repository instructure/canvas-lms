module Lti
  class RegistrationRequestService

    def self.retrieve_registration_password(guid)
      Rails.cache.read(req_cache_key(guid))
    end

    def self.create_request(tc_profile_url, return_url)
      registration_request = IMS::LTI::Models::Messages::RegistrationRequest.new(
        lti_version: IMS::LTI::Models::LTIModel::LTI_VERSION_2P0,
        launch_presentation_document_target: IMS::LTI::Models::Messages::Message::LAUNCH_TARGET_IFRAME,
        tc_profile_url: tc_profile_url,
        launch_presentation_return_url: return_url
      )
      reg_key, reg_password = registration_request.generate_key_and_password
      cache_registration(reg_key, reg_password)

      registration_request
    end


    private

    def self.cache_registration(reg_key, reg_password)
      Rails.cache.write(req_cache_key(reg_key), reg_password, :expires_in => 1.hour)
    end

    def self.req_cache_key(reg_key)
      ['lti_registration_request', reg_key].cache_key
    end

  end
end