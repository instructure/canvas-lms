require_relative '../../mobile_common'

# ======================================================================================================================
# Log In / Out of Mobile App
# ======================================================================================================================

def android_app_init(username, password, course_name)
  # check for multi-user access
  if (userlink = find_ele_by_attr('id', 'name', 'text', /#{username}/)).nil?
    enter_school
    login_mobile(username, password)
    navigate_to_course(course_name)
  else
    userlink.click
  end
end

def enter_school
  find_element(:id, 'enterURL').send_keys(@school)
  find_element(:id, 'connect').click

  # blocks until 1st login view loads
  wait_true(timeout: 10, interval: 0.250){ button_exact('Log In') }
end

def login_mobile(username, password)
  # 1st login view
  first_textfield.send_keys(username)
  last_textfield.send_keys(password)
  button('Log In').click

  # blocks until 2nd login view loads
  wait_true(timeout: 10, interval: 0.250){ find_ele_by_attr('tags', 'android.view.View', 'name', /Cancel/) }
  button('Log In').click
  skip_tutorial
end

def logout(add_account)
  candroid_app ? logout_android(add_account) : logout_speedgrader
end

def logout_android(add_account)
  open_hamburger
  find_element(:id, 'userNameContainer').click unless exists{ find_element(:id, 'logout') }
  if add_account
    find_element(:id, 'addAccount').click
  else
    find_element(:id, 'logout').click
    find_element(:id, 'dialog_custom_confirm').click
  end
  wait_true(timeout: 10, interval: 0.100){ find_element(:id, 'enterURL') }
end

def logout_speedgrader
  find_ele_by_attr('tag', 'android.widget.ImageButton', 'name', /(Open Drawer)/).click
  find_element(:id, 'logoutText').click
end

def skip_tutorial
  # Getting Started screen takes a second to animate in and out
  find_element(:id, 'skip').click if exists(3){ find_element(:id, 'skip') }
  if candroid_app
    wait_true(timeout:10, interval: 0.100){ find_element(:id, 'toolbar') }
  else
    wait_true(timeout:10, interval: 0.100){ find_element(:id, 'courseSwitcher') }
  end
end

# ======================================================================================================================
# Navigation
# ======================================================================================================================

# TODO: add support for speedgrader
def navigate_to_course(course_name)
  if candroid_app
    tags('android.widget.ImageButton')[0].click unless exists{ find_element(:id, 'scrollview') }
    find_element(:id, 'courses').click
    text_exact(course_name).click
  end
end

def navigate_to(location)
  case location
  when 'Bookmarks', 'Grades', 'Inbox'
    open_hamburger
    scroll_vertically_in_view(find_element(:id, 'scrollview'), 2000, 'down') unless exists{ text_exact(location) }
  else
    # location needs to differentiate between course grades in the navigation menu and grades in scroll view
    location = 'Grades' if location == 'Course_Grades'
    wait_true(timeout: 10, interval: 0.100){ find_navigation_indicator.click }
    list_view = tag('android.widget.ListView')
    scroll_vertically_in_view(list_view, 2000, 'down') unless exists{ text_exact(location) }
  end
  text_exact(location).click
end

def find_navigation_indicator
  return find_element(:id, 'indicator') if exists{ find_element(:id, 'indicator') }
  return find_element(:id, 'arrow') if exists{ find_element(:id, 'arrow') }
end

def open_hamburger
  # hamburger will always be the first image view returned
  tag('android.widget.ImageButton').click unless exists{ find_element(:id, 'scrollview') }
end

# ======================================================================================================================
# General
# ======================================================================================================================

def find_ele_by_attr(type, id, attribute, regex)
  elements = type == 'id' ? ids(id) : tags(id)
  elements.each do |element|
    case attribute
    when 'text'
      return element if element.text =~ regex
    when 'name'
      return element if element.name =~ regex
    else
      raise('unsupported option for finding element')
    end
  end
  nil
end

def press_keycodes(text)
  text.each_byte do |code|
    if code == 32
      press_keycode(62) # space
    else
      press_keycode(code - 68)
    end
  end
end

def wait_for_super_panda
  loop do
    break unless exists(0.250){ find_element(:id, 'pandaLoading') }
  end
end
