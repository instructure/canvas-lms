require File.expand_path(File.dirname(__FILE__) + '/../common')

def open_theme_editor_with_btn
  fj('.btn.button-sidebar-wide').click
end

def open_theme_editor
  get '/brand_configs/new'
  wait_for_ajaximations
end

# the close mechanism only works with beta and not with how it is in master
def close_theme_editor
  fj('button:contains("Cancel")').click
end

def select_template(template)
  # "Canvas Default" "K12 Theme"
  select_list = Selenium::WebDriver::Support::Select.new(fj('#sharedThemes'))
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

def click_global_branding
  f('h3.ui-accordion-header.ui-helper-reset.ui-state-default.ui-accordion-icons.ui-corner-top > a > div.te-Flex > span.te-Flex__block').click
  wait_for_ajaximations
end

def click_global_navigation
  f('div.accordion.ui-accordion--mini.Theme__editor-accordion.ui-accordion.ui-widget.ui-helper-reset > h3:nth-of-type(2) > a > div.te-Flex > span.te-Flex__block').click
  wait_for_ajaximations
end

def click_watermarks_and_other_images
  f('div.accordion.ui-accordion--mini.Theme__editor-accordion.ui-accordion.ui-widget.ui-helper-reset > h3:nth-of-type(3) > a > div.te-Flex > span.te-Flex__block').click
  wait_for_ajaximations
end

def primary_color(color)
  f('div.accordion.ui-accordion--mini.Theme__editor-accordion.ui-accordion.ui-widget.ui-helper-reset > div:nth-of-type(1) > section:first-child > div.Theme__editor-form--color > div.Theme__editor-color-block > span > input.Theme__editor-color-block_input-text.Theme__editor-color-block_input').send_keys(color)
end

def primary_button(color)
  f('div.accordion.ui-accordion--mini.Theme__editor-accordion.ui-accordion.ui-widget.ui-helper-reset > div:nth-of-type(1) > section:nth-of-type(2) > div.Theme__editor-form--color > div.Theme__editor-color-block > span > input.Theme__editor-color-block_input-text.Theme__editor-color-block_input').send_keys(color)
end

def primary_button_text(color)
  f('div.accordion.ui-accordion--mini.Theme__editor-accordion.ui-accordion.ui-widget.ui-helper-reset > div:nth-of-type(1) > section:nth-of-type(3) > div.Theme__editor-form--color > div.Theme__editor-color-block > span > input.Theme__editor-color-block_input-text.Theme__editor-color-block_input').send_keys(color)
end

def secondary_button(color)
  f('div.accordion.ui-accordion--mini.Theme__editor-accordion.ui-accordion.ui-widget.ui-helper-reset > div:nth-of-type(1) > section:nth-of-type(4) > div.Theme__editor-form--color > div.Theme__editor-color-block > span > input.Theme__editor-color-block_input-text.Theme__editor-color-block_input').send_keys(color)
end

def secondary_button_text(color)
  f('div.accordion.ui-accordion--mini.Theme__editor-accordion.ui-accordion.ui-widget.ui-helper-reset > div:nth-of-type(1) > section:nth-of-type(5) > div.Theme__editor-form--color > div.Theme__editor-color-block > span > input.Theme__editor-color-block_input-text.Theme__editor-color-block_input').send_keys(color)
end

def link(color)
  f('div.accordion.ui-accordion--mini.Theme__editor-accordion.ui-accordion.ui-widget.ui-helper-reset > div:nth-of-type(1) > section:nth-of-type(6) > div.Theme__editor-form--color > div.Theme__editor-color-block > span > input.Theme__editor-color-block_input-text.Theme__editor-color-block_input').send_keys(color)
end

def nav_background(color)
  f('div.accordion.ui-accordion--mini.Theme__editor-accordion.ui-accordion.ui-widget.ui-helper-reset > div:nth-of-type(2) > section:first-child > div.Theme__editor-form--color > div.Theme__editor-color-block > span > input.Theme__editor-color-block_input-text.Theme__editor-color-block_input').send_keys(color)
end

def nav_icon(color)
  f('div.accordion.ui-accordion--mini.Theme__editor-accordion.ui-accordion.ui-widget.ui-helper-reset > div:nth-of-type(2) > section:nth-of-type(2) > div.Theme__editor-form--color > div.Theme__editor-color-block > span > input.Theme__editor-color-block_input-text.Theme__editor-color-block_input').send_keys(color)
end

def nav_icon_active(color)
  f('div.accordion.ui-accordion--mini.Theme__editor-accordion.ui-accordion.ui-widget.ui-helper-reset > div:nth-of-type(2) > section:nth-of-type(3) > div.Theme__editor-form--color > div.Theme__editor-color-block > span > input.Theme__editor-color-block_input-text.Theme__editor-color-block_input').send_keys(color)
end

def nav_text(color)
  f('div.accordion.ui-accordion--mini.Theme__editor-accordion.ui-accordion.ui-widget.ui-helper-reset > div:nth-of-type(2) > section:nth-of-type(4) > div.Theme__editor-form--color > div.Theme__editor-color-block > span > input.Theme__editor-color-block_input-text.Theme__editor-color-block_input').send_keys(color)
end

def nav_text_active(color)
  f('div.accordion.ui-accordion--mini.Theme__editor-accordion.ui-accordion.ui-widget.ui-helper-reset > div:nth-of-type(2) > section:nth-of-type(5) > div.Theme__editor-form--color > div.Theme__editor-color-block > span > input.Theme__editor-color-block_input-text.Theme__editor-color-block_input').send_keys(color)
end

def nav_avatar_border(color)
  f('div.accordion.ui-accordion--mini.Theme__editor-accordion.ui-accordion.ui-widget.ui-helper-reset > div:nth-of-type(2) > section:nth-of-type(6) > div.Theme__editor-form--color > div.Theme__editor-color-block > span > input.Theme__editor-color-block_input-text.Theme__editor-color-block_input').send_keys(color)
end

def nav_badge(color)
  f('div.accordion.ui-accordion--mini.Theme__editor-accordion.ui-accordion.ui-widget.ui-helper-reset > div:nth-of-type(2) > section:nth-of-type(7) > div.Theme__editor-form--color > div.Theme__editor-color-block > span > input.Theme__editor-color-block_input-text.Theme__editor-color-block_input').send_keys(color)
end

def logo_background(color)
  f('div.accordion.ui-accordion--mini.Theme__editor-accordion.ui-accordion.ui-widget.ui-helper-reset > div:nth-of-type(2) > section:nth-of-type(8) > div.Theme__editor-form--color > div.Theme__editor-color-block > span > input.Theme__editor-color-block_input-text.Theme__editor-color-block_input').send_keys(color)
end

def window_title_color(color)
  f('div.accordion.ui-accordion--mini.Theme__editor-accordion.ui-accordion.ui-widget.ui-helper-reset > div:nth-of-type(3) > section.Theme__editor-accordion_element.Theme__editor-color.ic-Form-control > div.Theme__editor-form--color > div.Theme__editor-color-block > span > input.Theme__editor-color-block_input-text.Theme__editor-color-block_input').send_keys(color)
end