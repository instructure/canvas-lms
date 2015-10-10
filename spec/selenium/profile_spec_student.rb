require File.expand_path(File.dirname(__FILE__) + '/helpers/profile_common')


describe 'profile_pics' do
  include_context "in-process server selenium tests"

  context 'as a student' do
    before do
      course_with_student_logged_in
    end

    it_behaves_like 'profile_settings_page', 'student'

    it_behaves_like 'profile_user_about_page', 'student'

    it_behaves_like 'user settings page change pic window', 'student'

  end
end