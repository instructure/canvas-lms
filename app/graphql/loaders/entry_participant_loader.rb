# frozen_string_literal: true

#
# Copyright (C) 2021 - present Instructure, Inc.
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

class Loaders::EntryParticipantLoader < GraphQL::Batch::Loader
  def initialize(current_user:)
    @current_user = current_user
  end

  def perform(objects)
    deps = DiscussionEntryParticipant.where(user: @current_user, discussion_entry_id: objects).index_by(&:discussion_entry_id)

    objects.each do |object|
      unless deps[object.id]
        fulfill(object, { read: false, rating: nil, forced_read_state: nil, report_type: nil })
        next
      end

      participant = {}
      participant["rating"] = deps[object.id].rating
      participant["forced_read_state"] = deps[object.id].forced_read_state
      participant["read"] = deps[object.id].workflow_state == 'read'
      participant["report_type"] = deps[object.id].report_type
      fulfill(object, participant)
    end
  end
end
