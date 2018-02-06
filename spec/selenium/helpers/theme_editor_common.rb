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

require File.expand_path(File.dirname(__FILE__) + '/../common')

module ThemeEditorCommon
  def open_theme_editor_with_btn
    f('.btn.button-sidebar-wide').click
  end

  def open_theme_editor(account_id)
    get "/accounts/#{account_id}/theme_editor"
  end

  # the close mechanism only works with beta and not with how it is in master
  def close_theme_editor
    fj('button:contains("Cancel")').click
  end

  def select_template(template)
    # "Canvas Default" "K12 Theme"
    select_list = Selenium::WebDriver::Support::Select.new(f('#sharedThemes'))
    select_list.select_by(:text, template)
  end

  def apply_settings
    f('div.Theme__editor-header_actions > span').click
    wait_for_ajaximations
    preview_your_changes
    accept_alert
  end

  def preview_your_changes
    f('button.Button.Button--primary > span').click
    wait_for_ajaximations
  end

  def warning_message_css
    '.ic-Form-message--error'
  end

  def all_warning_messages
    ff(warning_message_css)
  end

  def click_global_branding
    fj('h3:contains("Global Branding")').click
  end

  def click_global_navigation
    fj('h3:contains("Global Navigation")').click
  end

  def click_watermarks_and_other_images
    fj('h3:contains("Watermarks & Other Images")').click
  end

  def primary_color
    f('#brand_config\\[variables\\]\\[ic-brand-primary\\]')
  end

  def primary_button
    f('#brand_config\\[variables\\]\\[ic-brand-button--primary-bgd\\]')
  end

  def primary_button_text
    f('#brand_config\\[variables\\]\\[ic-brand-button--primary-text\\]')
  end

  def secondary_button
    f('#brand_config\\[variables\\]\\[ic-brand-button--secondary-bgd\\]')
  end

  def secondary_button_text
    f('#brand_config\\[variables\\]\\[ic-brand-button--secondary-text\\]')
  end

  def link_color
    f('#brand_config\\[variables\\]\\[ic-link-color\\]')
  end

  def nav_background
    f('#brand_config\\[variables\\]\\[ic-brand-global-nav-bgd\\]')
  end

  def nav_icon
    f('#brand_config\\[variables\\]\\[ic-brand-global-nav-ic-icon-svg-fill\\]')
  end

  def nav_icon_active
    f('#brand_config\\[variables\\]\\[ic-brand-global-nav-ic-icon-svg-fill--active\\]')
  end

  def nav_text
    f('#brand_config\\[variables\\]\\[ic-brand-global-nav-menu-item__text-color\\]')
  end

  def nav_text_active
    f('#brand_config\\[variables\\]\\[ic-brand-global-nav-menu-item__text-color--active\\]')
  end

  def nav_avatar_border
    f('#brand_config\\[variables\\]\\[ic-brand-global-nav-avatar-border\\]')
  end

  def nav_badge
    f('#brand_config\\[variables\\]\\[ic-brand-global-nav-menu-item__badge-bgd\\]')
  end

  def logo_background
    f('#brand_config\\[variables\\]\\[ic-brand-global-nav-logo-bgd\\]')
  end

  def window_title_color
    f('#brand_config\\[variables\\]\\[ic-brand-msapplication-tile-color\\]')
  end

  def all_global_branding
    [primary_color, primary_button, primary_button_text, secondary_button, secondary_button_text, link_color]
  end

  def all_global_navigation
    [nav_background,
     nav_icon,
     nav_icon_active,
     nav_text,
     nav_text_active,
     nav_avatar_border,
     nav_badge,
     logo_background]
  end

  def all_watermarks
    [window_title_color]
  end

  def all_colors(array, color = 'random')
    array.each do |x|
      x.send_keys(color == 'random' ? random_hex_color : color)
    end
  end

  def create_theme(color = 'random')
    click_global_branding
    all_colors(all_global_branding, color)

    click_global_navigation
    all_colors(all_global_navigation, color)

    click_watermarks_and_other_images
    all_colors(all_watermarks, color)
  end
end
