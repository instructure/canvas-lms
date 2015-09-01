require File.expand_path(File.dirname(__FILE__) + '/common')
require File.expand_path(File.dirname(__FILE__) + '/helpers/files_common')
require File.expand_path(File.dirname(__FILE__) + '/helpers/announcements_common')
require File.expand_path(File.dirname(__FILE__) + '/helpers/color_common')


describe 'dashcards' do
  include_context 'in-process server selenium tests'

  context 'as a student' do

    before do
      @course = course(active_all: true)
      course_with_student_logged_in(active_all: true)
      Account.default.enable_feature! :use_new_styles
    end

    it 'should redirect to announcements index', priority: "1", test_id: 222509 do
      # Icon will not display unless there is an announcement.
      create_announcement
      get '/'

      f('.icon-announcement').click
      expect(driver.current_url).to include("/courses/#{@course.id}/announcements")
    end

    it 'should redirect to assignments index', priority: "1", test_id: 238637 do
      # Icon will not display unless there is an assignment.
      @course.assignments.create!(title: 'assignment 1', name: 'assignment 1')
      get '/'

      f('.icon-assignment').click
      expect(driver.current_url).to include("/courses/#{@course.id}/assignments")
    end

    it 'should redirect to discussions index', priority: "1", test_id: 238638 do
      # Icon will not display unless there is a discussion.
      @course.discussion_topics.create!(title: 'discussion 1', message: 'This is a message.')
      get '/'

      f('.icon-discussion').click
      expect(driver.current_url).to include("/courses/#{@course.id}/discussion_topics")
    end

    it 'should redirect to files index', priority: "1", test_id: 238639 do
      # Icon will not display unless there is a file.
      add_file(fixture_file_upload('files/example.pdf', 'application/pdf'), @course, 'example.pdf')
      get '/'

      f('.icon-folder').click
      expect(driver.current_url).to include("/courses/#{@course.id}/files")
    end

    it 'should display color picker', priority: "1", test_id: 249122 do
      get '/'
      f('.icon-settings').click
      expect(f('.ColorPicker__Container')).to be_displayed
    end

    it 'should customize dashcard color', priority: "1", test_id: 239991 do
      hex = random_hex_color
      get '/'

      f('.icon-settings').click
      expect(f('.ColorPicker__Container')).to be_displayed

      replace_content(fj('#ColorPickerCustomInput'), hex)
      f('button.Button.Button--primary').click

      keep_trying_until(5) do
        if fj('.ic-DashboardCard__background').attribute(:style).include?('rgb')
          rgb = convert_hex_to_rgb_color(hex)
          expect(fj('.ic-DashboardCard__background').attribute(:style)).to include_text(rgb)
        else
          expect(fj('.ic-DashboardCard__background').attribute(:style)).to include_text(hex)
        end
      end
    end
  end
end