require_relative '../../mobile_common'

# ======================================================================================================================
# Log In / Out of Mobile App
# ======================================================================================================================

def icanvas_init(username, password, course_name)
  enter_school
  login_mobile(username, password)
  dismiss_user_polling
  navigate_to_course(course_name)
end

def enter_school
  find_ele_by_attr('UIATextField', 'value', 'Find your school or district').send_keys(@school)
  visible_buttons = buttons
  if visible_buttons.size == 1
    visible_buttons[0].click
  else
    visible_buttons[1].click
  end
  wait_true(timeout: 10, interval: 0.100){ tag('UIASecureTextField') }
end

def provide_credentials(username, password)
  email = tag('UIATextField')
  email.click
  email.send_keys(username)
  pw = tag('UIASecureTextField')
  pw.click
  pw.send_keys(password)
  button_exact('Log In').click
end

def login_mobile(username, password)
  provide_credentials(username, password)
  wait_true(timeout: 10, interval: 0.250){ text_exact('Canvas for iOS') }
  button_exact('Log In').click
end

# ==== Parameters
#    change_user: App settings for multi-user access must be enabled if change_user is true
#                 If multi-user is disabled, change_user must be false
def logout(change_user)
  if icanvas_app
    navigate_to('Logout')
    if change_user
      find_element(:id, 'Change User').click
    else
      find_elements(:id, 'Logout')[1].click
    end
  else # speedgrader
    first_button.click # hamburger
    find_element(:id, 'Logout').click
  end
end

# This assumes the app is on the landing page.
def logout_all_users
  while exists{ find_element(:id, 'icon x delete') }
    find_element(:id, 'icon x delete').click
  end
end

# ======================================================================================================================
# Navigation
# ======================================================================================================================

def goto_courses_root
  # tap twice to guarantee root view
  button_exact('Courses').click
  button_exact('Courses').click
end

# TODO: add support for Speedgrader
def navigate_to_course(course_name)
  if icanvas_app
    # Double tap should navigate to root courses view
    wait_true(timeout: 10, interval: 0.250){ button_exact('Courses') }
    goto_courses_root
    scroll_to_element(
      scroll_view: tag('UIACollectionView'),
      id: course_name,
      time: 1000,
      direction: 'down',
      attempts: 2
    ).click
  end
end

def navigate_to(location, opts = {course_name: ios_course_name})
  case location
  when 'My Files', 'About', 'Help', 'Logout'
    goto_courses_root
    find_element(:name, 'Profile').click
    find_element(:name, location).click
  when 'Calendar', 'To Do List', 'Notifications', 'Messages'
    button_exact(location).click
  else
    navigate_to_course(opts[:course_name])
    find_element(:name, location).click
  end
end

# ======================================================================================================================
# General
# ======================================================================================================================

def double_tap(element)
  element.click
  element.click
end

def device_is_iphone
  $appium_config[:ios_type] == 'iPhone'
end

def device_is_ipad
  $appium_config[:ios_type] == 'iPad'
end

def dismiss_user_polling
  begin
    find_element(:id, 'How do you like Canvas?')
    find_element(:id, 'Don\'t ask me again').click
  rescue => ex
    raise ex unless ex.is_a?(Selenium::WebDriver::Error::NoSuchElementError)
  end
end
