require 'spec_helper'

module Lti
  describe RegistrationRequestService do

    describe '#create' do

      it 'creates a RegistrationRequest' do
        enable_cache do
          reg_request = described_class.create_request('profile_url', 'return_url')
          reg_request.lti_version.should == 'LTI-2p0'
          reg_request.launch_presentation_document_target.should == 'iframe'
          reg_request.tc_profile_url.should == 'profile_url'
        end
      end

      it 'writes the reg password to the cache' do
        enable_cache do
          IMS::LTI::Models::Messages::RegistrationRequest.any_instance.expects(:generate_key_and_password).
            returns(['key', 'password'])
          Rails.cache.expects(:write).with('lti_registration_request/key', 'password', anything)

          described_class.create_request('profile_url', 'return_url')
        end
      end

      it 'generates the cache key' do
        described_class.req_cache_key('reg_key').should == 'lti_registration_request/reg_key'
      end

    end

  end
end