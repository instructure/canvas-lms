# frozen_string_literal: true

#
# Canvas is Copyright (C) 2022 - present Instructure, Inc.
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

module TokenScopesHelper::SpecHelper
  module MockCanvasRails
  end

  class MockCanvasRails::Application
    def self.routes
      @_routes ||= ActionDispatch::Routing::RouteSet.new
    end

    # Clear out all routes that we have previously loaded. This
    # allows us to re-load only routes from some plugin, e.g. to
    # isolate one plugin's routes from another plugin's routes when
    # running tests.
    def self.reset_routes
      @_routes = ActionDispatch::Routing::RouteSet.new
    end
  end
end
