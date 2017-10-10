#
# Copyright (C) 2016 - present Instructure, Inc.
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

require_relative '../../helpers/differentiated_assignments/da_common'

describe 'Viewing differentiated assignments' do
  include_context 'differentiated assignments'

  context 'as the first student' do
    before(:each) { login_as(users.first_student) }

    context 'on the assignments index page' do
      before(:each) { go_to(urls.assignments_index_page) }

      it 'only shows assigned quizzes, assignments, and discussions', priority: "1", test_id: 618804 do
        expect(list_of_assignments.text).to include(
          # assignments
          assignments.assignment_for_sections_a_and_b.title,

          # discussions
          discussions.discussion_for_sections_a_and_b.title,

          # quizzes
          quizzes.quiz_for_sections_a_and_b.title,
        )

        # hides the rest
        expect(list_of_assignments.text).not_to include(
          assignments.assignment_for_second_and_third_students.title,

          discussions.discussion_for_second_and_third_students.title,

          quizzes.quiz_for_second_and_third_students.title
        )
      end
    end
  end

  context 'as the first observer' do
    before(:each) { login_as(users.first_observer) }

    context 'on the assignments index page' do
      before(:each) { go_to(urls.assignments_index_page) }

      it 'only shows assigned quizzes, assignments, and discussions', priority: "1", test_id: 619042 do
        expect(list_of_assignments.text).to include(
          # assignments
          assignments.assignment_for_sections_a_and_b.title,

          # discussions
          discussions.discussion_for_sections_a_and_b.title,

          # quizzes
          quizzes.quiz_for_sections_a_and_b.title
        )

        # hides the rest
        expect(list_of_assignments.text).not_to include(
          assignments.assignment_for_second_and_third_students.title,
          discussions.discussion_for_second_and_third_students.title,
          quizzes.quiz_for_second_and_third_students.title
        )
      end
    end
  end


  context 'as the second student' do
    before(:each) { login_as(users.second_student) }

    context 'on the assignments index page' do
      before(:each) { go_to(urls.assignments_index_page) }

      it 'only shows assigned quizzes, assignments, and discussions', priority: "1", test_id: 619043 do
        expect(list_of_assignments.text).to include(
          # assignments
          assignments.assignment_for_sections_a_and_b.title,
          assignments.assignment_for_second_and_third_students.title,

          # discussions
          discussions.discussion_for_sections_a_and_b.title,
          discussions.discussion_for_second_and_third_students.title,

          # quizzes
          quizzes.quiz_for_sections_a_and_b.title,
          quizzes.quiz_for_second_and_third_students.title
        )
      end
    end
  end

  context 'as the third student' do
    before(:each) { login_as(users.third_student) }

    context 'on the assignments index page' do
      before(:each) { go_to(urls.assignments_index_page) }

      it 'only shows assigned quizzes, assignments, and discussions', priority: "1", test_id: 619044 do
        expect(list_of_assignments.text).to include(
          # assignments
          assignments.assignment_for_sections_a_and_b.title,
          assignments.assignment_for_second_and_third_students.title,

          # discussions
          discussions.discussion_for_sections_a_and_b.title,
          discussions.discussion_for_second_and_third_students.title,

          # quizzes
          quizzes.quiz_for_sections_a_and_b.title,
          quizzes.quiz_for_second_and_third_students.title
        )
      end
    end
  end

  context 'as the third observer' do
    before(:each) { login_as(users.third_observer) }

    context 'on the assignments index page' do
      before(:each) { go_to(urls.assignments_index_page) }

      it 'only shows assigned quizzes, assignments, and discussions', priority: "1", test_id: 619046 do
        expect(list_of_assignments.text).to include(
          # assignments
          assignments.assignment_for_sections_a_and_b.title,
          assignments.assignment_for_second_and_third_students.title,

          # discussions
          discussions.discussion_for_sections_a_and_b.title,
          discussions.discussion_for_second_and_third_students.title,

          # quizzes
          quizzes.quiz_for_sections_a_and_b.title,
          quizzes.quiz_for_second_and_third_students.title
        )
      end
    end
  end
end
