require File.expand_path(File.dirname(__FILE__) + '/common')
require File.expand_path(File.dirname(__FILE__) + '/helpers/theme_editor_common')
require File.expand_path(File.dirname(__FILE__) + '/helpers/color_common')

describe 'Theme Editor' do
  include_context 'in-process server selenium tests'
  include ColorCommon
  include ThemeEditorCommon

  before(:each) do
    Account.default.enable_feature!(:use_new_styles)
    course_with_admin_logged_in
  end

  it 'should open theme index from the admin page', priority: "1", test_id: 244225 do
    get "/accounts/#{Account.default.id}"

    f('#left-side #section-tabs .brand_configs').click
    expect(driver.title).to include 'Themes:'
  end

  it 'theme index renders shared themes' do
    brand_config = BrandConfig.create!(variables: {"ic-brand-primary" => "#321"})
    shared_themes = 2.times.map do |i|
      Account.default.shared_brand_configs.create!(
        name: "shared theme #{i}",
        brand_config_md5: brand_config.md5
      )
    end

    get "/accounts/#{Account.default.id}"
    f('#left-side #section-tabs .brand_configs').click
    shared_themes.each do |shared_theme|
      expect(fj(".ic-ThemeCard-main__name:contains('#{shared_theme.name}')")).to be_displayed
    end
  end

  it 'should open theme editor', priority: "1", test_id: 239980 do
    open_theme_editor(Account.default.id)

    expect(driver.title).to include 'Theme Editor'
  end

  it 'should close theme editor on cancel and redirect to /accounts/x', priority: "1", test_id: 239981 do
    open_theme_editor(Account.default.id)

    # verifies theme editor is open
    expect(driver.title).to include 'Theme Editor'

    fj('.Theme__header button:contains("Exit")').click
    driver.switch_to.alert.accept
    # validations
    assert_flash_notice_message /Theme editor changes have been cancelled/
    expect(driver.current_url).to end_with("/accounts/#{Account.default.id}/brand_configs")
    expect(f('#left-side #section-tabs .brand_configs').text).to eq 'Themes'
  end

  it 'should display the preview button when valid change is made', priority: "1", test_id: 239984 do
    open_theme_editor(Account.default.id)

    # verifies theme editor is open
    expect(driver.title).to include 'Theme Editor'

    f('.Theme__editor-color-block_input-text').send_keys('#dc6969')
    # validations
    expect(f('.Theme__preview-button-text')).to include_text 'Preview Your Changes'
  end

  it 'should accept valid Hex IDs', priority: "1", test_id: 239986 do
    open_theme_editor(Account.default.id)

    # verifies theme editor is open
    expect(driver.title).to include 'Theme Editor'

    all_colors(all_global_branding)

    # expect no validation error message to be present
    expect(f("body")).not_to contain_css(warning_message_css)
  end

  it 'should accept valid shortened Hex IDs', priority: "2", test_id: 240455 do
    open_theme_editor(Account.default.id)

    # verifies theme editor is open
    expect(driver.title).to include 'Theme Editor'

    f('.Theme__editor-color-block_input-text').send_keys('#fff')
    # validations
    expect(f('.Theme__preview-button-text')).to include_text 'Preview Your Changes'
  end

  it 'should accept valid color names', priority: "2", test_id: 240233 do
    open_theme_editor(Account.default.id)

    # verifies theme editor is open
    expect(driver.title).to include 'Theme Editor'

    f('.Theme__editor-color-block_input-text').send_keys('orange')
    # validations
    expect(f('.Theme__preview-button-text')).to include_text 'Preview Your Changes'
  end

  it 'should not accept invalid hex IDs', priority: "1", test_id: 239987 do
    open_theme_editor(Account.default.id)

    # verifies theme editor is open
    expect(driver.title).to include 'Theme Editor'

    # enters invalid ID and presses tab
    f('.Theme__editor-color-block_input-text').send_keys('#xxxxx!')
    f('.Theme__editor-color-block_input-text').send_keys(:tab)

    # validations
    expect(f('.ic-Form-message--error')).to include_text "'#xxxxx!' is not a valid color."
  end

  it 'K12 Theme should be automatically set when K12 Feature Flag is turned on', priority: "1", test_id: 240001

  it 'should preview should display a progress bar when generating preview', priority: "1", test_id: 239990 do
    open_theme_editor(Account.default.id)
    f('.Theme__editor-color-block_input-text').send_keys(random_hex_color)

    expect(f("body")).not_to contain_css('div.progress-bar__bar-container')
    preview_your_changes
    expect(f('div.progress-bar__bar-container')).to be
  end

  it 'should have validation for every text field', priority: "2", test_id: 241992 do
    skip_if_firefox('Broken after upgrade to webdriver 2.53 - seems to be a timing issue on jenkins, passes locally')
    open_theme_editor(Account.default.id)

    # input invalid text into every text field
    create_theme('#xxxxxx')

    # tab to trigger last validation
    fj('.Theme__editor-color-block_input--has-error:last').send_keys(:tab)

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
