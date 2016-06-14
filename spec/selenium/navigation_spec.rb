require File.expand_path(File.dirname(__FILE__) + '/common')

describe 'Global Navigation' do
  include_context 'in-process server selenium tests'

  context 'As a Teacher' do
    before do
      course_with_teacher_logged_in
      Account.default.enable_feature! :use_new_styles
    end

    describe 'Courses Link' do
      it 'should show the courses tray upon clicking' do
        get "/"
        f('#global_nav_courses_link').click
        wait_for_ajaximations
        expect(f('.ReactTray__primary-content')).to be_displayed
      end

      it 'should populate the courses tray when using the keyboard to open it' do
        get "/"
        driver.execute_script('$("#global_nav_courses_link").focus()')
        f('#global_nav_courses_link').send_keys(:enter)
        wait_for_ajaximations
        links = ff('.ReactTray__link-list li')
        expect(links.count).to eql 2
      end
    end

    describe 'LTI Tools' do
      it 'should show the Commons logo/link if it is enabled' do
        Account.default.enable_feature! :lor_for_account
        @teacher.enable_feature! :lor_for_user
        @tool = Account.default.context_external_tools.new({
          :name => "Commons",
          :domain => "canvaslms.com",
          :consumer_key => '12345',
          :shared_secret => 'secret'
        })
        @tool.set_extension_setting(:global_navigation, {
          :url => "canvaslms.com",
          :visibility => "admins",
          :display_type => "full_width",
          :text => "Commons"
        })
        @tool.save!
        get "/"
        expect(f('.ic-icon-svg--commons')).to be_displayed
      end
    end
  end
end
