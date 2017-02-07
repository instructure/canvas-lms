require 'spec_helper'
require_dependency "lti/registration_request_service"

module Lti
  describe RegistrationRequestService do

    describe '#create' do

      it 'creates a RegistrationRequest' do
        enable_cache do
          account = Account.new
          reg_request = described_class.create_request(account, 'profile_url', -> {'return_url'})
          expect(reg_request.lti_version).to eq 'LTI-2p0'
          expect(reg_request.launch_presentation_document_target).to eq 'iframe'
          expect(reg_request.tc_profile_url).to eq 'profile_url'
        end
      end

      it 'writes the reg password to the cache' do
        account = Account.create!
        enable_cache do
          expect_any_instance_of(IMS::LTI::Models::Messages::RegistrationRequest).to receive(:generate_key_and_password).
            and_return(['key', 'password'])
          expect(Rails.cache).to receive(:write).
            with("lti_registration_request/Account/#{account.global_id}/key", 'password', anything)

          described_class.create_request(account, 'profile_url', -> {'return_url'})
        end
      end

      it 'generates the cache key' do
        account = Account.create!
        expect(described_class.req_cache_key(account, 'reg_key')).to eq "lti_registration_request/Account/#{account.global_id}/reg_key"
      end

    end

  end
end
