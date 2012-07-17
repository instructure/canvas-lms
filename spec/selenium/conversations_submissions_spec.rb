require File.expand_path(File.dirname(__FILE__) + '/helpers/conversations_common')

describe "conversations submissions" do
  it_should_behave_like "in-process server selenium tests"
  it_should_behave_like "conversations selenium tests"

  it "should list submission comments in the conversation" do
    @me = @user
    @bob = student_in_course(:name => "bob", :active_all => true).user
    submission1 = submission_model(:course => @course, :user => @bob)
    submission2 = submission_model(:course => @course, :user => @bob)
    submission1.add_comment(:comment => "hey bob", :author => @me)
    submission1.add_comment(:comment => "wut up teacher", :author => @bob)
    submission2.add_comment(:comment => "my name is bob", :author => @bob)
    submission2.assignment.grade_student(@bob, {:grade => 0.9})
    conversation(@bob)
    get "/conversations"
    elements = nil
    keep_trying_until do
      elements = get_conversations
      elements.size == 1
    end
    elements.first.click
    wait_for_ajaximations
    subs = ff("div#messages .submission")
    subs.size.should == 2
    subs[0].find_element(:css, '.score').text.should == '0.9 / 1.5'
    subs[1].find_element(:css, '.score').text.should == 'no score'

    coms = subs[0].find_elements(:css, '.comment')
    coms.size.should == 1
    coms.first.find_element(:css, '.audience').text.should == 'bob'
    coms.first.find_element(:css, 'p').text.should == 'my name is bob'

    coms = subs[1].find_elements(:css, '.comment')
    coms.size.should == 2
    coms.first.find_element(:css, '.audience').text.should == 'bob'
    coms.first.find_element(:css, 'p').text.should == 'wut up teacher'
    coms.last.find_element(:css, '.audience').text.should == 'nobody@example.com'
    coms.last.find_element(:css, 'p').text.should == 'hey bob'
  end

  it "should interleave submissions with messages based on comment time" do
    SubmissionComment.any_instance.stubs(:current_time_from_proper_timezone).returns(10.minutes.ago, 8.minutes.ago)
    @me = @user
    @bob = student_in_course(:name => "bob", :active_all => true).user
    @conversation = conversation(@bob).conversation
    @conversation.conversation_messages.first.update_attribute(:created_at, 9.minutes.ago)
    submission1 = submission_model(:course => @course, :user => @bob)
    submission1.add_comment(:comment => "hey bob", :author => @me)

    # message comes first, then submission, due to creation times
    msgs = get_messages
    msgs.size.should == 2
    msgs[0].should have_class('message')
    msgs[1].should have_class('submission')

    # now new submission comment bumps it up
    submission1.add_comment(:comment => "hey teach", :author => @bob)
    msgs = get_messages
    msgs.size.should == 2
    msgs[0].should have_class('submission')
    msgs[1].should have_class('message')

    # new message appears on top, submission now in the middle
    @conversation.add_message(@bob, 'ohai there').update_attribute(:created_at, 7.minutes.ago)
    msgs = get_messages
    msgs.size.should == 3
    msgs[0].should have_class('message')
    msgs[1].should have_class('submission')
    msgs[2].should have_class('message')
  end

  it "should allow deleting submission messages from the conversation" do
    @me = @user
    @bob = student_in_course(:name => "bob", :active_all => true).user
    submission1 = submission_model(:course => @course, :user => @bob)
    submission1.add_comment(:comment => "hey teach", :author => @bob)
    @conversation = @me.conversations.first
    @conversation.should be_present

    msgs = get_messages
    msgs.size.should == 1
    msgs.first.click
    delete_selected_messages
    @conversation.reload
    @conversation.last_message_at.should be_nil
  end
end
