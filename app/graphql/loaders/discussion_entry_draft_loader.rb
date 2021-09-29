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

class Loaders::DiscussionEntryDraftLoader < GraphQL::Batch::Loader
  def initialize(current_user:)
    @current_user = current_user
    super()
  end

  def perform(all_objects)
    Shard.partition_by_shard(all_objects) do |objects|
      scope = @current_user.discussion_entry_drafts.where(discussion_topic_id: objects)
      drafts = scope.group_by(&:discussion_topic_id)
      objects.each do |object|
        topic_drafts = drafts[object.id]
        topic_drafts ||= DiscussionEntryDraft.none
        fulfill(object, topic_drafts)
      end
    end
  end
end
