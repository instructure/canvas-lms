require_relative 'conversations_common'

describe 'conversations inbox' do
  include_context 'in-process server appium tests'
  include_context 'appium mobile specs', 'candroid'
  include_context 'teacher and student users', 'candroid'

  context 'student as the sender' do
    let(:sender){ @student.primary_pseudonym.unique_id }
    let(:recipient){ @teacher.primary_pseudonym.unique_id }
    let(:recipient_role){ 'teacher' }

    before(:all) do
      android_app_init(@student.primary_pseudonym.unique_id, user_password(@student), @course.name)
    end

    before(:each) do
      navigate_to('Inbox')
      click_object('compose')
    end

    after(:each) do
      # use this over *back*; this will clear out previously entered recipients, *back* will not
      find_ele_by_attr('tag', 'android.widget.ImageButton', 'name', /(Navigate up)/).click
    end

    after(:all) do
      logout(false)
    end

    # taps the compose button (buttom right) and verifies a new message form is displayed
    it 'has a working compose button', priority: "1", test_id: 18399 do
      expect(find_ele_by_attr('tag', 'android.widget.ImageButton', 'name', /(Navigate up)/)).to be_displayed
      expect(text_exact('Compose Message')).to be_displayed
      expect(find_element(:id, 'menu_send')).to be_displayed
      expect(text_exact('Select a course')).to be_displayed
      expect(find_element(:id, 'subject')).to be_displayed
      expect(text_exact('Compose Message')).to be_displayed
    end

    # uses course menu dropdown rather than manually typing the course
    it 'selects a course', priority: "1", test_id: 220022 do
      expect(exists{ find_element(:id, 'menu_choose_recipients') }).to be false
      select_recipient_course
      expect(exists{ find_element(:id, 'menu_choose_recipients') }).to be true
    end

    it 'adds recipient using recipient menu', priority: "1", test_id: 220024 do
      select_recipient_course
      select_recipient_from_menu(recipient, recipient_role)

      # actual text of recipient field encapsulates entries with "< >"
      expect(find_element(:id, 'recipient').text).to match(recipient_list_matcher)
    end

    it 'adds recipient with auto-populated response', priority: "1", test_id: 18400 do
      select_recipient_course
      expect(auto_populate_recipient(recipient)).to be true
    end

    it 'enters a subject line', priority: "1", test_id: 18401 do
      expect(find_element(:id, 'subject').text).to eq('Subject')
      enter_subject(student_subject)
      expect(find_element(:id, 'subject').text).to eq(student_subject)
    end

    it 'enters a message body', priority: "1", test_id: 369247 do
      expect(find_element(:id, 'message').text).to eq('Compose Message')
      enter_message(student_message)
      expect(find_element(:id, 'message').text).to eq(student_message)
    end

    it 'sends a message', priority: "1", test_id: 18403 do
      # sending the email closes the form and displays the inbox view
      send_message(recipient, recipient_role, student_subject, student_message)
      expect(find_element(:id, 'compose')).to be_displayed
    end
  end
end
