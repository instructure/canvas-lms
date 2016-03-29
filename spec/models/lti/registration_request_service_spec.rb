require 'spec_helper'

module Lti
  describe RegistrationRequestService do

    describe '#create' do

      it 'creates a RegistrationRequest' do
        enable_cache do
          account = Account.new
          reg_request = described_class.create_request(account, 'profile_url', ->(_) {'return_url'})
          expect(reg_request.lti_version).to eq 'LTI-2p0'
          expect(reg_request.launch_presentation_document_target).to eq 'iframe'
          expect(reg_request.tc_profile_url).to eq 'profile_url'
        end
      end

      it 'writes the reg password to the cache' do
        account = Account.create!
        enable_cache do
          IMS::LTI::Models::Messages::RegistrationRequest.any_instance.expects(:generate_key_and_password).
            returns(['key', 'password'])
          Rails.cache.expects(:write).with("lti_registration_request/Account/#{account.global_id}/key", 'password', anything)

          described_class.create_request(account, 'profile_url', ->(_) {'return_url'})
        end
      end

      it 'generates the cache key' do
        account = Account.create!
        expect(described_class.req_cache_key(account, 'reg_key')).to eq "lti_registration_request/Account/#{account.global_id}/reg_key"
      end

    end

  end
end