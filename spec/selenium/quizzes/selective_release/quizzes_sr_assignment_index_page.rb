require File.expand_path(File.dirname(__FILE__) + '/../../helpers/selective_release_common')

describe 'Viewing a selective release quiz' do
  include_context 'selective release'

  context 'as the teacher' do
    before(:each) { login_as_teacher }

    context 'on the assignments index page' do
      before(:each) { go_to_assignments_index_page }

      it 'shows all the quizzes'
    end
  end

  context 'as the first student' do
    before(:each) { login_as_first_student }

    context 'on the assignments index page' do
      before(:each) { go_to_assignments_index_page }

      it 'shows the quizzes for Section A'

      it 'hides the quizzes for sections B and C'
    end
  end

  context 'as the first observer' do
    before(:each) { login_as_first_observer }

    context 'on the assignments index page' do
      before(:each) { go_to_assignments_index_page }

      it 'shows the quizzes for Section A'

      it 'hides the quizzes for sections B and C'
    end
  end
end
