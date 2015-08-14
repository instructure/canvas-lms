require File.expand_path(File.dirname(__FILE__) + '/common')
require File.expand_path(File.dirname(__FILE__) + '/helpers/theme_editor_common')
require File.expand_path(File.dirname(__FILE__) + '/helpers/color_common')

describe 'Theme Editor' do
  include_context 'in-process server selenium tests'

  before(:each) do
    course_with_admin_logged_in
    Account.default.enable_feature!(:use_new_styles)
  end

  it 'should open theme editor from the admin page', priority: "1", test_id: 244225 do
    get "/accounts/#{Account.default.id}"

    fj('#right-side > div:nth-of-type(4) > a.btn.button-sidebar-wide').click
    wait_for_ajaximations
    expect(fj('.Theme__editor-header_title').text).to include_text 'Theme Editor'
  end

  it 'should open theme editor', priority: "1", test_id: 239980 do
    open_theme_editor(Account.default.id)

    expect(fj('.Theme__editor-header_title').text).to include_text 'Theme Editor'
  end

  it 'should close theme editor on cancel and redirect to account settings page', priority: "1", test_id: 239981 do
    open_theme_editor(Account.default.id)

    # verifies theme editor is open
    expect(fj('.Theme__editor-header_title').text).to include_text 'Theme Editor'

    fj('button:contains("Cancel")').click
    # validations
    assert_flash_notice_message /Theme editor changes have been cancelled/
    expect(f('#breadcrumbs')).to include_text('Courses')
    expect(fj('.btn.button-sidebar-wide').text).to include_text 'Open Theme Editor'
  end

  it 'should display the preview button when valid change is made', priority: "1", test_id: 239984 do
    open_theme_editor(Account.default.id)

    # verifies theme editor is open
    expect(fj('.Theme__editor-header_title').text).to include_text 'Theme Editor'

    fj('.Theme__editor-color-block_input-text').send_keys('#dc6969')
    # validations
    expect(fj('.Theme__preview-button-text').text).to include_text 'Preview Your Changes'
  end

  it 'should accept valid Hex IDs', priority: "1", test_id: 239986 do
    open_theme_editor(Account.default.id)

    # verifies theme editor is open
    expect(fj('.Theme__editor-header_title').text).to include_text 'Theme Editor'

    all_colors(all_global_branding)

    # expect no validation error message to be present
    expect(single_warning_message).not_to be
  end

  it 'should accept valid shortened Hex IDs', priority: "2", test_id: 240455 do
    open_theme_editor(Account.default.id)

    # verifies theme editor is open
    expect(fj('.Theme__editor-header_title').text).to include_text 'Theme Editor'

    fj('.Theme__editor-color-block_input-text').send_keys('#fff')
    # validations
    expect(fj('.Theme__preview-button-text').text).to include_text 'Preview Your Changes'
  end

  it 'should accept valid color names', priority: "2", test_id: 240233 do
    open_theme_editor(Account.default.id)

    # verifies theme editor is open
    expect(fj('.Theme__editor-header_title').text).to include_text 'Theme Editor'

    fj('.Theme__editor-color-block_input-text').send_keys('orange')
    # validations
    expect(fj('.Theme__preview-button-text').text).to include_text 'Preview Your Changes'
  end

  it 'should not accept invalid hex IDs', priority: "1", test_id: 239987 do
    open_theme_editor(Account.default.id)

    # verifies theme editor is open
    expect(fj('.Theme__editor-header_title').text).to include_text 'Theme Editor'

    # enters invalid ID and presses tab
    fj('.Theme__editor-color-block_input-text').send_keys('#xxxxx!')
    fj('.Theme__editor-color-block_input-text').send_keys(:tab)

    # validations
    expect(fj('.ic-Form-message--error').text).to include_text "'#xxxxx!' is not a valid color."
  end

  it 'K12 Theme should be automatically set when K12 Feature Flag is turned on', priority: "1", test_id: 240001 do
    skip("Skipped because the K12 template option does not appear in selenium tests")
    Account.default.enable_feature!(:k12)
    open_theme_editor(Account.default.id)
    expect(f('div.accordion.ui-accordion--mini.Theme__editor-accordion.ui-accordion.ui-widget.ui-helper-reset > div:nth-of-type(1) > section:first-child > div.Theme__editor-form--color > div.Theme__editor-color-block > span > input.Theme__editor-color-block_input-text.Theme__editor-color-block_input').attribute(:placeholder)).to include_text('#E66135')
  end

  it 'Theme editor has a dropdown menu for Templates', priority: "1", test_id: 244889 do
    open_theme_editor(Account.default.id)
    expect(f('#sharedThemes')).to include_text('Start from a template...')
  end

  it 'should preview should display a progress bar when generating preview', priority: "1", test_id: 239990 do
    open_theme_editor(Account.default.id)
    fj('.Theme__editor-color-block_input-text').send_keys(random_hex_color)

    expect(f('div.progress-bar__bar-container')).not_to be
    preview_your_changes
    expect(f('div.progress-bar__bar-container')).to be
  end

  it 'should have validation for every text field', priority: "2", test_id: 241992 do
    open_theme_editor(Account.default.id)

    # input invalid text into every text field
    create_theme('#xxxxxx')

    # tab to trigger last validation
    fj('div.accordion.ui-accordion--mini.Theme__editor-accordion.ui-accordion.ui-widget.ui-helper-reset > div:nth-of-type(3) > section.Theme__editor-accordion_element.Theme__editor-color.ic-Form-control > div.Theme__editor-form--color > div.Theme__editor-color-block > span > input.Theme__editor-color-block_input-text.Theme__editor-color-block_input.Theme__editor-color-block_input--has-error').send_keys(:tab)

    # expect all 15 text fields to have working validation
    expect(all_warning_messages.length).to eq 15
  end

  it 'should have color squares that match the hex value', priority: "2", test_id: 241993 do
    open_theme_editor(Account.default.id)
    create_theme

    click_global_branding
    verify_colors_for_arrays(all_global_branding, all_global_branding('color_box'))

    click_global_navigation
    verify_colors_for_arrays(all_global_navigation, all_global_navigation('color_box'))

    click_watermarks_and_other_images
    verify_colors_for_arrays(all_watermarks, all_watermarks('color_box'))
  end
end