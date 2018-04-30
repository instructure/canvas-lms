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


describe TokenScopes do
  describe "SCOPES" do
    it "formats the scopes with url:http_verb|api_path" do
      TokenScopes::SCOPES.sort.each do |scope|
        expect(/^url:(?:GET|OPTIONS|POST|PUT|PATCH|DELETE)\|\/api\/.+/ =~ scope).not_to be_nil
      end
    end

    it "does not include the optional format part of the route path" do
      TokenScopes::SCOPES.each do |scope|
        expect(/\(\.:format\)/ =~ scope).to be_nil
      end
    end

  end

  describe "GROUPED_SCOPES" do
    it "groups the scopes by controller" do
      expect(TokenScopes::GROUPED_DETAILED_SCOPES["demos"]).to include({
                                                                resource: "demos",
                                                                verb: "POST",
                                                                path: "/api/v1/demos",
                                                                scope: "url:POST|/api/v1/demos"
                                                              })

    end

    it "includes the user_info scope" do
      expect(TokenScopes::GROUPED_DETAILED_SCOPES["oauth"]).to include TokenScopes::USER_INFO_SCOPE
    end

  end

end
