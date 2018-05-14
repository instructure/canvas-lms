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

require File.expand_path(File.dirname(__FILE__) + '/../sharding_spec_helper')

describe ApiScopeMapperLoader do

  let(:resource) {"users"}

  describe ".load" do

    it "loads the ApiScopeMapper file if present" do
      fallback_class = ApiScopeMapperLoader.api_scope_mapper_fallback
      Object.const_set("ApiScopeMapper", fallback_class)
      allow(File).to receive(:exist?).and_return(true)
      expect(ApiScopeMapperLoader.load).to eq(fallback_class)
    end

    it "loads the api_scope_mapper_fallback if the file is not present" do
      allow(File).to receive(:exist?).and_return(false)
      api_scope_mapper = ApiScopeMapperLoader.load
      expect(api_scope_mapper.name_for_resource(resource)).to eq resource
    end

  end

  describe ".api_scope_mapper_fallback" do

    it "creates a ApiScopeMapper Class with a lookup_resource method" do
      api_scope_mapper_fallback = ApiScopeMapperLoader.api_scope_mapper_fallback
      expect(api_scope_mapper_fallback.lookup_resource(resource, "not_used")).to eq(resource)
    end

    it "creates a ApiScopeMapper Class with a name_for_resource method" do
      api_scope_mapper_fallback = ApiScopeMapperLoader.api_scope_mapper_fallback
      expect(api_scope_mapper_fallback.name_for_resource(resource)).to eq(resource)
    end

  end
end
