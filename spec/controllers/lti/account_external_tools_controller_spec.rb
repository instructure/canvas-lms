# frozen_string_literal: true

#
# Copyright (C) 2019 - present Instructure, Inc.
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
#

require_relative "ims/concerns/advantage_services_shared_context"
require_relative "ims/concerns/lti_services_shared_examples"

describe Lti::AccountExternalToolsController do
  include WebMock::API

  include_context "advantage services context"

  before do
    root_account.lti_context_id = SecureRandom.uuid
    root_account.save
  end

  describe "#show" do
    it_behaves_like "lti services" do
      let(:action) { :show }
      let(:expected_mime_type) { described_class::MIME_TYPE }
      let(:scope_to_remove) { "https://canvas.instructure.com/lti/account_external_tools/scope/show" }
      let(:params_overrides) do
        { account_id: root_account.lti_context_id, external_tool_id: tool.id }
      end
    end
  end

  describe "#index" do
    it_behaves_like "lti services" do
      let(:action) { :index }
      let(:expected_mime_type) { described_class::MIME_TYPE }
      let(:scope_to_remove) { "https://canvas.instructure.com/lti/account_external_tools/scope/list" }
      let(:params_overrides) do
        { account_id: root_account.lti_context_id }
      end
    end

    let(:action) { :index }

    context "when given just an account id" do
      let(:params_overrides) do
        { account_id: root_account.lti_context_id }
      end

      it "returns id, domain, and other fields on account" do
        send_request
        body = response.parsed_body.first
        expect(body).to include(
          "id" => tool.id,
          "domain" => tool.domain,
          "url" => tool.url,
          "consumer_key" => tool.consumer_key,
          "name" => tool.name,
          "description" => tool.description
        )
        expect(body["id"]).to be_a(Integer)
        expect(body["name"]).to be_a(String)
      end
    end

    context "when an invalid account ID is given" do
      let(:params_overrides) do
        { account_id: 991_234 }
      end

      it "returns a 401" do
        send_request
        expect(response).to have_http_status :unauthorized
      end
    end
  end

  describe "#destroy" do
    it_behaves_like "lti services" do
      let(:action) { :destroy }
      let(:expected_mime_type) { described_class::MIME_TYPE }
      let(:scope_to_remove) { "https://canvas.instructure.com/lti/account_external_tools/scope/destroy" }
      let(:params_overrides) do
        { account_id: root_account.lti_context_id, external_tool_id: tool.id }
      end
    end
  end

  describe "#create" do
    let(:params_overrides) do
      { account_id: root_account.lti_context_id, client_id: tool_configuration.developer_key.id }
    end

    it_behaves_like "lti services" do
      let(:action) { :create }
      let(:expected_mime_type) { described_class::MIME_TYPE }
      let(:scope_to_remove) { "https://canvas.instructure.com/lti/account_external_tools/scope/create" }
    end

    context "error handling" do
      let(:action) { :create }

      context "with invalid client id" do
        let(:params_overrides) do
          { account_id: root_account.lti_context_id, client_id: "bad client id" }
        end

        it "return 404" do
          send_request
          expect(response).to have_http_status :not_found
        end
      end

      context "with inactive developer key" do
        let(:developer_key) do
          dev_key = super()
          dev_key.deactivate!
          dev_key
        end

        it "return 401" do
          send_request
          expect(response).to have_http_status :unauthorized
        end
      end

      context "with no account binding" do
        let(:developer_key2) do
          dk = DeveloperKey.create!(account: root_account)
          dk.developer_key_account_bindings.destroy_all
          dk
        end

        let(:params_overrides) do
          { account_id: root_account.lti_context_id, client_id: developer_key2.id }
        end

        it "return 401" do
          send_request
          expect(response).to have_http_status :unauthorized
        end
      end

      context "with duplicate tool" do
        let(:params_overrides) do
          { account_id: root_account.lti_context_id, client_id: tool_configuration.developer_key.id, verify_uniqueness: true }
        end

        it "return 400" do
          send_request
          expect(response).to have_http_status :ok
          send_request
          expect(response).to have_http_status :bad_request
          error_message = response.parsed_body.dig("errors", "tool_currently_installed").first["message"]
          expect(error_message).to eq "The tool is already installed in this context."
        end
      end
    end
  end
end
