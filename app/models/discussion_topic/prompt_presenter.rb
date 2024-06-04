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

class DiscussionTopic
  class PromptPresenter
    def initialize(topic)
      @topic = topic
    end

    # Example output:
    #
    # DISCUSSION BY instructor_1 WITH TITLE:
    # '''
    # Course Feedback
    # '''
    #
    # DISCUSSION MESSAGE:
    # '''
    # Please provide feedback on the course.
    # '''
    #
    # DISCUSSION ENTRY BY student_1 ON THREAD LEVEL 1:
    # '''
    # I liked the course.
    # '''
    #
    # DISCUSSION ENTRY BY student_2 ON THREAD LEVEL 2:
    # '''
    # I felt the course was too hard.
    # '''
    #
    # DISCUSSION ENTRY BY instructor_1 ON THREAD LEVEL 2.1:
    # '''
    # I'm sorry to hear that. Could you please provide more details?
    # '''
    def content_for_summary
      anonymized_user_ids = {}
      instructor_count = 0
      student_count = 0

      @topic.course.enrollments.active.find_each do |enrollment|
        user_id = enrollment.user_id
        if @topic.course.user_is_instructor?(enrollment.user)
          instructor_count += 1
          anonymized_user_ids[user_id] = "instructor_#{instructor_count}"
        else
          student_count += 1
          anonymized_user_ids[user_id] = "student_#{student_count}"
        end
      end

      discussion_text = "DISCUSSION BY #{anonymized_user_ids[@topic.user_id]} WITH TITLE:\n'''\n#{@topic.title}\n'''\n\n"
      discussion_text += "DISCUSSION MESSAGE:\n'''\n#{@topic.message}\n'''\n\n"

      entries = @topic.discussion_entries.active.to_a
      entries_for_parent_id = entries.group_by(&:parent_id)
      discussion_text += parts_for_summary(nil, entries_for_parent_id, anonymized_user_ids, "", 1)

      discussion_text
    end

    private

    def parts_for_summary(parent_id, entries_for_parent_id, anonymized_user_ids, prefix, level)
      text = ""

      entries_for_parent_id[parent_id]&.each do |entry|
        user_identifier = anonymized_user_ids[entry.user_id]
        current_level = prefix.empty? ? level.to_s : "#{prefix}.#{level}"

        text += "DISCUSSION ENTRY BY #{user_identifier} ON THREAD LEVEL #{current_level}:\n'''\n#{entry.message}\n'''\n\n"

        text += parts_for_summary(entry.id, entries_for_parent_id, anonymized_user_ids, current_level, 1)

        level += 1
      end

      text
    end
  end
end
