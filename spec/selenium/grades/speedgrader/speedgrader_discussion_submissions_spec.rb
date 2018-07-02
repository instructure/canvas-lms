#
# Copyright (C) 2015 - present Instructure, Inc.
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

require_relative "../../common"
require_relative "../pages/speedgrader_page"

describe "speed grader - discussion submissions" do
  include_context "in-process server selenium tests"

  before(:each) do
    course_with_teacher_logged_in
    outcome_with_rubric
    @assignment = @course.assignments.create(
      name: 'some topic',
      points_possible: 10,
      submission_types: 'discussion_topic',
      description: 'a little bit of content'
    )
    student = user_with_pseudonym(
      name: 'first student',
      active_user: true,
      username: 'student@example.com',
      password: 'qwertyuiop'
    )
    @course.enroll_user(student, "StudentEnrollment", enrollment_state: 'active')
    # create and enroll second student
    student_2 = user_with_pseudonym(
      name: 'second student',
      active_user: true,
      username: 'student2@example.com',
      password: 'qwertyuiop'
    )
    @course.enroll_user(student_2, "StudentEnrollment", enrollment_state: 'active')

    # create discussion entries
    @first_message = 'first student message'
    @second_message = 'second student message'
    @discussion_topic = DiscussionTopic.find_by_assignment_id(@assignment.id)
    entry = @discussion_topic.discussion_entries.
        create!(user: student, message: @first_message)
    entry.update_topic
    entry.context_module_action
    @attachment_thing = attachment_model(context: student_2, filename: 'horse.doc', content_type: 'application/msword')
    entry_2 = @discussion_topic.discussion_entries.
        create!(user: student_2, message: @second_message, attachment: @attachment_thing)
    entry_2.update_topic
    entry_2.context_module_action
  end

  it "displays discussion entries for only one student", priority: "1", test_id: 283745 do
    Speedgrader.visit(@course.id, @assignment.id)

    # check for correct submissions in speed grader iframe
    in_frame 'speedgrader_iframe', '#discussion_view_link' do
      expect(f('#main')).to include_text(@first_message)
      expect(f('#main')).not_to include_text(@second_message)
    end
    f('#next-student-button').click
    wait_for_ajax_requests
    in_frame 'speedgrader_iframe', '#discussion_view_link' do
      expect(f('#main')).not_to include_text(@first_message)
      expect(f('#main')).to include_text(@second_message)
      url = f('#main div.attachment_data a')['href']
      expect(url).to be_include "/files/#{@attachment_thing.id}/download?verifier=#{@attachment_thing.uuid}"
      expect(url).not_to be_include "/courses/#{@course}"
    end
  end

  context "when student names hidden" do
    it "hides the name of student on discussion iframe", priority: "2", test_id: 283746 do
      Speedgrader.visit(@course.id, @assignment.id)

      Speedgrader.click_settings_link
      Speedgrader.click_options_link
      Speedgrader.select_hide_student_names
      expect_new_page_load { fj('.ui-dialog-buttonset .ui-button:visible:last').click }

      # check for correct submissions in speed grader iframe
      in_frame 'speedgrader_iframe', '#discussion_view_link' do
        expect(f('#main')).to include_text("This Student")
      end
    end

    it "hides student names and shows name of grading teacher" \
      "entries on both discussion links", priority: "2", test_id: 283747 do
      teacher = @course.teachers.first
      teacher_message = "why did the taco cross the road?"

      teacher_entry = @discussion_topic.discussion_entries.
        create!(user: teacher, message: teacher_message)
      teacher_entry.update_topic
      teacher_entry.context_module_action

      Speedgrader.visit(@course.id, @assignment.id)

      Speedgrader.click_settings_link
      Speedgrader.click_options_link
      Speedgrader.select_hide_student_names
      expect_new_page_load { fj('.ui-dialog-buttonset .ui-button:visible:last').click }

      # check for correct submissions in speed grader iframe
      in_frame 'speedgrader_iframe', '#discussion_view_link' do
        f('#discussion_view_link').click
        wait_for_ajaximations
        authors = ff('h2.discussion-title span')
        expect(authors).to have_size(3)
        author_text = authors.map(&:text).join("\n")
        expect(author_text).to include("This Student")
        expect(author_text).to include("Discussion Participant")
        expect(author_text).to include(teacher.name)
      end
    end

    it "hides avatars on entries on both discussion links", priority: "2", test_id: 283748 do
      Speedgrader.visit(@course.id, @assignment.id)

      Speedgrader.click_settings_link
      Speedgrader.click_options_link
      Speedgrader.select_hide_student_names
      expect_new_page_load { fj('.ui-dialog-buttonset .ui-button:visible:last').click }

      # check for correct submissions in speed grader iframe
      in_frame 'speedgrader_iframe', '#discussion_view_link' do
        f('#discussion_view_link').click
        expect(f("body")).not_to contain_css('.avatar')
      end

      Speedgrader.visit(@course.id, @assignment.id)

      in_frame 'speedgrader_iframe', '#discussion_view_link' do
        f('.header_title a').click
        expect(f("body")).not_to contain_css('.avatar')
      end
    end
  end
end
