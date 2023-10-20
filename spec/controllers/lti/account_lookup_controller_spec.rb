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

describe Lti::AccountLookupController do
  include WebMock::API

  include_context "advantage services context"

  describe "#show" do
    it_behaves_like "lti services" do
      let(:action) { :show }
      let(:expected_mime_type) { described_class::MIME_TYPE }
      let(:scope_to_remove) { "https://canvas.instructure.com/lti/account_lookup/scope/show" }
      let(:params_overrides) do
        { account_id: root_account.id }
      end
    end

    let(:action) { :show }

    context "when given just an account it" do
      let(:params_overrides) do
        { account_id: root_account.id }
      end

      it "returns id, uuid, and other fields on account" do
        send_request
        acct = root_account
        body = response.parsed_body
        expect(body).to include(
          "id" => acct.id,
          "uuid" => acct.uuid,
          "name" => acct.name,
          "workflow_state" => acct.workflow_state,
          "parent_account_id" => acct.parent_account_id,
          "root_account_id" => nil
        )
        expect(body["id"]).to be_a(Integer)
        expect(body["uuid"]).to be_a(String)
      end
    end

    context "when an invalid account ID is given" do
      let(:params_overrides) do
        { account_id: 991_234 }
      end

      it "returns a 404" do
        send_request
        expect(response).to have_http_status(:not_found)
      end
    end

    context "when an ID on an invalid shard given" do
      let(:params_overrides) do
        { account_id: 1_987_650_000_000_000_000 + root_account.local_id }
      end

      it "returns a 404" do
        expect(Shard.find_by(id: 198_765)).to be_nil
        send_request
        expect(response).to have_http_status(:not_found)
      end
    end

    context "when given a global ID" do
      let(:params_overrides) do
        { account_id: root_account.global_id }
      end

      it "returns id, uuid, and other fields on account" do
        send_request
        acct = root_account
        body = response.parsed_body
        expect(body).to include(
          "id" => acct.id,
          "uuid" => acct.uuid,
          "name" => acct.name,
          "workflow_state" => acct.workflow_state,
          "parent_account_id" => acct.parent_account_id,
          "root_account_id" => nil
        )
        expect(body["id"]).to be_a(Integer)
      end
    end
  end
end
