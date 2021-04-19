# frozen_string_literal: true

#
# Copyright (C) 2011 - present Instructure, Inc.
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
module JobLiveEventsContext
  def live_events_context
    ctx = {
      job_id: global_id,
      job_tag:tag,
      producer: 'canvas',
      root_account_id: Account.default.global_id,
      root_account_uuid: Account.default.uuid,
      root_account_lti_guid: Account.default.lti_guid,
    }
    StringifyIds.recursively_stringify_ids(ctx)
  end
end
