#
# Copyright (C) 2011 Instructure, Inc.
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

# wrapping your API routes in an ApiRouteSet adds structure to the routes file
# and lets us auto-discover the route for a given API method in the docs.
class ApiRouteSet
  cattr_accessor :apis
  self.apis = []

  def initialize(mapper, prefix)
    @prefix = prefix
    mapper.with_options(:path_prefix => @prefix) do |api|
      yield api
    end
    ApiRouteSet.apis << self
  end
  attr_reader :prefix

  def self.routes_for(prefix)
    builder = ActionController::Routing::RouteBuilder.new
    segments = builder.segments_for_route_path(prefix)
    ActionController::Routing::Routes.routes.select { |r| segments_match(r.segments[0,segments.size], segments) }
  end

  def self.segments_match(seg1, seg2)
    seg1.size == seg2.size && seg1.each_with_index { |s,i| return false unless s.respond_to?(:value) && s.value == seg2[i].value }
  end

  def api_methods_for_controller_and_action(controller, action)
    self.class.routes_for(prefix).find_all { |r| r.matches_controller_and_action?(controller, action) }
  end
end
