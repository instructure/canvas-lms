require File.expand_path(File.dirname(__FILE__) + '/../helpers/conversations_common')

describe "conversations new" do
  include_examples "in-process server selenium tests"

  before do
    conversation_setup
    add_students(3)
    @teacher.update_attribute(:name, 'Teacher')
  end

  describe "message list" do
    before(:each) do
      @participant = conversation(@teacher, @s[0], @s[1], body: 'hi there', workflow_state: 'unread')
      @convo = @participant.conversation
      @convo.update_attribute(:subject, 'test')
    end

    it "should display relevant information for messages", priority: "1", test_id: 86605 do
      # Normalizes time zone to be safe, in case user object and browser are not matching. Must do this
      # before page renders
      @teacher.time_zone = 'America/Juneau'
      @teacher.save!
      get_conversations
      expect(conversation_elements.size).to eq 1
      expect(f('li .author')).to include_text("#{@teacher.name}, #{@s[0].name}")
      expect(f('ul .read-state')).to be_present
      expect(f('li .subject')).to include_text('test')
      expect(f('li .summary')).to include_text('hi there')

      # We're interested in the element's attribute datetime for matching the timestamp
      rendered_time = f('time').attribute('datetime')

      # Gotta parse the times so they match, which includes removing the milliseconds by
      # converting both to integer
      # We do all this to test the time rendered on screen against the time the object was created
      expect(Time.zone.parse(rendered_time).to_i).to match(@participant.last_message_at.to_i)
    end

    it "should forward messages", priority: "1", test_id: 86608 do
      get_conversations
      message_count = @convo.conversation_messages.length
      conversation_elements.first.click
      wait_for_ajaximations

      # Tests forwarding messages via the top level More Options gear menu
      click_more_options(admin:true)
      forward_message(@s[2])
      expect(ffj('.message-item-view').length).to eq message_count += 1

      # Tests forwarding messages via the conversation level More Options gear menu
      click_more_options(convo:true)
      forward_message(@s[0])
      expect(ffj('.message-item-view').length).to eq message_count += 1

      # Tests forwarding messages via the message level More Options gear menu
      click_more_options({message:true}, 0)
      forward_message(@s[1])
      expect(ffj('.message-item-view').length).to eq message_count + 1
    end

    it "should display message count", priority: "1", test_id: 138897 do
      get_conversations
      expect(f('.message-count')).to include_text('1')

      select_view('sent')
      select_message(0)
      reply_to_message
      expect(f('.message-count')).to include_text('2')

      reply_to_message
      expect(f('.message-count')).to include_text('3')
    end
  end

  describe "view filter" do
    before do
      conversation(@teacher, @s[0], @s[1], workflow_state: 'unread')
      conversation(@teacher, @s[0], @s[1], workflow_state: 'read', starred: true)
      conversation(@teacher, @s[0], @s[1], workflow_state: 'archived', starred: true)
    end

    it "should default to inbox view", priority: "1", test_id: 86601 do
      get_conversations
      selected = expect(get_bootstrap_select_value(get_view_filter)).to eq 'inbox'
      expect(conversation_elements.size).to eq 2
    end

    it "should have an unread view", priority: "1", test_id: 197523 do
      get_conversations
      select_view('unread')
      expect(conversation_elements.size).to eq 1
    end

    it "should have an starred view", priority: "1", test_id: 197524 do
      get_conversations
      select_view('starred')
      expect(conversation_elements.size).to eq 2
    end

    it "should have an sent view", priority: "1", test_id: 197525 do
      get_conversations
      select_view('sent')
      expect(conversation_elements.size).to eq 3
    end

    it "should have an archived view", priority: "1", test_id: 197526 do
      get_conversations
      select_view('archived')
      expect(conversation_elements.size).to eq 1
    end

    it "should default to all courses context", priority: "1", test_id: 197527 do
      get_conversations
      selected = expect(get_bootstrap_select_value(get_course_filter)).to eq ''
      expect(conversation_elements.size).to eq 2
    end

    it "should truncate long course names", priority: "2", test_id: 197528 do
      @course.name = "this is a very long course name that will be truncated"
      @course.save!
      get_conversations
      select_course(@course.id)
      button_text = f('.filter-option', get_course_filter).text
      expect(button_text).not_to eq @course.name
      expect(button_text[0...5]).to eq @course.name[0...5]
      expect(button_text[-5..-1]).to eq @course.name[-5..-1]
    end

    it "should filter by course", priority: "1", test_id: 197529 do
      get_conversations
      select_course(@course.id)
      expect(conversation_elements.size).to eq 2
    end

    it "should filter by course plus view", priority: "1", test_id: 197530 do
      get_conversations
      select_course(@course.id)
      select_view('unread')
      expect(conversation_elements.size).to eq 1
    end

    it "should hide the spinner after deleting the last conversation", priority: "1", test_id: 207164 do
      get_conversations
      select_view('archived')
      expect(conversation_elements.size).to eq 1
      conversation_elements[0].click
      wait_for_ajaximations
      fj('#delete-btn').click
      driver.switch_to.alert.accept
      wait_for_ajaximations
      expect(conversation_elements.size).to eq 0
      expect(ffj('.message-list .paginatedLoadingIndicator:visible').length).to eq 0
      expect(ffj('.actions .btn-group button:disabled').size).to eq 4
    end
  end

  describe "starred" do
    before do
      @conv_unstarred = conversation(@teacher, @s[0], @s[1])
      @conv_starred = conversation(@teacher, @s[0], @s[1])
      @conv_starred.starred = true
      @conv_starred.save!
    end

    it "should star via star icon", priority: "1", test_id: 197532 do
      get_conversations
      unstarred_elt = conversation_elements[1]
      # make star button visible via mouse over
      driver.mouse.move_to(unstarred_elt)
      wait_for_ajaximations
      star_btn = f('.star-btn', unstarred_elt)
      expect(star_btn).to be_present
      expect(f('.active', unstarred_elt)).to be_nil

      star_btn.click
      wait_for_ajaximations
      expect(f('.active', unstarred_elt)).to be_present
      expect(@conv_unstarred.reload.starred).to be_truthy
    end

    it "should unstar via star icon", priority: "1", test_id: 197533 do
      get_conversations
      starred_elt = conversation_elements[0]
      star_btn = f('.star-btn', starred_elt)
      expect(star_btn).to be_present
      expect(f('.active', starred_elt)).to be_present

      star_btn.click
      wait_for_ajaximations
      expect(f('.active', starred_elt)).to be_nil
      expect(@conv_starred.reload.starred).to be_falsey
    end

    it "should star via gear menu", priority: "1", test_id: 197534 do
      get_conversations
      unstarred_elt = conversation_elements[1]
      unstarred_elt.click
      wait_for_ajaximations
      click_star_toggle_menu_item
      expect(f('.active', unstarred_elt)).to be_present
      run_progress_job
      expect(@conv_unstarred.reload.starred).to be_truthy
    end

    it "should unstar via gear menu", priority: "1", test_id: 197535 do
      get_conversations
      starred_elt = conversation_elements[0]
      starred_elt.click
      wait_for_ajaximations
      click_star_toggle_menu_item
      expect(f('.active', starred_elt)).to be_nil
      run_progress_job
      expect(@conv_starred.reload.starred).to be_falsey
    end
  end
end
