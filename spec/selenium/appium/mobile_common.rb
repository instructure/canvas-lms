require 'appium_lib'
require_relative '../common'
require_relative 'environment_setup'

include EnvironmentSetup

# ======================================================================================================================
# Appium
# ======================================================================================================================

def start_appium_driver
  Appium::Driver.new(caps: @capabilities, appium_lib: @appium_lib ).start_driver
  Appium.promote_appium_methods(RSpec::Core::ExampleGroup)
  set_wait(implicit_wait_time)

  @width = window_size.width
  @height = window_size.height
  @orientation = @width < @height ? 'portrait' : 'landscape'
end

def appium_init_android
  @capabilities = {
    platformName: 'Android',
    deviceName: android_device_name
  }
end

def appium_init_ios
  @capabilities = {
    platformName: 'iOS',
    versionNumber: ios_version,
    deviceName: ios_device_name,
    udid: ios_udid,
    app: ios_app_path
  }
end

def appium_init(platform_name)
  # @school = "#{host_url}:#{$server_port}"
  @school = 'twilson' # TODO: REMOVE WHEN MOBILE VERIFY SUPPORTS LOCAL ENVIRONMENT
  @appium_lib = { server_url: appium_server_url }
  case platform_name
  when 'Android'
    appium_init_android
  when 'iOS'
    appium_init_ios
  else
    raise('unsupported mobile platform')
  end
  start_appium_driver
end

# ======================================================================================================================
# Scrolling
# ======================================================================================================================

def scroll_to_element(opts = {})
  count = 0
  begin
    return find_element(:id, opts[:id])
  rescue
    count += 1
    scroll_vertically_in_view(opts[:scroll_view], opts[:time], opts[:direction])
    retry unless count > opts[:attempts]
  end
end

def scroll_vertically_in_view(scroll_view, time, direction)
  x = scroll_view.location.x + (0.5 * scroll_view.size.width)

  if direction == 'up'
    start_y = scroll_view.location.y + (0.1 * scroll_view.size.height)
    end_y = scroll_view.location.y + (0.9 * scroll_view.size.height)
  else
    start_y = scroll_view.location.y + (0.9 * scroll_view.size.height)
    end_y = scroll_view.location.y + (0.1 * scroll_view.size.height)
  end

  action = Appium::TouchAction.new.press(x: x, y: start_y).wait(time).move_to(x: x, y: end_y).release
  action.perform
end
