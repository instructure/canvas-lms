require_relative 'common'
require_relative 'helpers/files_common'

describe 'new ui' do
  include_context "in-process server selenium tests"
  include FilesCommon

  before(:each) do
    Account.default.enable_feature!(:use_new_styles)
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
