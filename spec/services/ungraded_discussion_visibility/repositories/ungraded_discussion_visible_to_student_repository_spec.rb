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

require_relative "../../../spec_helper"

# See discussion_topic_visibility_service_spec for more (integration) tests that exercise this repository
describe UngradedDiscussionVisibility::Repositories::UngradedDiscussionVisibleToStudentRepository do
  describe "testing things" do
    it "raises error if called with no filter parameters" do
      expect do
        UngradedDiscussionVisibility::Repositories::UngradedDiscussionVisibleToStudentRepository
          .find_discussion_topics_visible_to_everyone(course_id_params: nil, user_id_params: nil, discussion_topic_id_params: nil)
      end.to raise_error(ArgumentError, "UngradedDiscussionsVisibleToStudents must have a limiting where clause of at least one course_id, user_id, or discussion_topic_id (for performance reasons)")
    end
  end
end
