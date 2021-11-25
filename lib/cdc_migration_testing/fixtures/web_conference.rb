# frozen_string_literal: true

#
# Copyright (C) 2020 - present Instructure, Inc.
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

module CdcFixtures
  def self.create_web_conference
    # the model-generator may have created a record with id 1 already, but
    # bypassing the sequence, so it'll try to create with id 1 and fail.
    # just let it try twice
    PluginSetting.unique_constraint_retry do
      ps = PluginSetting.where(name: "adobe_connect").first_or_initialize
      ps.settings = {}
      ps.disabled = false
      ps.save! if ps.changed?
    end

    WebConference.new(
      title: "default",
      conference_type: "AdobeConnect",
      context_id: 1,
      context_type: "Course",
      user_id: 1,
      root_account_id: 1
    )
  end
end
