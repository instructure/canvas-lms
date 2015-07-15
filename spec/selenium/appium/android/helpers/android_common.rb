require_relative '../../mobile_common'

# ======================================================================================================================
# Log In / Out of Mobile App
# ======================================================================================================================

# Example:
# candroid_init(
#   :username => @teacher.primary_pseudonym.unique_id,
#   :password => @teacher.primary_pseudonym.unique_id,
#   :course => @android_course.name
# )
def candroid_init(opts = {})
  enter_school
  login_mobile(opts[:username], opts[:password])
  navigate_to_course(opts[:course].name) if opts[:course]
end

def enter_school
  find_element(:id, 'enterURL').send_keys(@school)
  find_element(:id, 'connect').click
end

def login_mobile(user, password)
  # 1st login view
  first_textfield.send_keys(user)
  last_textfield.send_keys(password)
  button('Log In').click

  # blocks until 2nd login view loads
  count = 0
  loop do
    break unless find_ele_by_attr('tags', 'android.view.View', 'name', /Cancel/).nil?
    count += 1
    raise 'access request login view did not load' if count > 5
  end
  button('Log In').click

  # Getting Started screen takes a second to animate in
  if exists(3){ find_element(:id, 'skip') }
    find_element(:id, 'skip').click
  end
end

# ======================================================================================================================
# Navigation
# ======================================================================================================================

def navigate_to_course(course)
  tags('android.widget.ImageButton')[0].click unless exists{ find_element(:id, 'scrollview') }
  find_element(:id, 'courses').click
  text_exact(course).click
end

def navigate_to(location)
  case location
  when 'Bookmarks', 'Grades', 'Inbox'
    hamburger = find_hamburger_icon
    hamburger.click unless hamburger.nil?
    scroll_view = find_element(:id, 'scrollview')
    scroll_vertically_in_view(scroll_view, 2000, 'down') unless exists{ text_exact(location) }
  else
    # location needs to differentiate between course grades in the navigation menu and grades in scroll view
    location = 'Grades' if location == 'Course_Grades'
    find_navigation_indicator.click
    list_view = tag('android.widget.ListView')
    scroll_vertically_in_view(list_view, 2000, 'down') unless exists{ text_exact(location) }
  end
  text_exact(location).click
end

def find_navigation_indicator
  return find_element(:id, 'indicator') if exists{ find_element(:id, 'indicator') }
  return find_element(:id, 'arrow') if exists{ find_element(:id, 'arrow') }
end

def find_hamburger_icon
  if exists{ find_element(:id, 'scrollview') }
    return nil
  else
    return tag('android.widget.ImageButton') # hamburger will always be the first image view returned
  end
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