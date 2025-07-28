# frozen_string_literal: true

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

require_relative "../common"
require_relative "../helpers/theme_editor_common"
require_relative "../helpers/color_common"

describe "Theme Editor" do
  include_context "in-process server selenium tests"
  include ColorCommon
  include ThemeEditorCommon

  before do
    course_with_admin_logged_in
  end

  it "opens theme index from the admin page", priority: "1" do
    get "/accounts/#{Account.default.id}"

    f("#left-side #section-tabs .brand_configs").click
    expect(driver.title).to include "Themes:"
  end

  it "theme index renders shared themes" do
    brand_config = BrandConfig.create!(variables: { "ic-brand-primary" => "#321" })
    shared_themes = Array.new(2) do |i|
      Account.default.shared_brand_configs.create!(
        name: "shared theme #{i}",
        brand_config_md5: brand_config.md5
      )
    end

    get "/accounts/#{Account.default.id}"
    f("#left-side #section-tabs .brand_configs").click
    shared_themes.each do |shared_theme|
      expect(fj(".ic-ThemeCard-main__name:contains('#{shared_theme.name}')")).to be_displayed
    end
  end

  it "opens theme editor", priority: "1" do
    open_theme_editor(Account.default.id)

    expect(driver.title).to include "Theme Editor"
  end

  it "closes theme editor on cancel and redirect to /accounts/x", priority: "1" do
    skip_if_safari(:alert)
    open_theme_editor(Account.default.id)

    # verifies theme editor is open
    expect(driver.title).to include "Theme Editor"

    fj('.Theme__header button:contains("Exit")').click
    driver.switch_to.alert.accept
    # validations
    assert_flash_notice_message("Theme editor changes have been cancelled")
    expect(driver.current_url).to end_with("/accounts/#{Account.default.id}/brand_configs")
    expect(f("#left-side #section-tabs .brand_configs").text).to eq "Themes"
  end

  it "closes after preview (no changes saved)", priority: "1" do
    skip_if_safari(:alert)
    open_theme_editor(Account.default.id)

    # verifies theme editor is open
    expect(driver.title).to include "Theme Editor"
    f(".Theme__editor-color-block_input-text").send_keys("#dc6969")

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
    expect(f("#left-side #section-tabs .brand_configs").text).to eq "Themes"
  end

  it "displays the preview button when valid change is made", priority: "1" do
    open_theme_editor(Account.default.id)

    # verifies theme editor is open
    expect(driver.title).to include "Theme Editor"

    f(".Theme__editor-color-block_input-text").send_keys("#dc6969")
    # validations
    expect(f(".Theme__preview-button-text")).to include_text "Preview Your Changes"
  end

  it "accepts valid Hex IDs", priority: "1" do
    open_theme_editor(Account.default.id)
    click_global_branding

    # verifies theme editor is open
    expect(driver.title).to include "Theme Editor"

    all_colors(all_global_branding)

    # expect no validation error message to be present
    expect(f("body")).not_to contain_css(warning_message_css)
  end

  it "accepts valid shortened Hex IDs", priority: "2" do
    open_theme_editor(Account.default.id)
    click_global_branding

    # verifies theme editor is open
    expect(driver.title).to include "Theme Editor"

    f(".Theme__editor-color-block_input-text").send_keys("#fff")
    # validations
    expect(f(".Theme__preview-button-text")).to include_text "Preview Your Changes"
  end

  it "accepts valid color names", priority: "2" do
    open_theme_editor(Account.default.id)
    click_global_branding

    # verifies theme editor is open
    expect(driver.title).to include "Theme Editor"

    f(".Theme__editor-color-block_input-text").send_keys("orange")
    # validations
    expect(f(".Theme__preview-button-text")).to include_text "Preview Your Changes"
  end

  it "does not accept invalid hex IDs", priority: "1" do
    open_theme_editor(Account.default.id)
    click_global_branding

    # verifies theme editor is open
    expect(driver.title).to include "Theme Editor"

    # enters invalid ID and presses tab
    invalid_color = "#xxxxx!"
    f(".Theme__editor-color-block_input-text").send_keys(invalid_color)
    f(".Theme__editor-color-block_input-text").send_keys(:tab)

    # validations
    expect(f('[id="warning-message"]')).to include_text "'#{invalid_color}' is not a valid color."
  end

  it "K12 Theme should be automatically set when K12 Feature Flag is turned on", priority: "1"

  it "previews should display a progress bar when generating preview", priority: "1" do
    open_theme_editor(Account.default.id)
    f(".Theme__editor-color-block_input-text").send_keys(random_hex_color)

    expect(f("body")).not_to contain_css("div.progress-bar__bar-container")
    preview_your_changes
    expect(f("div.progress-bar__bar-container")).to be
  end

  it "has validation for every text field", priority: "2" do
    skip("Broken after upgrade to webdriver 2.53 - seems to be a timing issue on jenkins, passes locally")
    open_theme_editor(Account.default.id)

    # input invalid text into every text field
    create_theme("#xxxxxx")

    # tab to trigger last validation
    fj(".Theme__editor-color-block_input--has-error:last").send_keys(:tab)

    # expect all 15 text fields to have working validation
    expect(all_warning_messages.length).to eq 15
  end

  it "allows fields to be changed after colors are unlinked", priority: 3 do
    bc = BrandConfig.create(variables: {
                              "ic-brand-primary" => "#999",
                              "ic-brand-button--primary-bgd" => "#888"
                            })
    Account.default.brand_config = bc
    Account.default.save!
    open_theme_editor(Account.default.id)
    ff(".Theme__editor-color-block_input-text")[1].send_keys("#000") # main text color
    expect_new_page_load do
      preview_your_changes
      run_jobs
    end
    color_labels = ff(".Theme__editor-color-label")
    expect(color_labels[0].attribute("style")).to include("background-color: rgb(153, 153, 153)")
    expect(color_labels[1].attribute("style")).to include("background-color: rgb(0, 0, 0)")
  end

  it "only stores modified values to the database" do
    open_theme_editor(Account.default.id)
    ff(".Theme__editor-color-block_input-text")[1].send_keys("#000") # main text color
    expect_new_page_load do
      preview_your_changes
      run_jobs
    end
    brand_config_md5 = driver.execute_script "return ENV.brandConfig.md5"
    expect(BrandConfig.find(brand_config_md5).variables).to eq({ "ic-brand-font-color-dark" => "#000" })
  end

  it "applies the theme to the account" do
    open_theme_editor(Account.default.id)
    f('input[id="brand_config[variables][ic-brand-primary]"]').send_keys("#639")
    f('input[id="brand_config[variables][ic-link-color]"]').send_keys("#ff00ff")
    expect_new_page_load do
      preview_your_changes
      run_jobs
    end
    fj('button:contains("Save theme")').click

    name_input = f('input[name="name"]')

    keep_trying_until(1) do
      name_input.send_keys("Test Theme")
      true
    end
    fj('form[aria-label="Save Theme Dialog"] button:contains("Save theme")').click
    apply_btn = fj('button:contains("Apply theme")')
    keep_trying_until(1) do
      apply_btn.click
      true
    end
    driver.switch_to.alert.accept

    # wait for the popup
    wait_for_ajaximations
    run_jobs

    expect(fj('button:contains("Theme") span').css_value("background-color")).to eq("rgba(102, 51, 153, 1)")

    # also make sure instUI stuff picks up the theme variables
    f("#global_nav_accounts_link").click
    expect(fj('[aria-label="Admin tray"] ul li a:contains("Default Account")').css_value("color")).to eq("rgba(255, 0, 255, 1)")
  end
end
