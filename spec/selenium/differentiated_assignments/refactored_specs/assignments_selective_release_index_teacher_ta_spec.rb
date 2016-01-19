require_relative '../../helpers/selective_release/selective_release_common'

describe 'Viewing selective release assignments' do
  include_context 'selective release'

  context 'as the teacher' do
    before(:each) { login_as(users.teacher) }

    context 'on the assignments index page' do
      before(:each) { go_to(urls.assignments_index_page) }

      it 'shows all quizzes, assignments, and discussions', priority: "1", test_id: 618802 do
        expect(list_of_assignments.text).to include(
          *assignments.all.map(&:title),
          *discussions.all.map(&:title),
          *quizzes.all.map(&:title)
        )
      end
    end
  end

  context 'as the TA' do
    before(:each) { login_as(users.ta) }

    context 'on the assignments index page' do
      before(:each) { go_to(urls.assignments_index_page) }

      it 'shows all quizzes, assignments, and discussions', priority: "1", test_id: 618803 do
        expect(list_of_assignments.text).to include(
          *assignments.all.map(&:title),
          *discussions.all.map(&:title),
          *quizzes.all.map(&:title)
        )
      end
    end
  end
end