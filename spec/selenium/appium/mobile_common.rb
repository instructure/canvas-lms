require 'appium_lib'
require_relative '../common'
require_relative 'environment_setup'

include EnvironmentSetup

shared_context 'appium mobile specs' do |platform_name|
  before(:all) do
    # specs are unable to start mobile app from any page, so if a spec fails
    # running any following specs is unsafe and will most like fail as well
    RSpec.configure do |c|
      c.fail_fast = true
    end
    create_developer_key
    @platform_name = platform_name # TODO: remove variable Jenkins doesn't like unused block arguments
    # appium_init(platform_name)   # TODO: uncomment to run Appium tests
    skip('Appium not yet integrated with Jenkins') # TODO: removed when Appium is integrated with Jenkins
  end
end

shared_context 'teacher and student users' do |platform_name|
  before(:all) do
    course(course_name: platform_name == 'Android' ? android_course_name : ios_course_name)
    @course.offer
    @teacher = user_with_pseudonym(username: 'teacher', unique_id: 'teacher', password: 'teacher', active_user: true)
    @student = user_with_pseudonym(username: 'student', unique_id: 'student', password: 'student', active_user: true)
    @course.enroll_user(@teacher, 'TeacherEnrollment').accept!
    @course.enroll_user(@student).accept!
  end
end

shared_context 'student user' do |platform_name|
  before(:all) do
    course_with_student(
      course_name: platform_name == 'Android' ? android_course_name : ios_course_name,
      user: user_with_pseudonym(username: 'student', password: 'student', active_user: true),
      active_all: true
    )
    candroid_init(@user.primary_pseudonym.unique_id, @user.primary_pseudonym.unique_id, @course.name)
  end

  after(:all) do
    logout(false)
  end
end

# ======================================================================================================================
# Appium
# ======================================================================================================================

def start_appium_driver
  Appium::Driver.new(caps: @capabilities, appium_lib: @appium_lib).start_driver
  Appium.promote_appium_methods(RSpec::Core::ExampleGroup)
  set_wait(implicit_wait_time)
end

def appium_init_android
  @capabilities = {
    platformName: 'Android',
    deviceName: android_device_name
  }
end

def appium_init_ios
  device = ios_device
  @capabilities = {
    platformName: 'iOS',
    versionNumber: device[:versionNumber],
    deviceName: device[:deviceName],
    udid: device[:udid],
    app: device[:app],
    autoAcceptAlerts: true,
    sendKeysStrategy: 'setValue'
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

def refresh_view(view)
  scroll_vertically_in_view(view, 2, 'up')
end
