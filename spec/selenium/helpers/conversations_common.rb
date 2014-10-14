require File.expand_path(File.dirname(__FILE__) + '/../common')

def conversation_setup
  course_with_teacher_logged_in

  term = EnrollmentTerm.new :name => "Super Term"
  term.root_account_id = @course.root_account_id
  term.save!

  @course.update_attributes! :enrollment_term => term

  @user.watched_conversations_intro
  @user.save
end

def new_conversation(reload=true)
  if reload
    get "/conversations"
    keep_trying_until { fj("#create_message_form form:visible") }
  else
    f("#action_compose_message").click
    wait_for_ajaximations
  end


  @input = fj("#create_message_form input:visible")
  @browser = fj("#create_message_form .browser:visible")
  @level = 1
  @elements = nil
end

def add_recipient(search, input_selector=".recipients")
  input = driver.execute_script("return $('#{input_selector}').data('token_input').$input[0]")
  input.send_keys(search)
  keep_trying_until { driver.execute_script("return $('#{input_selector}').data('token_input').selector.list.query.search") == search }
  wait_for_ajaximations
  input.send_keys(:return)
end

def browse_menu
  @browser.click
  wait_for_ajaximations(500)
  keep_trying_until { expect(ffj('.autocomplete_menu:visible .list').size).to eq @level }
  wait_for_ajaximations(500)
end

def browse(*names)
  name = names.shift
  @level += 1
  prev_elements = elements
  element = prev_elements.detect { |e| e.last == name } or raise "menu item does not exist"
  element.first.click
  wait_for_ajaximations(500)
  keep_trying_until { expect(ffj('.autocomplete_menu:visible .list').size).to eq @level }
  @elements = nil

  if names.present?
    browse(*names, &Proc.new)
  else
    yield
  end

  @level -= 1
  @elements = nil
  @input.send_keys(:arrow_left) unless ffj('.autocomplete_menu:visible .list').empty?
  sleep 1
end

def elements
  wait_for_js
  @elements = ffj(".autocomplete_menu:visible .list:last ul:last li").map { |e|
    [e, (e.find_element(:tag_name, :b).text rescue e.text)]
  }
end

def menu
  elements.map(&:last)
end

def toggleable
  with_class("toggleable")
end

def toggled
  with_class("on")
end

def with_class(klass)
  elements.select { |e| e.first.attribute('class') =~ /(\A| )#{klass}(\z| )/ }.map(&:last)
end

def click(name)
  element = elements.detect { |e| e.last == name } or raise "menu item does not exist"
  element.first.click
end

def toggle(name)
  element = elements.detect { |e| e.last == name } or raise "menu item does not exist"
  element.first.find_element(:class, 'toggle').click
end

def tokens
  ffj("#create_message_form .token_input li div").map(&:text)
end

def search(text, input_selector=".recipients")
  @input.send_keys(text)
  keep_trying_until { driver.execute_script("return $('#{input_selector}').data('token_input').selector.list.query.search") == text }
  wait_for_ajaximations
  @elements = nil
  yield
  @elements = nil
  if input_selector == ".recipients"
    @input.send_keys(*@input.attribute('value').size.times.map { :backspace })
    keep_trying_until do
      driver.execute_script("return $('.autocomplete_menu:visible').toArray();").size == 0 || driver.execute_script("return $('#{input_selector}').data('token_input').selector.list.query.search") == ''
    end
    wait_for_ajaximations
  end
end

def submit_message_form(opts={})
  opts[:message] ||= "Test Message"
  opts[:attachments] ||= []
  opts[:add_recipient] = true unless opts.has_key?(:add_recipient)
  opts[:group_conversation] = true unless opts.has_key?(:group_conversation)
  opts[:existing_conversation] = false unless opts.has_key?(:existing_conversation)

  if opts[:add_recipient] && browser = fj("#create_message_form .browser:visible")
    browser.click
    wait_for_ajaximations(500)
    fj('.autocomplete_menu .selectable:visible').click
    wait_for_ajaximations(500)
    fj('.autocomplete_menu .toggleable:visible .toggle').click
    wait_for_ajaximations(500)
    expect(ff('.token_input ul li').length).to be > 0
    fj("#create_message_form input:visible").send_keys("\t")
  end

  fj("#create_message_form textarea").send_keys(opts[:message])

  opts[:attachments].each_with_index do |fullpath, i|
    f(".action_add_attachment").click

    keep_trying_until { ffj("#create_message_form .file_input:visible")[i] }.send_keys(fullpath)
  end

  if opts[:media_comment]
    driver.execute_script <<-JS
        $("#create_message_form input[name=media_comment_id]").val(#{opts[:media_comment].first.inspect})
        $("#create_message_form input[name=media_comment_type]").val(#{opts[:media_comment].last.inspect})
        $("#create_message_form .media_comment").show()
        $("#create_message_form .action_media_comment").hide()
    JS
  end

  group_conversation_link = f(".group_conversation")
  group_conversation_link.click if group_conversation_link && group_conversation_link.displayed? && opts[:group_conversation]

  expect {
    submit_form('#create_message_form form')
    # file uploads can trigger multiple ajax requests, so we just wait for the
    # sent notification
    assert_message_status("sent", opts[:message][0, 10])
  }.to change(ConversationMessage, :count).by_at_least(opts[:group_conversation] ? 1 : ff('.token_input li').size)

  @elements = nil

  if opts[:group_conversation]
    message = ConversationMessage.last
    # whether the message should be visible depends on whether we were appending to an already visible conversation
    if opts[:existing_conversation]
      expect(f("#message_#{message.id}")).not_to be_nil
    else
      expect(f("#message_#{message.id}")).to be_nil
    end
    message
  end
end

def assert_message_status(status = "sent", text = '')
  wait_for_ajaximations
  keep_trying_until {
    e = ff('#message_status li').last
    expect(e.text.downcase).to include("#{status} #{text.downcase}") #rescue false
  }
end

def get_messages(load_convo = true, keep_trying = true)
  if load_convo
    get "/conversations"
    get_conversations.first.click
  end
  elements = nil
  keep_trying_until do
    elements = ff("div#messages > ul.messages > li")
    elements.size > 0
  end
  elements
end

def get_conversations(keep_trying = true)
  elements = nil
  keep_trying_until do
    elements = driver.execute_script("return $('#conversations .conversations > ul > li').not('.scrollable-list-item-loading,.scrollable-list-item-deleting,.scrollable-list-item-moving').toArray();")
    return elements unless keep_trying
    elements.size > 0
  end
  elements
end

def delete_selected_messages(confirm_conversation_deleted = true)
  orig_size = get_conversations.size

  wait_for_ajaximations(500)
  delete = f('#action_delete')
  expect(delete).to be_displayed
  delete.click
  driver.switch_to.alert.accept

  if confirm_conversation_deleted
    keep_trying_until { expect(get_conversations(false).size).to eq orig_size - 1 }
  end
end

