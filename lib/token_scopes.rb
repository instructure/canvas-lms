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
    return @_named_scopes if @_named_scopes
    named_scopes = detailed_scopes.each_with_object([]) do |frozen_scope, arr|
      scope = frozen_scope.dup
      api_scope_mapper_class = ApiScopeMapperLoader.load
      scope[:resource] ||= api_scope_mapper_class.lookup_resource(scope[:controller], scope[:action])
      scope[:resource_name] = api_scope_mapper_class.name_for_resource(scope[:resource])
      arr << scope if scope[:resource_name]
      scope
    end
    @_named_scopes = Canvas::ICU.collate_by(named_scopes) {|s| s[:resource_name]}.freeze
  end

  def self.all_scopes
    @_all_scopes ||= [USER_INFO_SCOPE[:scope], *api_routes.map {|route| route[:scope]}].freeze
  end

  def self.detailed_scopes
    @_detailed_scopes ||= [USER_INFO_SCOPE, *api_routes].freeze
  end
  private_class_method :detailed_scopes

  def self.api_routes
    return @_api_routes if @_api_routes
    routes = Rails.application.routes.routes.select {|route| /^\/api\/(v1|sis)/ =~ route.path.spec.to_s}.map do |route|
      {
        controller: route.defaults[:controller]&.to_sym,
        action: route.defaults[:action]&.to_sym,
        verb: route.verb,
        path: route.path.spec.to_s.gsub(/\(\.:format\)$/, ''),
        scope: TokenScopesHelper.scope_from_route(route).freeze,
      }
    end
    @_api_routes = routes.uniq {|route| route[:scope]}.freeze
  end
  private_class_method :api_routes

end
