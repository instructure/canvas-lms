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

class Loaders::DiscussionTopicParticipantLoader < GraphQL::Batch::Loader
  def initialize(discussion_topic_id)
    super()
    @discussion_topic_id = discussion_topic_id
  end

  def perform(user_ids)
    participants = DiscussionTopicParticipant.where(discussion_topic_id: @discussion_topic_id, user_id: user_ids)
    user_ids.each do |user_id|
      fulfill(user_id, participants.find { |participant| user_id == participant.user_id })
    end
  end
end
