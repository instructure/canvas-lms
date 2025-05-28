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

module CC
  # Exports all Lti::ContextControls that are in the course being exported.
  module LtiContextControls
    def add_lti_context_controls(document = nil)
      return nil unless Lti::ContextControl.active.where(course: @course).exists?

      if document
        controls_file = nil
        rel_path = nil
      else
        controls_file = File.new(File.join(@canvas_resource_dir, CCHelper::LTI_CONTEXT_CONTROLS), "w")
        rel_path = File.join(CCHelper::COURSE_SETTINGS_DIR, CCHelper::LTI_CONTEXT_CONTROLS)
        document = Builder::XmlMarkup.new(target: controls_file, indent: 2)
      end

      document.instruct!
      document.lti_context_controls(
        "xmlns" => CCHelper::CANVAS_NAMESPACE,
        "xmlns:xsi" => "http://www.w3.org/2001/XMLSchema-instance",
        "xsi:schemaLocation" => "#{CCHelper::CANVAS_NAMESPACE} #{CCHelper::XSD_URI}"
      ) do |controls_node|
        Lti::ContextControl.preload(:deployment).where(course: @course).active.find_each do |context_control|
          next unless export_control?(context_control)

          add_lti_context_control(context_control, controls_node)
        end
      end

      controls_file&.close

      rel_path
    end

    private

    def add_lti_context_control(context_control, node)
      node.lti_context_control(
        identifier: create_key(context_control)
      ) do |context_control_node|
        context_control_node.available context_control.available
        # The deployment URL will be used later to associate a copied context control
        # with the appropriate deployment in the destination course. Note that this
        # URL for 1.3 tools is the same as the target_link_uri on the tool configuration.
        context_control_node.deployment_url context_control.deployment.url
        # Let's us know if the control's tool is being copied as well, so we can handle
        # selective import correctly.
        if export_object?(context_control.deployment)
          context_control_node.deployment_migration_id create_key(context_control.deployment)
        else
          # This only makes sense to include if the deployment is not being copied, as if it is being
          # copied, we know the preferred_deployment_id can't be used as it's a course level tool.
          context_control_node.preferred_deployment_id context_control.deployment.global_id
        end
      end
    end

    def export_control?(control)
      control.deployment.active? &&
        (export_object?(control.deployment) ||
          (!tool_deployed_in_course?(control.deployment) && export_symbol?(:all_course_settings)))
    end

    def tool_deployed_in_course?(tool)
      # Avoid loading context into memory unnecessarily
      tool.context_id == @course.id && tool.context_type == "Course"
    end
  end
end
