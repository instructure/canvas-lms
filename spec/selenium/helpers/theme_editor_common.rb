require File.expand_path(File.dirname(__FILE__) + '/../common')

def open_theme_editor_with_btn
  fj('.btn.button-sidebar-wide').click
end

def open_theme_editor(account_id)
  get "/accounts/#{account_id}/theme_editor"
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

def single_warning_message
  f('.ic-Form-message--error')
end

def all_warning_messages
  ff('.ic-Form-message--error')
end

def click_global_branding
  f('div.accordion.ui-accordion--mini.Theme__editor-accordion.ui-accordion.ui-widget.ui-helper-reset > h3:first-child').click
  wait_for_ajaximations
end

def click_global_navigation
  f('div.accordion.ui-accordion--mini.Theme__editor-accordion.ui-accordion.ui-widget.ui-helper-reset > h3:nth-of-type(2)').click
  wait_for_ajaximations
end

def click_watermarks_and_other_images
  f('div.accordion.ui-accordion--mini.Theme__editor-accordion.ui-accordion.ui-widget.ui-helper-reset > h3:nth-of-type(3)').click
  wait_for_ajaximations
end

# finds a hex text input by its text label
# i.e. 'Primary Color'
def find_theme_text_input(text_label)
  js_string =
      "$('label').filter(function(){return $(this).text() === '#{text_label}'}).siblings('.Theme__editor-color-block').find('.Theme__editor-color-block_input-text')"
  driver.execute_script(js_string)
end

def primary_color(option = 'text_field')
  return f('div.accordion.ui-accordion--mini.Theme__editor-accordion.ui-accordion.ui-widget.ui-helper-reset > div:nth-of-type(1) > section:first-child > div.Theme__editor-form--color > div.Theme__editor-color-block > span > input.Theme__editor-color-block_input-text.Theme__editor-color-block_input') if option == 'text_field'
  return f('div.accordion.ui-accordion--mini.Theme__editor-accordion.ui-accordion.ui-widget.ui-helper-reset > div:nth-of-type(1) > section:first-child > div.Theme__editor-form--color > div.Theme__editor-color-block > label.Theme__editor-color-label.Theme__editor-color-block_label-sample') if option == 'color_box'
end

def primary_button(option = 'text_field')
  return f('div.accordion.ui-accordion--mini.Theme__editor-accordion.ui-accordion.ui-widget.ui-helper-reset > div:nth-of-type(1) > section:nth-of-type(2) > div.Theme__editor-form--color > div.Theme__editor-color-block > span > input.Theme__editor-color-block_input-text.Theme__editor-color-block_input') if option == 'text_field'
  return f('div.accordion.ui-accordion--mini.Theme__editor-accordion.ui-accordion.ui-widget.ui-helper-reset > div:nth-of-type(1) > section:nth-of-type(2) > div.Theme__editor-form--color > div.Theme__editor-color-block > label.Theme__editor-color-label.Theme__editor-color-block_label-sample') if option == 'color_box'
end

def primary_button_text(option = 'text_field')
  return f('div.accordion.ui-accordion--mini.Theme__editor-accordion.ui-accordion.ui-widget.ui-helper-reset > div:nth-of-type(1) > section:nth-of-type(3) > div.Theme__editor-form--color > div.Theme__editor-color-block > span > input.Theme__editor-color-block_input-text.Theme__editor-color-block_input') if option == 'text_field'
  return f('div.accordion.ui-accordion--mini.Theme__editor-accordion.ui-accordion.ui-widget.ui-helper-reset > div:nth-of-type(1) > section:nth-of-type(3) > div.Theme__editor-form--color > div.Theme__editor-color-block > label.Theme__editor-color-label.Theme__editor-color-block_label-sample') if option == 'color_box'
end

def secondary_button(option = 'text_field')
  return f('div.accordion.ui-accordion--mini.Theme__editor-accordion.ui-accordion.ui-widget.ui-helper-reset > div:nth-of-type(1) > section:nth-of-type(4) > div.Theme__editor-form--color > div.Theme__editor-color-block > span > input.Theme__editor-color-block_input-text.Theme__editor-color-block_input') if option == 'text_field'
  return f('div.accordion.ui-accordion--mini.Theme__editor-accordion.ui-accordion.ui-widget.ui-helper-reset > div:nth-of-type(1) > section:nth-of-type(4) > div.Theme__editor-form--color > div.Theme__editor-color-block > label.Theme__editor-color-label.Theme__editor-color-block_label-sample') if option == 'color_box'
end

def secondary_button_text(option = 'text_field')
  return f('div.accordion.ui-accordion--mini.Theme__editor-accordion.ui-accordion.ui-widget.ui-helper-reset > div:nth-of-type(1) > section:nth-of-type(5) > div.Theme__editor-form--color > div.Theme__editor-color-block > span > input.Theme__editor-color-block_input-text.Theme__editor-color-block_input') if option == 'text_field'
  return f('div.accordion.ui-accordion--mini.Theme__editor-accordion.ui-accordion.ui-widget.ui-helper-reset > div:nth-of-type(1) > section:nth-of-type(5) > div.Theme__editor-form--color > div.Theme__editor-color-block > label.Theme__editor-color-label.Theme__editor-color-block_label-sample') if option == 'color_box'
end

def link(option = 'text_field')
  return f('div.accordion.ui-accordion--mini.Theme__editor-accordion.ui-accordion.ui-widget.ui-helper-reset > div:nth-of-type(1) > section:nth-of-type(6) > div.Theme__editor-form--color > div.Theme__editor-color-block > span > input.Theme__editor-color-block_input-text.Theme__editor-color-block_input') if option == 'text_field'
  return f('div.accordion.ui-accordion--mini.Theme__editor-accordion.ui-accordion.ui-widget.ui-helper-reset > div:nth-of-type(1) > section:nth-of-type(6) > div.Theme__editor-form--color > div.Theme__editor-color-block > label.Theme__editor-color-label.Theme__editor-color-block_label-sample') if option == 'color_box'
end

def nav_background(option = 'text_field')
  return f('div.accordion.ui-accordion--mini.Theme__editor-accordion.ui-accordion.ui-widget.ui-helper-reset > div:nth-of-type(2) > section:first-child > div.Theme__editor-form--color > div.Theme__editor-color-block > span > input.Theme__editor-color-block_input-text.Theme__editor-color-block_input') if option == 'text_field'
  return f('div.accordion.ui-accordion--mini.Theme__editor-accordion.ui-accordion.ui-widget.ui-helper-reset > div:nth-of-type(2) > section:first-child > div.Theme__editor-form--color > div.Theme__editor-color-block > label.Theme__editor-color-label.Theme__editor-color-block_label-sample') if option == 'color_box'
end

def nav_icon(option = 'text_field')
  return f('div.accordion.ui-accordion--mini.Theme__editor-accordion.ui-accordion.ui-widget.ui-helper-reset > div:nth-of-type(2) > section:nth-of-type(2) > div.Theme__editor-form--color > div.Theme__editor-color-block > span > input.Theme__editor-color-block_input-text.Theme__editor-color-block_input') if option == 'text_field'
  return f('div.accordion.ui-accordion--mini.Theme__editor-accordion.ui-accordion.ui-widget.ui-helper-reset > div:nth-of-type(2) > section:nth-of-type(2) > div.Theme__editor-form--color > div.Theme__editor-color-block > label.Theme__editor-color-label.Theme__editor-color-block_label-sample') if option == 'color_box'
end

def nav_icon_active(option = 'text_field')
  return f('div.accordion.ui-accordion--mini.Theme__editor-accordion.ui-accordion.ui-widget.ui-helper-reset > div:nth-of-type(2) > section:nth-of-type(3) > div.Theme__editor-form--color > div.Theme__editor-color-block > span > input.Theme__editor-color-block_input-text.Theme__editor-color-block_input') if option == 'text_field'
  return f('div.accordion.ui-accordion--mini.Theme__editor-accordion.ui-accordion.ui-widget.ui-helper-reset > div:nth-of-type(2) > section:nth-of-type(3) > div.Theme__editor-form--color > div.Theme__editor-color-block > label.Theme__editor-color-label.Theme__editor-color-block_label-sample') if option == 'color_box'
end

def nav_text(option = 'text_field')
  return f('div.accordion.ui-accordion--mini.Theme__editor-accordion.ui-accordion.ui-widget.ui-helper-reset > div:nth-of-type(2) > section:nth-of-type(4) > div.Theme__editor-form--color > div.Theme__editor-color-block > span > input.Theme__editor-color-block_input-text.Theme__editor-color-block_input') if option == 'text_field'
  return f('div.accordion.ui-accordion--mini.Theme__editor-accordion.ui-accordion.ui-widget.ui-helper-reset > div:nth-of-type(2) > section:nth-of-type(4) > div.Theme__editor-form--color > div.Theme__editor-color-block > label.Theme__editor-color-label.Theme__editor-color-block_label-sample') if option == 'color_box'
end

def nav_text_active(option = 'text_field')
  return f('div.accordion.ui-accordion--mini.Theme__editor-accordion.ui-accordion.ui-widget.ui-helper-reset > div:nth-of-type(2) > section:nth-of-type(5) > div.Theme__editor-form--color > div.Theme__editor-color-block > span > input.Theme__editor-color-block_input-text.Theme__editor-color-block_input') if option == 'text_field'
  return f('div.accordion.ui-accordion--mini.Theme__editor-accordion.ui-accordion.ui-widget.ui-helper-reset > div:nth-of-type(2) > section:nth-of-type(5) > div.Theme__editor-form--color > div.Theme__editor-color-block > label.Theme__editor-color-label.Theme__editor-color-block_label-sample') if option == 'color_box'
end

def nav_avatar_border(option = 'text_field')
  return f('div.accordion.ui-accordion--mini.Theme__editor-accordion.ui-accordion.ui-widget.ui-helper-reset > div:nth-of-type(2) > section:nth-of-type(6) > div.Theme__editor-form--color > div.Theme__editor-color-block > span > input.Theme__editor-color-block_input-text.Theme__editor-color-block_input') if option == 'text_field'
  return f('div.accordion.ui-accordion--mini.Theme__editor-accordion.ui-accordion.ui-widget.ui-helper-reset > div:nth-of-type(2) > section:nth-of-type(6) > div.Theme__editor-form--color > div.Theme__editor-color-block > label.Theme__editor-color-label.Theme__editor-color-block_label-sample') if option == 'color_box'
end

def nav_badge(option = 'text_field')
  return f('div.accordion.ui-accordion--mini.Theme__editor-accordion.ui-accordion.ui-widget.ui-helper-reset > div:nth-of-type(2) > section:nth-of-type(7) > div.Theme__editor-form--color > div.Theme__editor-color-block > span > input.Theme__editor-color-block_input-text.Theme__editor-color-block_input') if option == 'text_field'
  return f('div.accordion.ui-accordion--mini.Theme__editor-accordion.ui-accordion.ui-widget.ui-helper-reset > div:nth-of-type(2) > section:nth-of-type(7) > div.Theme__editor-form--color > div.Theme__editor-color-block > label.Theme__editor-color-label.Theme__editor-color-block_label-sample') if option == 'color_box'
end

def logo_background(option = 'text_field')
  return f('div.accordion.ui-accordion--mini.Theme__editor-accordion.ui-accordion.ui-widget.ui-helper-reset > div:nth-of-type(2) > section:nth-of-type(8) > div.Theme__editor-form--color > div.Theme__editor-color-block > span > input.Theme__editor-color-block_input-text.Theme__editor-color-block_input') if option == 'text_field'
  return f('div.accordion.ui-accordion--mini.Theme__editor-accordion.ui-accordion.ui-widget.ui-helper-reset > div:nth-of-type(2) > section:nth-of-type(8) > div.Theme__editor-form--color > div.Theme__editor-color-block > label.Theme__editor-color-label.Theme__editor-color-block_label-sample') if option == 'color_box'
end

def window_title_color(option = 'text_field')
  return f('div.accordion.ui-accordion--mini.Theme__editor-accordion.ui-accordion.ui-widget.ui-helper-reset > div:nth-of-type(3) > section.Theme__editor-accordion_element.Theme__editor-color.ic-Form-control > div.Theme__editor-form--color > div.Theme__editor-color-block > span > input.Theme__editor-color-block_input-text.Theme__editor-color-block_input') if option == 'text_field'
  return f('div.accordion.ui-accordion--mini.Theme__editor-accordion.ui-accordion.ui-widget.ui-helper-reset > div:nth-of-type(3) > section.Theme__editor-accordion_element.Theme__editor-color.ic-Form-control > div.Theme__editor-form--color > div.Theme__editor-color-block > label.Theme__editor-color-label.Theme__editor-color-block_label-sample') if option == 'color_box'
end


def all_global_branding(option = 'text_field')
  [primary_color(option), primary_button(option), primary_button_text(option), secondary_button(option), secondary_button_text(option), link(option)]
end

def all_global_navigation(option = 'text_field')
  [nav_background(option), nav_icon(option), nav_icon_active(option), nav_text(option), nav_text_active(option), nav_avatar_border(option), nav_badge(option), logo_background(option)]
end

def all_watermarks(option = 'text_field')
  [window_title_color(option)]
end

def all_colors(array, color = 'random')
  array.each do |x|
    x.send_keys(color) if color != 'random'
    x.send_keys(random_hex_color) if color == 'random'
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