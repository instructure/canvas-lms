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

describe MicrosoftSync::GraphService::UsersEndpoints do
  include_context "microsoft_sync_graph_service_endpoints"

  describe "#list" do
    let(:http_method) { :get }
    let(:url) { "https://graph.microsoft.com/v1.0/users" }
    let(:method_name) { :list }
    let(:method_args) { [] }

    it_behaves_like "a paginated list endpoint"
  end
end
