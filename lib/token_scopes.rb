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
#
class TokenScopes
  OAUTH2_SCOPE_NAMESPACE = '/auth/'.freeze
  USER_INFO_SCOPE = {
    resource: "oauth",
    verb: "GET",
    scope: "#{OAUTH2_SCOPE_NAMESPACE}userinfo"
  }.freeze

  def self.api_routes
    routes = Rails.application.routes.routes.select { |route| /^\/api\/(v1|sis)/ =~ route.path.spec.to_s }.map do |route|
      path = route.path.spec.to_s.gsub(/\(\.:format\)$/, '')
      {
        resource: route.defaults[:controller],
        verb: route.verb,
        path: path,
        scope: "url:#{route.verb}|#{path}".freeze
      }
    end
    routes.uniq {|route| route[:scope]}
  end
  private_class_method :api_routes

  API_ROUTES = api_routes.freeze
  SCOPES = API_ROUTES.map { |route| route[:scope] }.freeze
  ALL_SCOPES = [USER_INFO_SCOPE[:scope], *SCOPES].freeze
  DETAILED_SCOPES = [USER_INFO_SCOPE, *API_ROUTES].freeze
  GROUPED_DETAILED_SCOPES = DETAILED_SCOPES.group_by {|route| route[:resource]}.freeze
end
