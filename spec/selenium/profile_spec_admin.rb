require File.expand_path(File.dirname(__FILE__) + '/helpers/profile_common')

describe 'profile_pics' do
  include_context "in-process server selenium tests"

  context 'as an admin' do
    before do
      admin_logged_in
    end

    it_behaves_like 'profile_settings_page', 'admin'

    it_behaves_like 'profile_user_about_page', 'admin'

    it_behaves_like 'user settings page change pic window', 'admin'

  end
end
