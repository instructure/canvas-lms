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

module Mutations::LtiContentItems; end

# rubocop:disable GraphQL/ExtractInputType
class Mutations::LtiContentItems::LtiContentItemIframe < GraphQL::Schema::InputObject
  argument :height, Int, required: false
  argument :width, Int, required: false
end

class Mutations::LtiContentItems::LtiContentItemIcon < GraphQL::Schema::InputObject
  argument :height, Int, required: false
  argument :url, String, required: true
  argument :width, Int, required: false
end

class Mutations::LtiContentItems::LtiAssetProcessorWindowSettingsInput < GraphQL::Schema::InputObject
  # rubocop:disable GraphQL/ArgumentName
  # camelCase for compatibility with LTI spec, as these are stored
  # directly in Lti::AssetProcessor JSON columns
  argument :height, Int, required: false
  argument :targetName, String, required: false
  argument :width, Int, required: false
  argument :windowFeatures, String, required: false
  # rubocop:enable GraphQL/ArgumentName
end

class Mutations::LtiContentItems::LtiAssetProcessorReportSettings < GraphQL::Schema::InputObject
  argument :custom, Types::StringMapType, required: false
  argument :url, String, required: false
end

# Should match UI's AssetProcessorContentItemDto and
# Lti::AssetProcessor#build_for_assignment
class Mutations::LtiContentItems::LtiAssetProcessorDto < GraphQL::Schema::InputObject
  argument :context_external_tool_id, ID, required: true
  argument :custom, Types::StringMapType, required: false
  argument :icon, Mutations::LtiContentItems::LtiContentItemIcon, required: false
  argument :iframe, Mutations::LtiContentItems::LtiContentItemIframe, required: false
  argument :report, Mutations::LtiContentItems::LtiAssetProcessorReportSettings, required: false
  argument :text, String, required: false
  argument :thumbnail, Mutations::LtiContentItems::LtiContentItemIcon, required: false
  argument :title, String, required: false
  argument :url, String, required: false
  argument :window, Mutations::LtiContentItems::LtiAssetProcessorWindowSettingsInput, required: false
end
# rubocop:enable GraphQL/ExtractInputType
