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

require(File.expand_path(File.join(File.dirname(__FILE__), '..', '..', '..', '..', 'config/environment')))

YARD::Templates::Engine.register_template_path File.dirname(__FILE__) + '/../templates'

YARD::Tags::Library.define_tag("Is an API method", :API)
YARD::Tags::Library.define_tag("API method argument", :argument)
YARD::Tags::Library.define_tag("API response field", :response_field)
YARD::Tags::Library.define_tag("API example response", :example_response)

module YARD::Templates::Helpers
  module BaseHelper

    # Adds additional test that only includes Objects that contain a URL tag
    def run_verifier(list)
      if options[:verifier]
        list.reject! {|item| options[:verifier].call(item).is_a?(FalseClass) }
      end

      reject_module(list)
      reject_method_without_api(list)
      reject_class_without_api(list)

      list
    end

    def reject_module(list)
      list.reject! { |object| [:root, :module].include?(object.type) }
    end

    def reject_method_without_api(list)
      list.reject!  { |object| [:method].include?(object.type) and object.tags("API").empty? }
    end

    def reject_class_without_api(list)
      list.reject!  { |object| [:class].include?(object.type) and object.tags("API").empty? }
    end

  end
end

