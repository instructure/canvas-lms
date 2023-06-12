# frozen_string_literal: true

#
# Copyright (C) 2018 - present Instructure, Inc.
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

PactConfig::Consumers::ALL.each do |consumer|
  Pact.provider_states_for consumer do
    # Teacher ID: 3 || Name: Teacher1
    # Course ID: 1
    # Discussion ID: 1
    provider_state "a teacher in a course with a discussion" do
      set_up do
        @course = Pact::Canvas.base_state.course
        @teacher = Pact::Canvas.base_state.teachers.first
        @course.discussion_topics.create!(title: "title", message: nil, user: @teacher, discussion_type: "threaded")
      end
    end

    # Teacher ID: 3 || Name: Teacher1
    # Course ID: 1
    # Discussion ID: 1
    provider_state "a teacher in a course with a discussion and a student reply" do
      set_up do
        @course = Pact::Canvas.base_state.course
        @teacher = Pact::Canvas.base_state.teachers.first
        @student = Pact::Canvas.base_state.students.first
        @topic = @course.discussion_topics.create!(title: "title", message: nil, user: @teacher, discussion_type: "threaded")
        @entry = @topic.discussion_entries.create!(user: @student, message: "a comment")
      end
    end

    # Course ID: 3
    # Teacher: "Mobile Teacher", ID 9
    # Student: "Mobile Student", ID 8
    # Discussion topic w/ ID 1: Includes section data
    # Discussion topic w/ ID 2: Locked, delayed, requires an initial post to comment, associated with assignment
    provider_state "mobile course with discussions" do
      set_up do
        student = Pact::Canvas.base_state.mobile_student
        teacher = Pact::Canvas.base_state.mobile_teacher
        course = Pact::Canvas.base_state.mobile_courses[1]

        # Add section to course
        section = course.course_sections.create!(name: "section1", start_at: 2.weeks.ago, end_at: 2.weeks.from_now)
        course.enroll_teacher(teacher, section:, allow_multiple_enrollments: true).accept!
        course.enroll_student(student, section:, allow_multiple_enrollments: true).accept!

        # Create an assignment
        assignment = course.assignments.create!(
          title: "Assignment 1",
          description: "Awesome!",
          due_at: 2.days.from_now,
          points_possible: 10,
          allowed_extensions: ["txt"],
          submission_types: ["online_text_entry"]
        )

        # Create Topic 1: section specific, has an entry with ratings
        topic1 = course.discussion_topics.create!(title: "title",
                                                  message: "message",
                                                  user: student,
                                                  discussion_type: "threaded",
                                                  podcast_enabled: true,
                                                  position: 0)
        topic1.lock_at = 2.days.from_now
        topic1.is_section_specific = true
        topic1.course_sections = [section]
        topic1.save!
        entry = topic1.discussion_entries.create!(user: teacher, message: "A discussion entry.")
        entry.change_rating(1, teacher)
        entry.change_rating(2, student)
        entry.save!

        # Special incantation to cause entries to be promoted to "view" array
        # from "new_entries" array
        view = DiscussionTopic::MaterializedView.where(discussion_topic_id: topic1).first
        view.update_materialized_view(synchronous: true)

        # Create Topic 2: locked, delayed, assignment-specific, requires initial post
        topic2 = course.discussion_topics.create!(title: "title",
                                                  message: "message",
                                                  user: student,
                                                  discussion_type: "threaded",
                                                  require_initial_post: true,
                                                  podcast_enabled: true,
                                                  position: 1)
        topic2.lock_at = 2.days.ago
        topic2.assignment_id = assignment.id
        topic2.delayed_post_at = 2.days.from_now
        topic2.save!
      end
    end
  end
end
