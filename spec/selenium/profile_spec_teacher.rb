require File.expand_path(File.dirname(__FILE__) + '/helpers/profile_common')


describe 'profile_pics' do
  include_context "in-process server selenium tests"

  context 'as a teacher' do
    before do
      course_with_teacher_logged_in
    end

    it_behaves_like 'profile_settings_page', 'teacher'

    it_behaves_like 'profile_user_about_page', 'teacher'

    it_behaves_like 'user settings page change pic window', 'teacher'

  end
end