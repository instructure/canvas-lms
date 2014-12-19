require File.expand_path(File.dirname(__FILE__) + '/helpers/conversations_common')

describe "conversations new" do
  include_examples "in-process server selenium tests"

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
      @conv1 = conversation(@teacher, @s1)
      @conv2 = conversation(@teacher, @s2)
    end

    it "should allow finding messages by recipient" do
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
                        conversation(@teacher, @s1, @s2, workflow_state: 'read')]
    end

    def select_all_conversations
      driver.action.key_down(modifier).perform
      ff('.messages li').each do |message|
        message.click
      end
      driver.action.key_up(modifier).perform
    end

    it "should select multiple conversations" do
      get_conversations
      select_all_conversations
      expect(ff('.messages li.active').count).to eq 2
    end

    it "should select all conversations" do
      get_conversations
      driver.action.key_down(modifier)
        .send_keys('a')
        .key_up(modifier)
        .perform
      expect(ff('.messages li.active').count).to eq 2
    end

    it "should archive multiple conversations" do
      get_conversations
      select_all_conversations
      f('#archive-btn').click
      wait_for_ajaximations
      expect(conversation_elements.count).to eq 0
      run_progress_job
      @conversations.each { |c| expect(c.reload).to be_archived }
    end

    it "should delete multiple conversations" do
      get_conversations
      select_all_conversations
      f('#delete-btn').click
      driver.switch_to.alert.accept
      wait_for_ajaximations
      expect(conversation_elements.count).to eq 0
    end

    it "should mark multiple conversations as unread" do
      skip('breaks b/c jenkins is weird')
      get_conversations
      select_all_conversations
      click_unread_toggle_menu_item
      keep_trying_until { expect(ffj('.read-state[aria-checked=false]').count).to eq 2 }
    end

    it "should mark multiple conversations as unread" do
      skip('breaks b/c jenkins is weird')
      get_conversations
      select_all_conversations
      click_read_toggle_menu_item
      keep_trying_until { expect(ffj('.read-state[aria-checked=true]').count).to eq 2 }
    end

    it "should star multiple conversations" do
      skip('breaks b/c jenkins is weird')
      get_conversations
      select_all_conversations
      click_star_toggle_menu_item
      run_progress_job
      keep_trying_until { expect(ff('.star-btn.active').count).to eq 2 }
      @conversations.each { |c| expect(c.reload).to be_starred }
    end
  end
end