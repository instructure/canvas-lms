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
  def self.generate_scopes
    api_routes = Rails.application.routes.routes.select { |route| /^\/api\/v1/ =~ route.path.spec.to_s }
    api_route_hashes = api_routes.map { |route| { verb: route.verb, path: route.path.spec.to_s.gsub(/\(\.:format\)$/, '') } }
    api_route_hashes += [
      { verb: 'GET', path: '/api/sis/accounts/:account_id/assignments' }.freeze,
      { verb: 'GET', path: '/api/sis/courses/:course_id/assignments' }.freeze,
      { verb: 'PUT', path: '/api/sis/courses/:course_id/disable_post_to_sis' }.freeze,
      { verb: 'GET', path: '/api/lti/courses/:course_id/membership_service' }.freeze,
      { verb: 'GET', path: '/api/lti/groups/:group_id/membership_service' }.freeze,
    ]
    api_route_hashes.uniq.map { |route| "url:#{route[:verb]}|#{route[:path]}".freeze }
  end

  SCOPES = self.generate_scopes.freeze
end
