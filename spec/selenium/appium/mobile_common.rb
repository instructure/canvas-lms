require 'appium_lib'
require_relative 'environment_setup'

include EnvironmentSetup

# Mobile canvas and speedgrader apps have features that behave the same in both apps.
# Because each app still has its own test case in TestRails, this method chooses
# the proper test_id for examples that can be shared between app specs.
def pick_test_id_for_app(app_name, canvas, speedgrader)
  app_name =~ /(speedgrader)/ ? speedgrader : canvas
end

# ======================================================================================================================
# Shared Contexts and Helper Methods for Canvas Test Environment
# ======================================================================================================================

shared_context 'appium mobile specs' do |app_name|
  before(:all) do
    @app_name = app_name
    # appium_init(app_name) # TODO: uncomment to run Appium tests
    skip('Appium not yet integrated with Jenkins') # TODO: removed when Appium is integrated with Jenkins
    create_developer_key
    toggle_fail_fast(true)
  end

  after(:all) do
    toggle_fail_fast(false)
  end
end

shared_context 'teacher and student users' do |app_name|
  before(:all) do
    course(course_name: app_name =~ /(android)/ ? android_course_name : ios_course_name)
    @course.offer
    @teacher = user_with_pseudonym(username: 'teacher1', unique_id: 'teacher1', password: 'teacher', active_user: true)
    @student = user_with_pseudonym(username: 'student1', unique_id: 'student1', password: 'student', active_user: true)
    @course.enroll_user(@teacher, 'TeacherEnrollment').accept!
    @course.enroll_user(@student).accept!
  end
end

shared_context 'course with all user groups' do |app_name|
  before(:all) do
    course(course_name: app_name =~ /(android)/ ? android_course_name : ios_course_name)
    @course.offer
    @teacher = user_with_pseudonym(username: 'teacher1', unique_id: 'teacher1', password: 'teacher', active_user: true)
    @ta = user_with_pseudonym(username: 'assistant1', unique_id: 'assistant1', password: 'assistant', active_user: true)
    @students = []
    @observers = []
    5.times do |i|
      @students << user_with_pseudonym(username: "student#{i+1}", unique_id: "student#{i+1}", password: 'student', active_user: true)
      @observers << user_with_pseudonym(username: "observer#{i+1}", unique_id: "observer#{i+1}", password: 'observer', active_user: true)
      @course.enroll_user(@students[i]).accept!
      @course.enroll_user(@observers[i], 'ObserverEnrollment').accept!
    end
    @course.enroll_user(@teacher, 'TeacherEnrollment').accept!
    @course.enroll_user(@ta, 'TaEnrollment').accept!
  end
end

shared_context 'course with a single user' do |role, app_name|
  before(:all) do
    basic_course_setup(role, app_name)
    mobile_app_init(app_name)
  end

  after(:all) do
    logout(false)
  end
end

def basic_course_setup(role, app_name)
  case role
  when 'teacher'
    course_with_teacher(course_arguments(role, app_name))
  when 'student'
    course_with_student(course_arguments(role, app_name))
  else
    raise('Unsupported role for custom user shared context. Additional roles coming soon...')
  end
end

def course_arguments(role, app_name)
  { course_name: app_name =~ /(android)/ ? android_course_name : ios_course_name,
    user: user_with_pseudonym(username: role + '1', unique_id: role + '1', password: role, active_user: true),
    active_all: true }
end

def mobile_app_init(app_name)
  case app_name
  when 'candroid', 'speedgrader_android'
    android_app_init(@user.primary_pseudonym.unique_id, user_password(@user), @course.name)
  when 'icanvas', 'speedgrader_ios'
    icanvas_init(@user.primary_pseudonym.unique_id, user_password(@user), @course.name)
  else
    raise('Unsupported mobile application.')
  end
end

def user_password(user)
  user.primary_pseudonym.unique_id =~ /[a-z]+1/ ? user.primary_pseudonym.unique_id.sub(/[0-9]/, '') : user.primary_pseudonym.unique_id
end

def candroid_app
  @app_name == 'candroid'
end

def icanvas_app
  @app_name == 'icanvas'
end

def toggle_fail_fast(flag)
  # this tells rspec to not run remaining tests in the spec if a test fails
  # with mobile we can't guarantee the app is navigated to a specific location, so we fail quickly to not waste time
  RSpec.configure do |c|
    c.fail_fast = flag
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

def appium_init(app_name)
  @school = school_domain
  @appium_lib = { server_url: appium_server_url }
  case app_name
  when 'candroid', 'speedgrader_android'
    appium_init_android
  when 'icanvas', 'speedgrader_ios'
    appium_init_ios
  else
    raise('unsupported mobile platform')
  end
  start_appium_driver
end

# ======================================================================================================================
# Scrolling
# ======================================================================================================================

def scroll_to_element(opts)
  count = 0
  begin
    scroll_to_element_locator(opts)
  rescue Selenium::WebDriver::Error::NoSuchElementError
    scroll_vertically_in_view(opts[:scroll_view], opts[:time], opts[:direction])
    retry unless (count += 1) > opts[:attempts]
  end
end

def scroll_to_element_locator(opts)
  case opts[:strategy]
  when 'id'
    return find_element(:id, opts[:id])
  when 'tag'
    return tag(opts[:tag])
  when 'text_exact'
    return text_exact(opts[:text_exact])
  else
    raise('Unsupported locator strategy for scroll_to_element.')
  end
end

# Time is in milliseconds, so unless you want this to be a click send 1000 rather than 1
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
