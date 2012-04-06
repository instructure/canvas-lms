require File.expand_path(File.dirname(__FILE__) + '/common')
require File.expand_path(File.dirname(__FILE__) + '/conversations_common')

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

    conversations = find_all_with_jquery("#conversations > ul > li:visible")
    conversations.first.attribute('id').should eql("conversation_#{@c1.conversation_id}")
    conversations.first.text.should match(/yay i sent this/)
    conversations.last.attribute('id').should eql("conversation_#{@c2.conversation_id}")
    conversations.last.text.should match(/test/)
  end

  it "should reorder based on last authored message" do
    driver.find_element(:id, "conversation_#{@c2.conversation_id}").click
    wait_for_ajaximations

    submit_message_form(:message => "qwerty")

    conversations = find_all_with_jquery("#conversations > ul > li:visible")
    conversations.size.should eql 2
    conversations.first.text.should match(/qwerty/)
    conversations.last.text.should match(/yay i sent this/)
  end

  it "should remove the conversation when the last message by the author is deleted" do
    driver.find_element(:id, "conversation_#{@c2.conversation_id}").click
    wait_for_ajaximations

    msgs = driver.find_elements(:css, "div#messages ul.messages > li")
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

    conversations = find_all_with_jquery("#conversations > ul > li:visible")
    conversations.size.should eql 3
    conversations.each do |conversation|
      conversation.text.should match(/ohai guys/)
    end
  end
end
