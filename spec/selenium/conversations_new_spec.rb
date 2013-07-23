require File.expand_path(File.dirname(__FILE__) + '/helpers/conversations_common')

describe "conversations new" do
  it_should_behave_like "in-process server selenium tests"

  def conversations_url
    "/conversations/beta"
  end

  def get_conversations
    get conversations_url
    wait_for_ajaximations
  end

  def conversation_elements
    ff('.messages > li')
  end

  def get_view_filter
    Selenium::WebDriver::Support::Select.new(f('.type-filter'))
  end

  def select_view(new_view)
    get_view_filter.select_by(:value, new_view)
    wait_for_ajaximations
  end

  before do
    # TODO: to work around temporary authentication restrictions
    ConversationsController.any_instance.stubs(:authorized_action).returns(true)
    conversation_setup
  end

  describe "view filter" do
    before do
      @s1 = user(name: "first student")
      @s2 = user(name: "second student")
      [@s1, @s2].each { |s| @course.enroll_student(s) }
      conversation(@teacher, @s1, @s2, workflow_state: 'unread')
      conversation(@teacher, @s1, @s2, workflow_state: 'read', starred: true)
      conversation(@teacher, @s1, @s2, workflow_state: 'archived', starred: true)
    end

    it "should default to inbox view" do
      get_conversations
      selected = get_view_filter.first_selected_option.should have_attribute('value', 'inbox')
      conversation_elements.size.should eql 2
    end

    it "should have an unread view" do
      get_conversations
      select_view('unread')
      conversation_elements.size.should eql 1
    end

    it "should have an starred view" do
      get_conversations
      select_view('starred')
      conversation_elements.size.should eql 2
    end

    it "should have an sent view" do
      get_conversations
      select_view('sent')
      conversation_elements.size.should eql 3
    end

    it "should have an archived view" do
      get_conversations
      select_view('archived')
      conversation_elements.size.should eql 1
    end

  end

end