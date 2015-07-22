require File.expand_path(File.dirname(__FILE__) + '/common')
require File.expand_path(File.dirname(__FILE__) + '/helpers/theme_editor_common')

describe 'Theme Editor' do
  include_examples 'in-process server selenium tests'

  before(:each) do
    course_with_admin_logged_in
    Account.default.enable_feature!(:use_new_styles)
  end

  it 'should open theme editor', priority: "1", test_id: 239980 do
    open_theme_editor
    wait_for_ajaximations

    expect(fj('.Theme__editor-header_title').text).to include_text 'Theme Editor'
  end

  it 'should close theme editor on cancel and redirect to account settings page', priority: "1", test_id: 239981 do
    open_theme_editor
    wait_for_ajaximations

    # verifies theme editor is open
    expect(fj('.Theme__editor-header_title').text).to include_text 'Theme Editor'

    fj('button:contains("Cancel")').click
    # validations
    assert_flash_notice_message /Theme editor changes have been cancelled/
    expect(f('#breadcrumbs')).to include_text('Courses')
    expect(fj('.btn.button-sidebar-wide').text).to include_text 'Open Theme Editor'
  end

  it 'should display the preview button when valid change is made', priority: "1", test_id: 239984 do
    open_theme_editor
    wait_for_ajaximations
    
    # verifies theme editor is open
    expect(fj('.Theme__editor-header_title').text).to include_text 'Theme Editor'

    fj('.Theme__editor-color-block_input-text').send_keys('#dc6969')
    # validations
    expect(fj('.Theme__preview-button-text').text).to include_text 'Preview Your Changes'
  end

end