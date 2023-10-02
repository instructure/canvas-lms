# frozen_string_literal: true

#
# Copyright (C) 2023 - present Instructure, Inc.
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

class Mutations::DiscussionBase < Mutations::BaseMutation
  argument :allow_rating, Boolean, required: false
  argument :delayed_post_at, Types::DateTimeType, required: false
  argument :lock_at, Types::DateTimeType, required: false
  argument :locked, Boolean, required: false
  argument :message, String, required: false
  argument :only_graders_can_rate, Boolean, required: false
  argument :published, Boolean, required: false
  argument :require_initial_post, Boolean, required: false
  argument :title, String, required: false
  argument :todo_date, Types::DateTimeType, required: false
  argument :podcast_enabled, Boolean, required: false
  argument :podcast_has_student_posts, Boolean, required: false
  argument :locked, Boolean, required: false
  argument :is_announcement, Boolean, required: false

  field :discussion_topic, Types::DiscussionType, null: true
end
