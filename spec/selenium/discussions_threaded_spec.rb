require File.expand_path(File.dirname(__FILE__) + '/common')
require File.expand_path(File.dirname(__FILE__) + '/helpers/discussions_common')

describe "threaded discussions" do
  it_should_behave_like "discussions selenium tests"

  TOPIC_TITLE = 'threaded discussion topic'

  before (:each) do
    course_with_teacher_logged_in
    @topic = create_discussion(TOPIC_TITLE, 'threaded')
    @student = student_in_course.user
  end

  it "should create a threaded discussion" do
    get "/courses/#{@course.id}/discussion_topics/#{@topic.id}"
    wait_for_ajax_requests

    f('.discussion-title').text.should == TOPIC_TITLE
  end

  it "should reply to the threaded discussion" do
    entry_text = 'new entry'
    get "/courses/#{@course.id}/discussion_topics/#{@topic.id}"
    wait_for_ajax_requests

    add_reply(entry_text)
    last_entry = DiscussionEntry.last
    get_all_replies.count.should == 1
    @last_entry.find_element(:css, '.message').text.should == entry_text
    last_entry.depth.should == 1
  end

  it "should allow replies more than 2 levels deep" do
    reply_depth = 10
    reply_depth.times { |i| @topic.discussion_entries.create!(:user => @student, :message => "new threaded reply #{i} from student", :parent_entry => DiscussionEntry.last) }
    get "/courses/#{@course.id}/discussion_topics/#{@topic.id}"
    wait_for_ajax_requests
    DiscussionEntry.last.depth.should == reply_depth
  end

  it "should edit a reply" do
    pending("intermittently fails")
    edit_text = 'edit message '
    entry = @topic.discussion_entries.create!(:user => @student, :message => "new threaded reply from student")
    get "/courses/#{@course.id}/discussion_topics/#{@topic.id}"
    wait_for_ajax_requests

    edit_entry(entry, edit_text)
  end

  it "should delete a reply" do
    pending("intermittently fails")
    entry = @topic.discussion_entries.create!(:user => @student, :message => "new threaded reply from student")
    get "/courses/#{@course.id}/discussion_topics/#{@topic.id}"
    wait_for_ajax_requests

    delete_entry(entry)
  end
end
