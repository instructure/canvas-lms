require_relative '../../helpers/android_common'

# types a single character until auto-fill generates target recipient
# then selects auto-populated recipient
def auto_populate_recipient(name)
  email_field = find_element(:id, 'recipient')
  substring = ''
  name.each_char do |char|
    substring += char
    email_field.send_keys(substring)

    # auto-populated recipients will appear immediately below the email textfield object
    # tap the location where recipient will appear
    action = Appium::TouchAction.new.tap(x: 0.5 * window_size.width,
                                         y: (email_field.location.y + email_field.size.height) + (0.5 * email_field.size.height))
    action.perform

    # if recipient was auto-populated, the tap should have selected them
    # check if email textfield reflects a successful auto-population; keep trying if unsuccessful
    if email_field.text =~ recipient_list_matcher
      # auto-population on last character of input string does not count... fail
      return true unless char == name[-1, 1]
      break
    end
  end
  return false
end

# clicking compose button, for unknown reason, FAILS
# this method attempts to open the form several times before giving up
# this usually works on the second attempt
def click_object(obj)
  if obj == 'compose'
    click_compose_button
  elsif obj == 'sent'
    click_sent_tab
  else
    raise('Unsupported option for click_object. Expecting \'compose\' or \'sent\'')
  end
end

def click_compose_button
  attempts = 0
  loop do
    if find_ele_by_attr('tag', 'android.widget.ImageButton', 'name', /(Navigate up)/) != nil
      break
    elsif (attempts += 1) > 5
      raise('Unable to open compose message form.')
    else
      find_element(:id, 'compose').click
    end
  end
end

def click_sent_tab
  attempts = 0
  loop do
    if find_ele_by_attr('tag', 'android.widget.TextView', 'text', /(Sent)/).selected?
      break
    elsif (attempts += 1) > 5
      raise('Unable to open sent tab.')
    else
      text_exact('Sent').click
    end
  end
end

def enter_subject(subject)
  subject_field = find_element(:id, 'subject')
  subject_field.send_keys(subject)
end

def enter_message(message)
  message_field = find_element(:id, 'message')
  message_field.send_keys(message)
end

# only matches for a single recipient; does not match multiple recipients
def recipient_list_matcher
  return /(^<#{recipient}>)(,.)$/
end

def send_message(recipient, recipient_role, subject, message)
  select_recipient_course
  select_recipient_from_menu(recipient, recipient_role)
  enter_subject(subject)
  enter_message(message)
  find_element(:id, 'menu_send').click
end

def select_recipient_course
  find_element(:id, 'course_spinner').click
  text_exact(@course.name).click
end

def select_recipient_from_menu(recipient, recipient_role)
  # possible recipients are organized by user role
  find_element(:id, 'menu_choose_recipients').click
  select_user_group(recipient_role)
  text_exact(recipient).click
  find_element(:id, 'menu_done').click
end

def select_user_group(group)
  case group
  when 'teacher'
    text_exact('Teachers').click
  when 'ta'
    text_exact('Teaching Assistants').click
  when 'student'
    text_exact('Students').click
  when 'observer'
    text_exact('Observers').click
  else
    raise('Invalid user group selected.')
  end
end

def student_subject
  'Final Grades'
end

def student_message
  'Will I pass this class?'
end
