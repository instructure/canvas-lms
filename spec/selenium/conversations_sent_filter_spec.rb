require File.expand_path(File.dirname(__FILE__) + '/common')
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

    ConversationMessage.any_instance.stubs(:current_time_from_proper_timezone).returns(*100.times.to_a.reverse.map{ |h| Time.now.utc - h.hours })

    @c1 = conversation(@user, @s1)
    @c2 = conversation(@user, @s2)
    @c1.add_message('yay i sent this')
    @c2.conversation.add_message(@s2, "ohai im not u so this wont show up on the left")

    get "/conversations/sent"

    conversations = get_conversations
    conversations.first.attribute('data-id').should eql(@c1.conversation_id.to_s)
    conversations.first.text.should match(/yay i sent this/)
    conversations.last.attribute('data-id').should eql(@c2.conversation_id.to_s)
    conversations.last.text.should match(/test/)
  end

  it "should reorder based on last authored message" do
    get_conversations.last.click
    get_messages(false)

    submit_message_form(:message => "qwerty")

    conversations = get_conversations
    conversations.size.should eql 2
    conversations.first.text.should match(/qwerty/)
    conversations.last.text.should match(/yay i sent this/)
  end

  it "should remove the conversation when the last message by the author is deleted" do
    get_conversations.last.click

    msgs = get_messages(false)
    msgs.size.should == 2
    msgs.last.click

    delete_selected_messages
  end

  it "should show/update all conversations when sending a bulk private message" do
    @s3 = User.create(:name => "student3")
    @course1.enroll_user(@s3)

    new_conversation(false)
    add_recipient("student1")
    add_recipient("student2")
    add_recipient("student3")

    submit_message_form(:message => "ohai guys", :add_recipient => false, :group_conversation => false)

    conversations = get_conversations
    conversations.size.should eql 3
    conversations.each do |conversation|
      conversation.text.should match(/ohai guys/)
    end
  end
end
