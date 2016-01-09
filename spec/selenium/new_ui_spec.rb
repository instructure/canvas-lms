require_relative 'common'
require_relative 'helpers/files_common'

describe 'new ui' do
  include_context "in-process server selenium tests"
  include FilesCommon

  before(:each) do
    Account.default.enable_feature!(:use_new_styles)
  end

  context 'as admin' do

    it 'should not show k-12 template in the theme editor pulldown if disabled', priority: "2", test_id: 295290 do
      admin_logged_in
      get "/accounts/#{Account.default.id}/theme_editor"
      expect(fj('#sharedThemes')).not_to include_text('K12 Theme')
    end
  end

  context 'as teacher' do

    before(:each) do
      course_with_teacher_logged_in
    end

    it 'should show breadcrumbs for each course navigation menu item', priority: "2", test_id: 242471 do
      get "/courses/#{@course.id}"
      expect(f('.home + li .ellipsible')).to include_text("#{@course.course_code}")
      get "/courses/#{@course.id}/announcements"
      expect(f('.home + li + li .ellipsible')).to include_text('Announcements')
      expect(f('.home + li .ellipsible')).to include_text("#{@course.course_code}")
      get "/courses/#{@course.id}/assignments"
      expect(f('.home + li + li .ellipsible')).to include_text('Assignments')
      expect(f('.home + li .ellipsible')).to include_text("#{@course.course_code}")
      get "/courses/#{@course.id}/discussion_topics"
      expect(f('.home + li + li .ellipsible')).to include_text('Discussions')
      expect(f('.home + li .ellipsible')).to include_text("#{@course.course_code}")
      get "/courses/#{@course.id}/gradebook"
      expect(f('.home + li + li .ellipsible')).to include_text('Grades')
      expect(f('.home + li .ellipsible')).to include_text("#{@course.course_code}")
      get "/courses/#{@course.id}/users"
      expect(f('.home + li + li .ellipsible')).to include_text('People')
      expect(f('.home + li .ellipsible')).to include_text("#{@course.course_code}")
      get "/courses/#{@course.id}/wiki"
      expect(f('.home + li + li .ellipsible')).to include_text('Pages')
      expect(f('.home + li .ellipsible')).to include_text("#{@course.course_code}")
      get "/courses/#{@course.id}/files"
      expect(f('#breadcrumbs .ellipsis')).to include_text('Files')
      expect(f('.ellipsible')).to include_text("#{@course.course_code}")
      get "/courses/#{@course.id}/assignments/syllabus"
      expect(f('.home + li + li .ellipsible')).to include_text('Syllabus')
      expect(f('.home + li .ellipsible')).to include_text("#{@course.course_code}")
      get "/courses/#{@course.id}/outcomes"
      expect(f('.home + li + li .ellipsible')).to include_text('Outcomes')
      expect(f('.home + li .ellipsible')).to include_text("#{@course.course_code}")
      get "/courses/#{@course.id}/quizzes"
      expect(f('.home + li + li .ellipsible')).to include_text('Quizzes')
      expect(f('.home + li .ellipsible')).to include_text("#{@course.course_code}")
      get "/courses/#{@course.id}/modules"
      expect(f('.home + li + li .ellipsible')).to include_text('Modules')
      expect(f('.home + li .ellipsible')).to include_text("#{@course.course_code}")
      get "/courses/#{@course.id}/settings"
      expect(f('.home + li + li .ellipsible')).to include_text('Settings')
      expect(f('.home + li .ellipsible')).to include_text("#{@course.course_code}")
    end

    it 'should show new files folder icon in course files', priority: "2", test_id: 248683 do
      get "/courses/#{@course.id}/files"
      add_folder
      # verifying new files folder icon css property still displays with new ui
      f('.media-object.ef-big-icon.FilesystemObjectThumbnail.mimeClass-folder').displayed?
    end

    it 'should not override high contrast theme', priority: "2", test_id: 244898 do
      get '/profile/settings'
      f('.ic-Super-toggle__switch').click
      wait_for_ajaximations
      f = FeatureFlag.last
      expect(f.state).to eq 'on'
      expect(f('.profile_settings.active').css_value('background-color')).to eq('rgba(0, 150, 219, 1)')
    end

    it 'should not break tiny mce css', priority: "2", test_id: 244891 do
      get "/courses/#{@course.id}/discussion_topics/new?is_announcement=true"
      mce_icons = f('.mce-ico')
      expect(mce_icons.css_value('font-family')).to eq('tinymce,Arial')
      expect(mce_icons.css_value('font-style')).to eq('normal')
      expect(mce_icons.css_value('font-weight')).to eq('400')
      expect(mce_icons.css_value('font-size')).to eq('16px')
      expect(mce_icons.css_value('vertical-align')).to eq('text-top')
      expect(mce_icons.css_value('display')).to eq('inline-block')
      expect(mce_icons.css_value('background-size')).to eq('cover')
      expect(mce_icons.css_value('width')).to eq('16px')
      expect(mce_icons.css_value('height')).to eq('16px')
    end

    it 'should not break equation editor css', priority: "2", test_id: 273600 do
      get "/courses/#{@course.id}/assignments/new"
      f('div#mceu_19.mce-widget.mce-btn').click
      wait_for_ajaximations
      f('.mathquill-toolbar-panes, .mathquill-tab-bar').displayed?
    end
  end

  context 'as student' do

    it 'should still have courses icon when only course is unpublished', priority: "1", test_id: 288860 do
      course_with_student_logged_in(active_course: false)
      get "/"
      global_nav_courses_link = fj('#global_nav_courses_link')
      expect(global_nav_courses_link).to be_displayed
      global_nav_courses_link.click
      wait_for_ajaximations
      course_link_list = fj('ul.ReactTray__link-list')
      course_link_list.find_element(:link_text, 'All Courses').click
      wait_for_ajaximations
      expect(fj('span.name')).to have_attribute('title', "#{@course.name}")
      expect(fj('span.label.label-hollow')).to include_text('unpublished')
    end
  end
end
