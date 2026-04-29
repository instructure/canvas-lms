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

module Lti
  module AssetProcessorNotifierHelper
    module_function

    def asset_hash(submission, asset, asset_processor)
      hash = {
        asset_id: asset.uuid,
        sha256_checksum: asset.sha256_checksum,
        size: asset.content_size,
        url: asset_url(asset_processor, asset),
        content_type: asset.content_type
      }
      title = asset.attachment&.display_name
      hash[:title] = title unless title.nil?
      if asset.text_entry?
        hash[:timestamp] = submission.submitted_at.iso8601
      elsif asset.discussion_entry?
        hash[:timestamp] = asset.discussion_entry_version.created_at.iso8601
      else
        hash[:timestamp] = asset.attachment.modified_at.iso8601
        hash[:filename] = asset.attachment.display_name
      end
      hash
    end

    def asset_url(asset_processor, asset)
      Rails.application.routes.url_helpers.lti_asset_processor_asset_show_url(
        asset_processor_id: asset_processor.id,
        asset_id: asset.uuid,
        host: asset_processor.root_account.environment_specific_domain
      )
    end

    def asset_report_service_url(asset_processor)
      Rails.application.routes.url_helpers.lti_asset_processor_create_report_url(
        host: asset_processor.root_account.environment_specific_domain,
        asset_processor_id: asset_processor.id
      )
    end
  end
end
