#
# Copyright (C) 2018 - present Instructure, Inc.
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

require File.expand_path('../spec_helper', File.dirname(__FILE__))

# We want to force the usage of the fallback scope mapper here, not the generated version
Object.const_set("ApiScopeMapper", ApiScopeMapperLoader.api_scope_mapper_fallback)

describe TokenScopes do

  describe ".named_scopes" do

    let!(:user_info_scope){TokenScopes.named_scopes.find{|s| s[:scope] == TokenScopes::USER_INFO_SCOPE[:scope]}}

    it "includes the resource_name" do
      expect(user_info_scope[:resource_name].to_s).to eq 'oauth2'
    end

    it "includes the resource" do
      expect(user_info_scope[:resource].to_s).to eq 'oauth2'
    end

    it "doesn't include scopes without a name" do
      TokenScopes.instance_variable_set(:@_named_scopes, nil) # we need to make sure that we generate a new list
      allow(ApiScopeMapperLoader.load).to receive(:name_for_resource).and_return(nil)
      expect(TokenScopes.named_scopes).to eq []
      TokenScopes.instance_variable_set(:@_named_scopes, nil) # we don't want to have this version stored
    end

  end

  describe ".all_scopes" do

    it "includes the userinfo scope" do
      expect(TokenScopes.all_scopes).to include TokenScopes::USER_INFO_SCOPE[:scope]
    end

    describe "generated_scopes" do
      let!(:generated_scopes) {TokenScopes.all_scopes.reject {|s| s == TokenScopes::USER_INFO_SCOPE[:scope]}}

      it "formats the scopes with url:http_verb|api_path" do
        generated_scopes.each do |scope|
          expect(/^url:(?:GET|OPTIONS|POST|PUT|PATCH|DELETE)\|\/api\/.+/ =~ scope).not_to be_nil
        end
      end

      it "does not include the optional format part of the route path" do
        generated_scopes.each do |scope|
          expect(/\(\.:format\)/ =~ scope).to be_nil
        end
      end
    end
  end

end
