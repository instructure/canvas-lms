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
    resource: :oauth2,
    verb: "GET",
    scope: "#{OAUTH2_SCOPE_NAMESPACE}userinfo"
  }.freeze

  def self.named_scopes
    named_scopes = TokenScopes::DETAILED_SCOPES.each_with_object([]) do |frozen_scope, arr|
      scope = frozen_scope.dup
      api_scope_mapper_class = ApiScopeMapperLoader.load
      scope[:resource] ||= api_scope_mapper_class.lookup_resource(scope[:controller], scope[:action])
      scope[:resource_name] = api_scope_mapper_class.name_for_resource(scope[:resource])
      arr << scope if scope[:resource_name]
      scope
    end
    Canvas::ICU.collate_by(named_scopes) {|s| s[:resource_name]}
  end

  def self.api_routes
    routes = Rails.application.routes.routes.select { |route| /^\/api\/(v1|sis)/ =~ route.path.spec.to_s }.map do |route|
      {
        controller: route.defaults[:controller]&.to_sym,
        action: route.defaults[:action]&.to_sym,
        verb: route.verb,
        path: route.path.spec.to_s.gsub(/\(\.:format\)$/, ''),
        scope: TokenScopesHelper.scope_from_route(route).freeze,
      }
    end
    routes.uniq {|route| route[:scope]}
  end
  private_class_method :api_routes

  API_ROUTES = api_routes.freeze
  SCOPES = API_ROUTES.map { |route| route[:scope] }.freeze
  ALL_SCOPES = [USER_INFO_SCOPE[:scope], *SCOPES].freeze
  DETAILED_SCOPES = [USER_INFO_SCOPE, *API_ROUTES].freeze
end
