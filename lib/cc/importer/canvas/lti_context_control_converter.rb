# frozen_string_literal: true

#
# Copyright (C) 2021 - present Instructure, Inc.
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
module CC::Importer::Canvas
  module LtiContextControlConverter
    include CC::Importer

    def convert_lti_context_controls(document)
      return [] unless document

      controls = []
      controls_node = document.at_css("lti_context_controls")

      controls_node.children.each do |control|
        case control.name
        when "lti_context_control"
          controls << convert_lti_context_control(control)
        else
          next
        end
      end

      controls.compact
    end

    def convert_lti_context_control(control_node)
      # We don't want to convert controls that don't have both of these properties, as we
      # really don't want to assume anything about the availability of the control.
      return if get_bool_val(control_node, "available").nil? || get_node_val(control_node, "deployment_url").blank?

      control = {}.with_indifferent_access

      control[:deployment_url] = get_node_val(control_node, "deployment_url")
      control[:available] = get_bool_val(control_node, "available")
      control[:deployment_migration_id] = get_node_val(control_node, "deployment_migration_id")
      control[:preferred_deployment_id] = get_int_val(control_node, "preferred_deployment_id")

      control
    end
  end
end
