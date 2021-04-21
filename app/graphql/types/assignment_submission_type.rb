# frozen_string_literal: true

#
# Copyright (C) 2019 - present Instructure, Inc.
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

module Types
  SUBMISSION_TYPES = %w[
    attendance
    discussion_topic
    external_tool
    media_recording
    none
    not_graded
    on_paper
    online_quiz
    online_text_entry
    online_upload
    online_url
    wiki_page
  ].to_set

  class AssignmentSubmissionType < Types::BaseEnum
    graphql_name "SubmissionType"
    description "Types of submissions an assignment accepts"

    SUBMISSION_TYPES.each do |submission_type|
      value(submission_type)
    end
  end
end