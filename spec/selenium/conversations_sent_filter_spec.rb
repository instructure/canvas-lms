require File.expand_path(File.dirname(__FILE__) + '/helpers/conversations_common')

describe "conversations sent filter" do
  it_should_behave_like "in-process server selenium tests"
  it_should_behave_like "conversations selenium tests"

  before do
    @course.update_attribute(:name, "the course")
    @course1 = @course
    @s1 = User.create(:name => "student1")
    @s2 = User.create(:name => "student2")
    @course1.enroll_user(@s1)
    @course1.enroll_user(@s2)

    ConversationMessage.any_instance.stubs(:current_time_from_proper_timezone).returns(*100.times.to_a.reverse.map { |h| Time.now.utc - h.hours })

    @c1 = conversation(@user, @s1)
    @c2 = conversation(@user, @s2)
    @c1.add_message('yay i sent this')
    @c2.conversation.add_message(@s2, "ohai im not u so this wont show up on the left")

    get "/conversations/sent"

    conversations = get_conversations
    conversations.first.should have_attribute('data-id', @c1.conversation_id.to_s)
    conversations.first.should include_text('yay i sent this')
    conversations.last.should have_attribute('data-id', @c2.conversation_id.to_s)
    conversations.last.should include_text('test')
  end

  it "should reorder based on last authored message" do
    first_message_text = 'qwerty'
    get_conversations.last.click
    get_messages(false)

    submit_message_form(:message => first_message_text, :existing_conversation => true)

    ff(".last_author").length.should == 2
    ff(".last_author")[0].should include_text(first_message_text)
    ff(".last_author")[1].should include_text('yay i sent this')
  end

  it "should remove the conversation when the last message by the author is deleted" do
    get_conversations.last.click

    msgs = get_messages(false)
    msgs.size.should == 2
    msgs.last.click

    delete_selected_messages
  end

  it "should show/update all conversations when sending a bulk private message" do
    message_text = 'ohai guys'
    @s3 = User.create(:name => "student3")
    @course1.enroll_user(@s3)

    new_conversation(false)
    add_recipient("student1")
    add_recipient("student2")
    add_recipient("student3")

    ConversationBatch.any_instance.stubs(:mode).returns(:sync)
    submit_message_form(:message => message_text, :add_recipient => false, :group_conversation => false)

    conversations = get_conversations
    conversations.size.should == 3
    conversations.each { |conversation| conversation.should include_text(message_text) }
  end
end
