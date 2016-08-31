require File.expand_path(File.dirname(__FILE__) + '/common')

describe 'Global Navigation' do
  include_context 'in-process server selenium tests'

  context 'As a Teacher' do
    before do
      course_with_teacher_logged_in
    end

    describe 'Profile Link' do
      it 'should show the profile tray upon clicking' do
        get "/"
        f('#global_nav_profile_link').click
        expect(f('#global_nav_profile_header')).to be_displayed
      end

      # Profile links are hardcoded, so check that something is appearing for
      # the display_name in the tray header
      it 'should populate the profile tray with the current user display_name' do
        get "/"
        expect(displayed_username).to eq(@user.name)
      end
    end

    describe 'Courses Link' do
      it 'should show the courses tray upon clicking' do
        get "/"
        f('#global_nav_courses_link').click
        wait_for_ajaximations
        expect(f('.ic-NavMenu__primary-content')).to be_displayed
      end

      it 'should populate the courses tray when using the keyboard to open it' do
        get "/"
        driver.execute_script('$("#global_nav_courses_link").focus()')
        f('#global_nav_courses_link').send_keys(:enter)
        wait_for_ajaximations
        links = ff('.ic-NavMenu__link-list li')
        expect(links.count).to eql 2
      end
    end

    describe 'LTI Tools' do
      it 'should show a custom logo/link for LTI tools' do
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
          :text => "Commons",
          :icon_svg_path_64 => 'M100,37L70.1,10.5v17.6H38.6c-4.9,0-8.8,3.9-8.8,8.8s3.9,8.8,8.8,8.8h31.5v17.6L100,37z'
        })
        @tool.save!
        get "/"
        expect(f('.ic-icon-svg--lti')).to be_displayed
      end
    end
    describe 'Navigation Expand/Collapse Link' do
      it 'should collapse and expand the navigation when clicked' do
        get "/"
        f('#primaryNavToggle').click
        wait_for_ajaximations
        expect(f('body')).not_to have_class("primary-nav-expanded")
        f('#primaryNavToggle').click
        wait_for_ajaximations
        expect(f('body')).to have_class("primary-nav-expanded")
      end
    end
  end
end
