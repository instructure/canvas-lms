# frozen_string_literal: true

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

require "bundler"
Bundler.setup
require "action_controller"

# load the routes
if CanvasRails::Application.routes_reloader.paths.empty?
  require_relative "../../lib/api_route_set"
  require_relative "../../lib/token_scopes_helper"
  # we need this for a route constraint
  require_relative "../../lib/lti/re_reg_constraint"

  routes_files = CanvasRails::Application.paths["config/routes.rb"].existent +
                 CanvasRails::Application.railties.map do |railtie|
                   next unless railtie.is_a?(Rails::Engine)

                   railtie.paths["config/routes.rb"].existent
                 end.flatten

  CanvasRails::Application.routes.disable_clear_and_finalize = true
  CanvasRails::Application.routes.clear!

  routes_files.compact.each { |path| load(path) }
else
  # we're probably running in spring, and Rails has already loaded them; make
  # sure they're up to date
  CanvasRails::Application.routes_reloader.reload!
end

# Extend YARD to generate our API documentation
YARD::Tags::Library.define_tag("Is an API method", :API)
YARD::Tags::Library.define_tag("API method argument", :argument)
# Expected Format:
# @deprecated_argument argument_name NOTICE YYYY-MM-DD EFFECTIVE YYYY-MM-DD
#   A description of the deprecation. (required)
YARD::Tags::Library.define_tag("API method argument is deprecated", :deprecated_argument)
# Expected Format:
# @deprecated_method NOTICE YYYY-MM-DD EFFECTIVE YYYY-MM-DD
#   Use {api:FooController#some_action Foo#some_action} instead. A description of the deprecated method. (required)
YARD::Tags::Library.define_tag("API method is deprecated", :deprecated_method)
YARD::Tags::Library.define_tag("API response field", :request_field)
YARD::Tags::Library.define_tag("API response field", :response_field)
# Expected Format:
# @deprecated_response_field response_field NOTICE YYYY-MM-DD EFFECTIVE YYYY-MM-DD
#   A description of the deprecation. (required)
YARD::Tags::Library.define_tag("API response field is deprecated", :deprecated_response_field)
YARD::Tags::Library.define_tag("API example request", :example_request)
YARD::Tags::Library.define_tag("API example response", :example_response)
YARD::Tags::Library.define_tag("API subtopic", :subtopic)
YARD::Tags::Library.define_tag("API resource is Beta", :beta)
YARD::Tags::Library.define_tag("API Object Definition", :object)
YARD::Tags::Library.define_tag("API Return Type", :returns)
YARD::Tags::Library.define_tag("API resource is internal", :internal)

module YARD::Templates::Helpers
  module BaseHelper
    def run_verifier(list)
      list.select { |o| relevant_object?(o) }
    end

    def relevant_object?(object)
      case object.type
      when :root, :module, :constant
        false
      when :method, :class
        !object.tags("API").empty? && (ENV["INCLUDE_INTERNAL"] || object.tags("internal").empty?)
      else
        if object.parent.nil?
          false
        else
          relevant_object?(object.parent)
        end
      end
    end
  end
end
