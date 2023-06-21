# frozen_string_literal: true

#
# Copyright (C) 2014 - present Instructure, Inc.
#
# This file is part of Canvas.
#
# Canvas is free software: you can redistribute it and/or modify it under
# the terms of the GNU Affero General Public License as published by the Free
# Software Foundation, version 3 of the License.
#
# Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
# A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
# details.
#
# You should have received a copy of the GNU Affero General Public License along
# with this program. If not, see <http://www.gnu.org/licenses/>.

module Lti
  describe RegistrationRequestService do
    let(:registration_url) { "http://example.com/register" }
    let(:tool_proxy_service_url) { "http://example.com/service" }

    describe "#create" do
      it "creates a RegistrationRequest" do
        enable_cache do
          account = Account.new
          reg_request = described_class.create_request(account, "profile_url", -> { "return_url" }, registration_url, tool_proxy_service_url)
          expect(reg_request.lti_version).to eq "LTI-2p0"
          expect(reg_request.launch_presentation_document_target).to eq "iframe"
          expect(reg_request.tool_proxy_guid).to eq reg_request.reg_key
          expect(reg_request.tc_profile_url).to eq "profile_url"
          expect(reg_request.tool_proxy_url).to eq tool_proxy_service_url
        end
      end

      it "writes the reg password to the cache" do
        account = Account.create!
        enable_cache do
          expect_any_instance_of(::IMS::LTI::Models::Messages::RegistrationRequest).to receive(:generate_key_and_password)
            .and_return(["key", "password"])
          expect(Rails.cache).to receive(:write)
            .with("lti_registration_request/Account/#{account.global_id}/key", { reg_password: "password", registration_url: }, anything)

          described_class.create_request(account, "profile_url", -> { "return_url" }, registration_url, tool_proxy_service_url)
        end
      end

      it "generates the cache key" do
        account = Account.create!
        expect(described_class.req_cache_key(account, "reg_key")).to eq "lti_registration_request/Account/#{account.global_id}/reg_key"
      end
    end
  end
end
