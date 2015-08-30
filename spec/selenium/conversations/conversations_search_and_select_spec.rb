require File.expand_path(File.dirname(__FILE__) + '/../helpers/conversations_common')

describe "conversations index page" do
  include_context "in-process server selenium tests"

  before do
    conversation_setup
    @s1 = user(name: "first student")
    @s2 = user(name: "second student")
    [@s1, @s2].each { |s| @course.enroll_student(s).update_attribute(:workflow_state, 'active') }
    cat = @course.group_categories.create(:name => "the groups")
    @group = cat.groups.create(:name => "the group", :context => @course)
    @group.users = [@s1, @s2]
  end

  describe "search" do
    before do
      @conv1 = conversation(@teacher, @s1,body:"adrian")
      @conv2 = conversation(@teacher, @s2,body:"roberto")
    end

    it "should allow finding messages by recipient", priority: "1", test_id: 197540 do
      get_conversations
      name = @s2.name
      f('[role=main] header [role=search] input').send_keys(name)
      keep_trying_until { fj(".ac-result:contains('#{name}')") }.click
      expect(conversation_elements.length).to eq 1
    end
  end

  describe "multi-select" do
    before(:each) do
      @conversations = [conversation(@teacher, @s1, @s2, workflow_state: 'read'),
                        conversation(@teacher, @s1, @s2, workflow_state: 'read'),
                        conversation(@teacher, @s1, @s2, workflow_state: 'read')]
    end

    it "should select multiple conversations", priority: "1", test_id: 201429 do
      get_conversations
      select_conversations(2)
      expect(ff('.messages li.active').count).to eq 2
    end

    it "should select all conversations", priority: "1", test_id: 201462 do
      get_conversations
      driver.action.key_down(modifier)
        .send_keys('a')
        .key_up(modifier)
        .perform
      expect(ff('.messages li.active').count).to eq 3
    end

    it "should archive multiple conversations", priority: "1", test_id: 201490 do
      get_conversations
      select_conversations
      f('#archive-btn').click
      wait_for_ajaximations
      expect(conversation_elements.count).to eq 0
      run_progress_job
      @conversations.each { |c| expect(c.reload).to be_archived }
    end

    it "should delete multiple conversations", priority: "1", test_id: 201491 do
      get_conversations
      select_conversations
      f('#delete-btn').click
      driver.switch_to.alert.accept
      wait_for_ajaximations
      expect(conversation_elements.count).to eq 0
    end

    it "should mark multiple conversations as unread" do
      skip('breaks b/c jenkins is weird')
      get_conversations
      select_conversations
      click_unread_toggle_menu_item
      keep_trying_until { expect(ffj('.read-state[aria-checked=false]').count).to eq 3 }
    end

    it "should mark multiple conversations as unread" do
      skip('breaks b/c jenkins is weird')
      get_conversations
      select_conversations
      click_read_toggle_menu_item
      keep_trying_until { expect(ffj('.read-state[aria-checked=true]').count).to eq 3 }
    end

    it "should star multiple conversations" do
      skip('breaks b/c jenkins is weird')
      get_conversations
      select_conversations
      click_star_toggle_menu_item
      run_progress_job
      keep_trying_until { expect(ff('.star-btn.active').count).to eq 3 }
      @conversations.each { |c| expect(c.reload).to be_starred }
    end
  end
end