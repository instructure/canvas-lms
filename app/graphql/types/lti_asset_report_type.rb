# frozen_string_literal: true

#
# Copyright (C) 2019 - present Instructure, Inc.
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

module Types
  class LtiAssetReportType < ApplicationObjectType
    implements Interfaces::LegacyIDInterface

    field :asset, LtiAssetType, null: true
    def asset
      load_association(:asset)
    end

    field :comment, String, null: true
    field :error_code, String, null: true
    field :indication_alt, String, null: true
    field :indication_color, String, null: true
    field :launch_url_path, String, null: true
    field :priority, Integer, null: false
    field :processing_progress, String, null: false
    def processing_progress
      object.effective_processing_progress
    end

    field :processor_id, ID, method: :lti_asset_processor_id, null: false
    field :report_type, String, null: false
    field :resubmit_available, Boolean, null: false, method: :resubmit_available?
    field :result, String, null: true
    field :result_truncated, String, null: true
    field :title, String, null: true
  end
end
