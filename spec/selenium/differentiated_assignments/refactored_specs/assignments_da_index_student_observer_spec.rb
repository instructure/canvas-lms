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
          assignments.assignment_for_everyone.title,
          assignments.assignment_for_section_a.title,
          assignments.assignment_for_sections_a_and_b.title,
          assignments.assignment_for_first_student.title,

          # discussions
          discussions.discussion_for_everyone.title,
          discussions.discussion_for_section_a.title,
          discussions.discussion_for_sections_a_and_b.title,
          discussions.discussion_for_first_student.title,

          # quizzes
          quizzes.quiz_for_everyone.title,
          quizzes.quiz_for_section_a.title,
          quizzes.quiz_for_sections_a_and_b.title,
          quizzes.quiz_for_first_student.title
        )

        # hides the rest
        expect(list_of_assignments.text).to_not include(
          assignments.assignment_for_section_b.title,
          assignments.assignment_for_section_c.title,
          assignments.assignment_for_second_and_third_students.title,

          discussions.discussion_for_section_b.title,
          discussions.discussion_for_section_c.title,
          discussions.discussion_for_second_and_third_students.title,

          quizzes.quiz_for_section_b.title,
          quizzes.quiz_for_section_c.title,
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
          assignments.assignment_for_everyone.title,
          assignments.assignment_for_section_a.title,
          assignments.assignment_for_sections_a_and_b.title,
          assignments.assignment_for_first_student.title,

          # discussions
          discussions.discussion_for_everyone.title,
          discussions.discussion_for_section_a.title,
          discussions.discussion_for_sections_a_and_b.title,
          discussions.discussion_for_first_student.title,

          # quizzes
          quizzes.quiz_for_everyone.title,
          quizzes.quiz_for_section_a.title,
          quizzes.quiz_for_sections_a_and_b.title,
          quizzes.quiz_for_first_student.title
        )

        # hides the rest
        expect(list_of_assignments.text).to_not include(
          assignments.assignment_for_section_b.title,
          assignments.assignment_for_section_c.title,
          assignments.assignment_for_second_and_third_students.title,

          discussions.discussion_for_section_b.title,
          discussions.discussion_for_section_c.title,
          discussions.discussion_for_second_and_third_students.title,

          quizzes.quiz_for_section_b.title,
          quizzes.quiz_for_section_c.title,
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
          assignments.assignment_for_everyone.title,
          assignments.assignment_for_section_b.title,
          assignments.assignment_for_sections_a_and_b.title,
          assignments.assignment_for_second_and_third_students.title,

          # discussions
          discussions.discussion_for_everyone.title,
          discussions.discussion_for_section_b.title,
          discussions.discussion_for_sections_a_and_b.title,
          discussions.discussion_for_second_and_third_students.title,

          # quizzes
          quizzes.quiz_for_everyone.title,
          quizzes.quiz_for_section_b.title,
          quizzes.quiz_for_sections_a_and_b.title,
          quizzes.quiz_for_second_and_third_students.title
        )

        # hides the rest
        expect(list_of_assignments.text).to_not include(
          assignments.assignment_for_section_a.title,
          assignments.assignment_for_section_c.title,
          assignments.assignment_for_first_student.title,

          discussions.discussion_for_section_a.title,
          discussions.discussion_for_section_c.title,
          discussions.discussion_for_first_student.title,

          quizzes.quiz_for_section_a.title,
          quizzes.quiz_for_section_c.title,
          quizzes.quiz_for_first_student.title
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
          assignments.assignment_for_everyone.title,
          assignments.assignment_for_section_a.title,
          assignments.assignment_for_section_b.title,
          assignments.assignment_for_sections_a_and_b.title,
          assignments.assignment_for_second_and_third_students.title,

          # discussions
          discussions.discussion_for_everyone.title,
          discussions.discussion_for_section_a.title,
          discussions.discussion_for_section_b.title,
          discussions.discussion_for_sections_a_and_b.title,
          discussions.discussion_for_second_and_third_students.title,

          # quizzes
          quizzes.quiz_for_everyone.title,
          quizzes.quiz_for_section_a.title,
          quizzes.quiz_for_section_b.title,
          quizzes.quiz_for_sections_a_and_b.title,
          quizzes.quiz_for_second_and_third_students.title
        )

        # hides the rest
        expect(list_of_assignments.text).to_not include(
          assignments.assignment_for_first_student.title,
          assignments.assignment_for_section_c.title,

          discussions.discussion_for_first_student.title,
          discussions.discussion_for_section_c.title,

          quizzes.quiz_for_first_student.title,
          quizzes.quiz_for_section_c.title
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
          assignments.assignment_for_everyone.title,
          assignments.assignment_for_section_a.title,
          assignments.assignment_for_section_b.title,
          assignments.assignment_for_sections_a_and_b.title,
          assignments.assignment_for_second_and_third_students.title,

          # discussions
          discussions.discussion_for_everyone.title,
          discussions.discussion_for_section_a.title,
          discussions.discussion_for_section_b.title,
          discussions.discussion_for_sections_a_and_b.title,
          discussions.discussion_for_second_and_third_students.title,

          # quizzes
          quizzes.quiz_for_everyone.title,
          quizzes.quiz_for_section_a.title,
          quizzes.quiz_for_section_b.title,
          quizzes.quiz_for_sections_a_and_b.title,
          quizzes.quiz_for_second_and_third_students.title
        )

        # hides the rest
        expect(list_of_assignments.text).to_not include(
          assignments.assignment_for_first_student.title,
          assignments.assignment_for_section_c.title,

          discussions.discussion_for_first_student.title,
          discussions.discussion_for_section_c.title,

          quizzes.quiz_for_first_student.title,
          quizzes.quiz_for_section_c.title
        )
      end
    end
  end

  context 'as the fourth student' do
    before(:each) { login_as(users.fourth_student) }

    context 'on the assignments index page' do
      before(:each) { go_to(urls.assignments_index_page) }

      it 'only shows assigned quizzes, assignments, and discussions', priority: "1", test_id: 619047 do
        expect(list_of_assignments.text).to include(
          # assignments
          assignments.assignment_for_everyone.title,
          assignments.assignment_for_section_c.title,

          # discussions
          discussions.discussion_for_everyone.title,
          discussions.discussion_for_section_c.title,

          # quizzes
          quizzes.quiz_for_everyone.title,
          quizzes.quiz_for_section_c.title
        )

        # hides the rest
        expect(list_of_assignments.text).to_not include(
          assignments.assignment_for_section_a.title,
          assignments.assignment_for_section_b.title,
          assignments.assignment_for_sections_a_and_b.title,
          assignments.assignment_for_first_student.title,
          assignments.assignment_for_second_and_third_students.title,

          discussions.discussion_for_section_a.title,
          discussions.discussion_for_section_b.title,
          discussions.discussion_for_sections_a_and_b.title,
          discussions.discussion_for_first_student.title,
          discussions.discussion_for_second_and_third_students.title,

          quizzes.quiz_for_section_a.title,
          quizzes.quiz_for_section_b.title,
          quizzes.quiz_for_sections_a_and_b.title,
          quizzes.quiz_for_first_student.title,
          quizzes.quiz_for_second_and_third_students.title
        )
      end
    end
  end
end
