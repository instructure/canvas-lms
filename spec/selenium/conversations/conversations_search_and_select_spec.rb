require File.expand_path(File.dirname(__FILE__) + '/../helpers/conversations_common')

describe "conversations index page" do
  include_context "in-process server selenium tests"
  include ConversationsCommon

  before do
    conversation_setup
    @s1 = user_factory(name: "first student")
    @s2 = user_factory(name: "second student")
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
      conversations
      name = @s2.name
      f('[role=main] header [role=search] input').send_keys(name)
      fj(".ac-result:contains('#{name}')").click
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
      conversations
      select_conversations(2)
      expect(ff('.messages li.active').count).to eq 2
    end

    it "should select all conversations", priority: "1", test_id: 201462 do
      conversations
      f('#content').click # Ensures focus is in the window and not on the address bar
      driver.action.key_down(modifier)
        .send_keys('a')
        .key_up(modifier)
        .perform
      expect(ff('.messages li.active').count).to eq 3
    end

    it "should archive multiple conversations", priority: "1", test_id: 201490 do
      conversations
      select_conversations
      f('#archive-btn').click
      wait_for_ajaximations
      expect(f('.messages')).not_to contain_css('li')
      run_progress_job
      @conversations.each { |c| expect(c.reload).to be_archived }
    end

    it "should delete multiple conversations", priority: "1", test_id: 201491 do
      conversations
      select_conversations
      f('#delete-btn').click
      driver.switch_to.alert.accept
      wait_for_ajaximations
      expect(f('.messages')).not_to contain_css('li')
    end

    # TODO reimplement per CNVS-29601, but make sure we're testing at the right level
    it "should mark multiple conversations as unread"

    # TODO reimplement per CNVS-29602, but make sure we're testing at the right level
    it "should mark multiple conversations as unread"

    # TODO reimplement per CNVS-29603, but make sure we're testing at the right level
    it "should star multiple conversations"
  end
end
