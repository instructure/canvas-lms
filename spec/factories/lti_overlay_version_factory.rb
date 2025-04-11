# frozen_string_literal: true

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

module Factories
  def lti_overlay_versions_model(params, count)
    params ||= {}
    params[:created_by] ||= user_model
    params[:account] ||= params[:overlay]&.account || account_model
    params[:lti_overlay] ||= params[:lti_overlay] || lti_overlay_model(account: params[:account])

    @lti_overlay_versions = Array.new(count) do
      lti_overlay_version_model(params)
    end
  end

  def lti_overlay_version_model(params)
    params ||= {}
    params[:created_by] ||= user_model
    params[:account] ||= params[:overlay]&.account || account_model
    params[:lti_overlay] ||= params[:lti_overlay] || lti_overlay_model(account: params[:account])

    @lti_overlay_version = Lti::OverlayVersion.create!(params)
  end
end
