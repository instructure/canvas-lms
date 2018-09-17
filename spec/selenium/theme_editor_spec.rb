#
# Copyright (C) 2015 - present Instructure, Inc.
#
# This file is part of Canvas.
#
# Canvas is free software: you can redistribute it and/or modify it under
# the terms of the GNU Affero General Public License as published by the Free
# Software Foundation, version 3 of the License.
#
# Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
# A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
# details.
#
# You should have received a copy of the GNU Affero General Public License along
# with this program. If not, see <http://www.gnu.org/licenses/>.

require File.expand_path(File.dirname(__FILE__) + '/common')
require File.expand_path(File.dirname(__FILE__) + '/helpers/theme_editor_common')
require File.expand_path(File.dirname(__FILE__) + '/helpers/color_common')

describe 'Theme Editor' do
  include_context 'in-process server selenium tests'
  include ColorCommon
  include ThemeEditorCommon

  before(:each) do
    make_full_screen
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
    skip_if_safari(:alert)
    open_theme_editor(Account.default.id)

    # verifies theme editor is open
    expect(driver.title).to include 'Theme Editor'

    fj('.Theme__header button:contains("Exit")').click
    driver.switch_to.alert.accept
    # validations
    assert_flash_notice_message("Theme editor changes have been cancelled")
    expect(driver.current_url).to end_with("/accounts/#{Account.default.id}/brand_configs")
    expect(f('#left-side #section-tabs .brand_configs').text).to eq 'Themes'
  end

  it 'should close after preview (no changes saved)', priority: "1", test_id: 239984 do
    skip_if_safari(:alert)
    open_theme_editor(Account.default.id)

    # verifies theme editor is open
    expect(driver.title).to include 'Theme Editor'
    f('.Theme__editor-color-block_input-text').send_keys('#dc6969')

    expect_new_page_load do
      preview_your_changes
      expect(fj('h2:contains("Generating preview")')).to be_displayed
      run_jobs
    end

    exit_btn = fj('.Theme__header button:contains("Exit")')
    exit_btn.click
    driver.switch_to.alert.accept
    assert_flash_notice_message("Theme editor changes have been cancelled")
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
    click_global_branding

    # verifies theme editor is open
    expect(driver.title).to include 'Theme Editor'

    all_colors(all_global_branding)

    # expect no validation error message to be present
    expect(f("body")).not_to contain_css(warning_message_css)
  end

  it 'should accept valid shortened Hex IDs', priority: "2", test_id: 240455 do
    open_theme_editor(Account.default.id)
    click_global_branding

    # verifies theme editor is open
    expect(driver.title).to include 'Theme Editor'

    f('.Theme__editor-color-block_input-text').send_keys('#fff')
    # validations
    expect(f('.Theme__preview-button-text')).to include_text 'Preview Your Changes'
  end

  it 'should accept valid color names', priority: "2", test_id: 240233 do
    open_theme_editor(Account.default.id)
    click_global_branding

    # verifies theme editor is open
    expect(driver.title).to include 'Theme Editor'

    f('.Theme__editor-color-block_input-text').send_keys('orange')
    # validations
    expect(f('.Theme__preview-button-text')).to include_text 'Preview Your Changes'
  end

  it 'should not accept invalid hex IDs', priority: "1", test_id: 239987 do
    open_theme_editor(Account.default.id)
    click_global_branding

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
    skip('Broken after upgrade to webdriver 2.53 - seems to be a timing issue on jenkins, passes locally')
    open_theme_editor(Account.default.id)

    # input invalid text into every text field
    create_theme('#xxxxxx')

    # tab to trigger last validation
    fj('.Theme__editor-color-block_input--has-error:last').send_keys(:tab)

    # expect all 15 text fields to have working validation
    expect(all_warning_messages.length).to eq 15
  end

  it 'should allow fields to be changed after colors are unlinked', priority: 3, test_id: 3470985 do
    bc = BrandConfig.create(variables: {
                              'ic-brand-primary' => '#999',
                              'ic-brand-button--primary-bgd' => '#888'
                            })
    Account.default.brand_config = bc
    Account.default.save!
    open_theme_editor(Account.default.id)
    ff('.Theme__editor-color-block_input-text')[1].send_keys('#000') # main text color
    expect_new_page_load do
      preview_your_changes
      run_jobs
    end
    color_labels = ff('.Theme__editor-color-label')
    expect(color_labels[0].attribute('style')).to include('background-color: rgb(153, 153, 153)')
    expect(color_labels[1].attribute('style')).to include('background-color: rgb(0, 0, 0)')
  end

  it 'should only store modified values to the database' do
    open_theme_editor(Account.default.id)
    ff('.Theme__editor-color-block_input-text')[1].send_keys('#000') # main text color
    expect_new_page_load do
      preview_your_changes
      run_jobs
    end
    brand_config_md5 = driver.execute_script "return ENV.brandConfig.md5"
    expect(BrandConfig.find(brand_config_md5).variables).to eq({"ic-brand-font-color-dark"=>"#000"})
  end

  it 'should apply the theme to the account' do
    open_theme_editor(Account.default.id)
    ff('.Theme__editor-color-block_input-text')[0].send_keys('#639') # primary brand color
    expect_new_page_load do
      preview_your_changes
      run_jobs
    end
    fj('button:contains("Save theme")').click

    name_input = f('#new_theme_theme_name')
    keep_trying_until(1) do
      name_input.send_keys('Test Theme')
      true
    end
    fj('span[aria-label="Save Theme"] button:contains("Save theme")').click
    apply_btn = fj('button:contains("Apply theme")')
    keep_trying_until(1) do
      apply_btn.click
      true
    end
    driver.switch_to.alert.accept
    expect(fj('button:contains("Theme")').css_value('background-color')).to eq('rgba(102, 51, 153, 1)')
  end
end
