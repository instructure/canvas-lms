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
#

module Api::V1::Lti::OverlayVersion
  include Api::V1::Json
  include Api::V1::User

  JSON_ATTRS = %w[
    id account_id root_account_id lti_overlay_id created_at updated_at diff caused_by_reset
  ].freeze

  def lti_overlay_version_json(overlay_version, user, session, context)
    api_json(overlay_version, user, session, only: JSON_ATTRS).tap do |json|
      if overlay_version.created_by.present?
        json["created_by"] = if Account.site_admin.grants_right?(overlay_version.created_by, session, :read)
                               "Instructure"
                             else
                               user_json(overlay_version.created_by, user, session, [], context, nil, ["pseudonym"])
                             end
      end
    end
  end

  def lti_overlay_versions_json(overlay_versions, user, session, context)
    overlay_versions.map { |ov| lti_overlay_version_json(ov, user, session, context) }
  end
end
