shared_examples_for "conversations selenium tests" do
  before(:each) do
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
      keep_trying_until { fj("#create_message_form:visible") }
    else
      driver.find_element(:id, "action_compose_message").click
    end

    @input = find_with_jquery("#create_message_form input:visible")
    @browser = find_with_jquery("#create_message_form .browser:visible")
    @level = 1
    @elements = nil
  end

  def add_recipient(search, input_id = "recipients")
    input = driver.execute_script("return $('\##{input_id}').data('token_input').$input[0]")
    input.send_keys(search)
    keep_trying_until { driver.execute_script("return $('\##{input_id}').data('token_input').selector.lastSearch") == search }
    input.send_keys(:return)
  end

  def browse_menu
    @browser.click
    keep_trying_until {
      find_all_with_jquery('.autocomplete_menu:visible .list').size.should eql(@level)
    }
    wait_for_animations
  end

  def browse(*names)
    name = names.shift
    @level += 1
    prev_elements = elements
    element = prev_elements.detect { |e| e.last == name } or raise "menu item does not exist"

    element.first.click
    wait_for_ajaximations(150)
    keep_trying_until {
      find_all_with_jquery('.autocomplete_menu:visible .list').size.should eql(@level)
    }

    @elements = nil
    elements

    if names.present?
      browse(*names, &Proc.new)
    else
      yield
    end

    @level -= 1
    @elements = @level == 1 ? nil : prev_elements
    @input.send_keys(:arrow_left) unless ffj('.autocomplete_menu:visible .list').empty?
    wait_for_animations
  end

  def elements
    @elements ||= driver.execute_script("return $('.autocomplete_menu:visible .list').last().find('ul').last().find('li').toArray();").map { |e|
      [e, (e.find_element(:tag_name, :b).text rescue e.text)]
    }
  end

  def menu
    elements.map(&:last)
  end

  def toggled
    elements.select { |e| e.first.attribute('class') =~ /(^| )on($| )/ }.map(&:last)
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
    find_all_with_jquery("#create_message_form .token_input li div").map(&:text)
  end

  def search(text, input_id="recipients")
    @input.send_keys(text)
    keep_trying_until do
      driver.execute_script("return $('\##{input_id}').data('token_input').selector.lastSearch") == text
    end
    @elements = nil
    yield
    @elements = nil
    if input_id == "recipients"
      @input.send_keys(*@input.attribute('value').size.times.map { :backspace })
      keep_trying_until do
        driver.execute_script("return $('.autocomplete_menu:visible').toArray();").size == 0 ||
            driver.execute_script("return $('\##{input_id}').data('token_input').selector.lastSearch") == ''
      end
    end
  end

  def submit_message_form(opts={})
    opts[:message] ||= "Test Message"
    opts[:attachments] ||= []
    opts[:add_recipient] = true unless opts.has_key?(:add_recipient)
    opts[:group_conversation] = true unless opts.has_key?(:group_conversation)

    if opts[:add_recipient] && browser = find_with_jquery("#create_message_form .browser:visible")
      browser.click
      wait_for_ajaximations(150)
      find_with_jquery('.autocomplete_menu .selectable:visible').click
      wait_for_ajaximations(150)
      find_with_jquery('.autocomplete_menu .toggleable:visible .toggle').click
      wait_for_ajaximations
      driver.find_elements(:css, '.token_input ul li').length.should > 0
      find_with_jquery("#create_message_form input:visible").send_keys("\t")
    end

    find_with_jquery("#create_message_form textarea").send_keys(opts[:message])

    opts[:attachments].each_with_index do |fullpath, i|
      driver.find_element(:id, "action_add_attachment").click

      keep_trying_until {
        find_all_with_jquery("#create_message_form .file_input:visible")[i]
      }.send_keys(fullpath)
    end

    if opts[:media_comment]
      driver.execute_script <<-JS
        $("#media_comment_id").val(#{opts[:media_comment].first.inspect})
        $("#media_comment_type").val(#{opts[:media_comment].last.inspect})
        $("#create_message_form .media_comment").show()
        $("#action_media_comment").hide()
      JS
    end

    group_conversation_link = driver.find_element(:id, "group_conversation")
    group_conversation_link.click if group_conversation_link.displayed? && opts[:group_conversation]

    expect {
      # ensure that we've focused on the button, since file inputs go away
      submit_form('#create_message_form')
      # file uploads can trigger multiple ajax requests, so we just wait for stuff to get reenabled
      keep_trying_until{ f('#create_message_form textarea').enabled? }
    }.to change(ConversationMessage, :count).by(opts[:group_conversation] ? 1 : ff('.token_input li').size)

    if opts[:group_conversation]
      message = ConversationMessage.last
      f("#message_#{message.id}").should_not be_nil
      message
    end
  end

  def get_messages(load_convo = true, keep_trying = true)
    if load_convo
      get "/conversations"
      get_conversations.first.click
    end
    elements = nil
    keep_trying_until {
      elements = ff("div#messages > ul.messages > li")
      elements.size > 0
    }
    elements
  end

  def get_conversations(keep_trying = true)
    elements = nil
    keep_trying_until {
      elements = driver.execute_script("return $('#conversations .conversations > ul > li').not('.scrollable-list-item-loading,.scrollable-list-item-deleting,.scrollable-list-item-moving').toArray();")
      return elements unless keep_trying
      elements.size > 0
    }
    elements
  end

  def delete_selected_messages(confirm_conversation_deleted = true)
    orig_size = get_conversations.size

    wait_for_animations
    delete = driver.find_element(:id, 'action_delete')
    delete.should be_displayed
    delete.click
    driver.switch_to.alert.accept

    if confirm_conversation_deleted
      keep_trying_until {
        get_conversations(false).size.should eql(orig_size - 1)
      }
    end
  end

  def conversations_path(params={})
    hash = params.to_json.unpack('H*').first
    "/conversations##{hash}"
  end
end
