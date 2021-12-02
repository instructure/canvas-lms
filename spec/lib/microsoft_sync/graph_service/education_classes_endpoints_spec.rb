# frozen_string_literal: true

#
# Copyright (C) 2021 - present Instructure, Inc.
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

describe MicrosoftSync::GraphService::EducationClassesEndpoints do
  include_context "microsoft_sync_graph_service_endpoints"

  describe "#list" do
    let(:method_name) { :list }
    let(:method_args) { [] }
    let(:url) { "https://graph.microsoft.com/v1.0/education/classes" }

    it_behaves_like "a paginated list endpoint" do
      it_behaves_like "an endpoint that uses up quota", [1, 0]
    end

    context "when the API says the tenant is not an Education tenant" do
      let(:http_method) { :get }
      let(:status) { 400 }
      let(:response) do
        {
          status: 400,
          body: "{\"error\":{\"code\":\"Request_UnsupportedQuery\",\"message\":\"Property 'extension_fe2174665583431c953114ff7268b7b3_Education_ObjectType' does not exist as a declared property or extension property.\"}"
        }
      end

      it "raises a graceful cancel NotEducationTenant error" do
        klass = MicrosoftSync::Errors::NotEducationTenant
        msg =  /not an Education tenant, so cannot be used/
        expect do
          endpoints.list
        end.to raise_microsoft_sync_graceful_cancel_error(klass, msg)
      end
    end
  end

  describe "#create" do
    subject { endpoints.create(abc: 123) }

    let(:http_method) { :post }
    let(:url) { "https://graph.microsoft.com/v1.0/education/classes" }
    let(:with_params) { { body: { abc: 123 } } }
    let(:response_body) { { "id" => "newclass", "val" => "etc" } }

    it { is_expected.to eq(response_body) }

    it_behaves_like "a graph service endpoint"
    it_behaves_like "an endpoint that uses up quota", [1, 1]
  end
end
