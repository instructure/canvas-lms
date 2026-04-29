# frozen_string_literal: true

#
# Copyright (C) 2025 - present Instructure, Inc.
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

module DocumentationHelpers
  # Finds the actual ruby class for the provided class name
  #
  # @argument module_name The name of a class, with module namespaces separated by two colons.
  #                       E.g. Lti::Registration
  # @return A class
  def self.class_from_string(module_name)
    Module.const_get(module_name)
  end

  def self.topicize(str)
    str.tr(" ", "_").underscore
  end

  def self.build_json_objects_map(resources)
    obj_map = {}
    resource_obj_list = {}
    resources.each do |r, cs|
      cs.each do |controller|
        # Find any methods with a @returns tag that also returns a schema. Get the JSON schema
        # from that class directly.
        referenced_schemas = controller.children.filter_map do |method|
          return_type = method.tags(:returns)&.first&.text
          return_type if return_type&.starts_with?("Schemas::Docs::")
        end.uniq

        # Include any schemas marked as @include in the controller
        referenced_schemas.concat(controller.tags(:include).map(&:text))

        referenced_schemas.each do |referenced_schema|
          schema_class = DocumentationHelpers.class_from_string(referenced_schema)
          name = referenced_schema.sub("Schemas::Docs::", "")
          json = schema_class.schema.to_json

          obj_map[name] = topicize r
          resource_obj_list[r] ||= []
          resource_obj_list[r] << [name, json]
        end

        (controller.tags(:object) + controller.tags(:model)).each do |obj|
          name, json = obj.text.split(/\n+/, 2).map(&:strip)
          obj_map[name] = topicize r
          resource_obj_list[r] ||= []
          resource_obj_list[r] << [name, json]
        end
      end
    end

    [obj_map, resource_obj_list]
  end
end
