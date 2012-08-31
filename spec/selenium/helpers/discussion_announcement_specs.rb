require File.expand_path(File.dirname(__FILE__) + '/../common')
require File.expand_path(File.dirname(__FILE__) + '/../helpers/discussions_common')

shared_examples_for "discussion and announcement main page tests" do
  it_should_behave_like "in-process server selenium tests"

  before (:each) do
    @context = @course
    5.times do |i|
      title = "new #{i.to_s.rjust(3, '0')}"
      what_to_create == DiscussionTopic ? @course.discussion_topics.create!(:title => title, :user => @user) : announcement_model(:title => title, :user => @user)
    end
    get url
    wait_for_ajaximations
    @checkboxes = ff('.toggleSelected')
  end

  it "shouldn't allow users without permission to delete/lock an announcement" do
    pending('need to log in as otherUser')
    @otherUser = User.create!(:name => 'karl')
    @otherUser.register!
    @otherUser.pseudonyms.create!(:unique_id => "nobody1@example.com", :password => 'foobarbaz1234', :password_confirmation => 'foobarbaz1234')
    e = @course.enroll_student(@otherUser)
    e.workflow_state = 'active'
    e.save!
    what_to_create == DiscussionTopic ? @course.discussion_topics.create!(:title => 'other users', :user => @otherUser) : announcement_model(:title => 'other users', :user => @otherUser)
    get url
    wait_for_ajaximations
    checkboxes = ff('.toggleSelected')
    checkboxes.length.should == 1
    ff('.discussion-topic').length.should == 6
  end

  def update_attributes_and_validate(attribute, update_value, search_term = update_value, expected_results = 1)
    what_to_create.last.update_attributes(attribute => update_value)
    refresh_page # in order to get the new topic information
    replace_content(f('#searchTerm'), search_term)
    ff('.discussionTopicIndexList .discussion-topic').count.should == expected_results
  end

  def refresh_and_filter(filter_type, filter, expected_text, expected_results = 1)
    refresh_page # in order to get the new topic information
    wait_for_ajax_requests
    filter_type == :css ? f(filter).click : replace_content(f('#searchTerm'), filter)
    ff('.discussionTopicIndexList .discussion-topic').count.should == expected_results
    expected_results > 1 ? ff('.discussionTopicIndexList .discussion-topic').each { |topic| topic.should include_text(expected_text) } : (f('.discussionTopicIndexList .discussion-topic').should include_text(expected_text))
  end

  it "should bulk delete topics" do
    5.times { |i| @checkboxes[i].click }
    f('#delete').click
    driver.switch_to.alert.accept
    wait_for_ajax_requests
    ff('.discussion-topic').count.should == 0
    what_to_create.where(:workflow_state => 'active').count.should == 0
  end

  it "should bulk lock topics" do
    5.times { |i| @checkboxes[i].click }
    f('#lock').click
    wait_for_ajax_requests
    #TODO: check the UI to make sure the topics have a locked symbol
    what_to_create.where(:workflow_state => 'locked').count.should == 5
  end

  it "should search by title" do
    expected_text = 'hey there'
    update_attributes_and_validate(:title, expected_text)
  end

  it "should search by body" do
    body_text = 'new topic body'
    update_attributes_and_validate(:message, body_text, 'topic')
  end

  it "should search by author" do
    user_name = 'jake@instructure.com'
    title = 'new one'
    new_teacher = teacher_in_course(:course => @course, :active_all => true, :name => user_name)
    what_to_create == DiscussionTopic ? @course.discussion_topics.create!(:title => title, :user => new_teacher.user) : announcement_model(:title => title, :user => new_teacher.user)
    refresh_and_filter(:string, 'jake', user_name)
  end

  it "should return multiple items in the search" do
    new_title = 'updated'
    what_to_create.first.update_attributes(:title => "#{new_title} first")
    what_to_create.last.update_attributes(:title => "#{new_title} last")
    refresh_and_filter(:string, new_title, new_title, 2)
  end

  it "should filter by unread" do
    what_to_create.last.change_read_state('unread', @user)
    refresh_and_filter(:css, '#onlyUnread', 'new 004')
  end
end

shared_examples_for "discussion and announcement individual tests" do
  it_should_behave_like "in-process server selenium tests"

  TOPIC_TITLE = 'new discussion'

  def add_attachment_and_validate
    filename, fullpath, data = get_file("testfile5.zip")
    f('input[name=attachment]').send_keys(fullpath)
    type_in_tiny('textarea[name=message]', 'file attachement discussion')
    expect_new_page_load { submit_form('.form-actions') }
    wait_for_ajaximations
    f('.zip').should include_text(filename)
  end

  def edit(title, message)
    replace_content(f('input[name=title]'), title)
    type_in_tiny('textarea[name=message]', message)
    expect_new_page_load { submit_form('.form-actions') }
    f('#discussion_topic .discussion-title').text.should == title
  end

  before (:each) do
    @context = @course
  end

  it "should start a new topic" do
    get url

    expect_new_page_load { f('.btn-primary').click }
    edit(TOPIC_TITLE, 'new topic')
  end

  it "should add an attachment to a new topic" do
    topic_title = 'new topic with file'
    get url

    expect_new_page_load { f('.btn-primary').click }
    replace_content(f('input[name=title]'), topic_title)
    add_attachment_and_validate
    what_to_create.find_by_title(topic_title).attachment_id.should be_present
  end

  it "should add an attachment to a graded topic" do
    what_to_create == DiscussionTopic ? @course.discussion_topics.create!(:title => 'graded attachment topic', :user => @user) : announcement_model(:title => 'graded attachment topic', :user => @user)
    what_to_create.last.update_attributes(:assignment => @course.assignments.create!(:name => 'graded topic assignment'))
    get url
    expect_new_page_load{ f('.discussion-title').click }
    f("#discussion_topic .al-trigger-inner").click
    expect_new_page_load{ f("#ui-id-2").click }

    add_attachment_and_validate
  end

  it "should edit a topic" do
    edit_name = 'edited discussion name'
    topic = what_to_create == DiscussionTopic ? @course.discussion_topics.create!(:title => TOPIC_TITLE, :user => @user) : announcement_model(:title => TOPIC_TITLE, :user => @user)
    get url + "#{topic.id}"
    f("#discussion_topic .al-trigger-inner").click
    expect_new_page_load{ f("#ui-id-2").click }

    edit(edit_name, 'edit message')
  end

  it "should delete a topic" do
    what_to_create == DiscussionTopic ? @course.discussion_topics.create!(:title => TOPIC_TITLE, :user => @user) : announcement_model(:title => TOPIC_TITLE, :user => @user)
    get url

    f('.toggleSelected').click
    f('#delete').click
    driver.switch_to.alert.accept
    wait_for_ajaximations
    what_to_create.last.workflow_state.should == 'deleted'
    f('.discussionTopicIndexList').should be_nil
  end

  it "should reorder topics" do
    3.times { |i| what_to_create == DiscussionTopic ? @course.discussion_topics.create!(:title => "new topic #{i}", :user => @user) : announcement_model(:title => "new topic #{i}", :user => @user) }
    get url
    wait_for_ajax_requests

    topics = ff('.discussion-topic')
    driver.action.move_to(topics[0]).perform
    # drag first topic to second place
    # (using topics[2] as target to get the dragging to work)
    driver.action.drag_and_drop(fj('.discussion-drag-handle:visible', topics[0]), topics[2]).perform
    wait_for_ajax_requests
    new_topics = ffj('.discussion-topic') # using ffj to avoid selenium caching
    new_topics[0].should_not include_text('new topic 0')
  end
end
