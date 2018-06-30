#
# Copyright (C) 2014 - present Instructure, Inc.
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

require_relative './pages/discussions_new_edit_page'

describe "discussions index" do
  include_context "in-process server selenium tests"

  context "as a teacher" do
    discussion1_title = 'Meaning of life'
    discussion2_title = 'Meaning of the universe'

    before :once do
      @teacher = user_with_pseudonym(active_user: true)
      @student = user_with_pseudonym(active_user: true)
      @account = Account.create(name: 'New Account', default_time_zone: 'UTC')
      @course = course_factory(course_name: 'Desks 101',
        account: @account, active_course: true)
      @course.enroll_student(@student, { active_all: true })
      @course.enroll_teacher(@teacher, { active_all: true })

      # Discussion attributes: title, message, delayed_post_at, user
      @discussion1 = @course.discussion_topics.create!(
        title: discussion1_title,
        message: 'Is it really 42?',
        user: @teacher,
        pinned: false
      )
      @discussion2 = @course.discussion_topics.create!(
        title: discussion2_title,
        message: 'Could it be 43?',
        delayed_post_at: 1.day.from_now,
        user: @teacher,
        locked: true,
        pinned: false
      )

      @discussion1.discussion_entries.create!(user: @student, message: "I think I read that somewhere...")
      @discussion1.discussion_entries.create!(user: @student, message: ":eyeroll:")
    end

    def login_and_visit_edit_course(teacher, course)
      user_session(teacher)
      DiscussionNewEdit.visit(course)
    end

    def create_course_and_discussion(opts)
      opts.reverse_merge!({ locked: false, pinned: false })
      course = course_factory(:active_all => true)
      discussion = course.discussion_topics.create!(
        title: opts[:title],
        message: opts[:message],
        user: @teacher,
        locked: opts[:locked],
        pinned: opts[:pinned]
      )
      [course, discussion]
    end

    it 'creating discussion with section gives no error' do
      @course.course_sections.create!(name: "Section 1")
      @course.course_sections.create!(name: "Section 2")
      login_and_visit_edit_course(@teacher, @course)
      DiscussionNewEdit.select_a_section("Section")
      DiscussionNewEdit.add_message("Discussion Body")
      DiscussionNewEdit.add_title("Discussion Title")
      expect_new_page_load {DiscussionNewEdit.submit_discussion_form}
    end

    it 'no sections will give an error' do
      login_and_visit_edit_course(@teacher, @course)
      DiscussionNewEdit.select_a_section("")
      expect(DiscussionNewEdit.section_error).to include("A section is required")
    end
  end
end
