# frozen_string_literal: true

#
# Copyright (C) 2024 - present Instructure, Inc.
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
module DataFixup::Lti::FixInvalidPlacementConfigurations
  def self.run
    DeveloperKey.nondeleted.where(is_lti_key: true).preload(:tool_configuration).find_each do |dk|
      # Skip keys associated with Dynamic Registration. They don't have a tool config and are already good to go.
      next unless dk.referenced_tool_configuration.present?

      actual_placements = dk.referenced_tool_configuration.configuration["extensions"]
                            &.find { |e| e["platform"] == Lti::ToolConfiguration::CANVAS_EXTENSION_LABEL }
                            &.dig("settings", "placements")
      actual_placements&.each do |placement|
        next unless placement_needs_fixing?(placement)

        placement["message_type"] = opposite_message_type(placement["message_type"])
      end

      dk.referenced_tool_configuration.save! if dk.referenced_tool_configuration.changed?
    end
  end

  def self.placement_needs_fixing?(p)
    return false unless Lti::ResourcePlacement::PLACEMENTS.include?(p["placement"]&.to_sym) && Lti::ResourcePlacement::PLACEMENTS_BY_MESSAGE_TYPE.key?(p["message_type"])
    return false if Lti::ResourcePlacement.supported_message_type?(p["placement"], p["message_type"]) || p["message_type"].blank?

    !Lti::ResourcePlacement.supported_message_type?(p["placement"], p["message_type"])
  end

  def self.opposite_message_type(message_type)
    if message_type == LtiAdvantage::Messages::DeepLinkingRequest::MESSAGE_TYPE
      LtiAdvantage::Messages::ResourceLinkRequest::MESSAGE_TYPE
    else
      LtiAdvantage::Messages::DeepLinkingRequest::MESSAGE_TYPE
    end
  end
end
