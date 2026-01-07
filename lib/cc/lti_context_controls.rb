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
      controls_to_export = Lti::ContextControl.preload(:deployment).where(course: @course).active.select do |context_control|
        export_control?(context_control)
      end

      return nil if controls_to_export.empty?

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
        controls_to_export.each do |context_control|
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
        context_control_node.deployment_migration_id create_key(context_control.deployment)
      end
    end

    def export_control?(control)
      control.deployment.active? && export_object?(control.deployment)
    end
  end
end
