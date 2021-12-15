# frozen_string_literal: true

#
# Copyright (C) 2011 - present Instructure, Inc.
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

describe ApiScopeMapperFallback do
  let(:resource) { "users" }

  it "loads the ApiScopeMapper file if present" do
    if Rails.root.join("lib/api_scope_mapper.rb").file?
      expect(ApiScopeMapper.name).not_to eq(ApiScopeMapperFallback.name)
    else
      expect(ApiScopeMapper.name).to eq(ApiScopeMapperFallback.name)
    end
  end

  it "creates a ApiScopeMapper Class with a lookup_resource method" do
    expect(ApiScopeMapperFallback.lookup_resource(resource, "not_used")).to eq(resource)
  end

  it "creates a ApiScopeMapper Class with a name_for_resource method" do
    expect(ApiScopeMapperFallback.name_for_resource(resource)).to eq(resource)
  end
end
