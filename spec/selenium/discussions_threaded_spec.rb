require File.expand_path(File.dirname(__FILE__) + '/helpers/discussions_common')


describe "threaded discussions" do
  include_examples "in-process server selenium tests"

  before (:each) do
    @topic_title = 'threaded discussion topic'
    course_with_teacher_logged_in
    @topic = create_discussion(@topic_title, 'threaded')
    @student = student_in_course.user
  end

  it "should create a threaded discussion" do
    get "/courses/#{@course.id}/discussion_topics/#{@topic.id}"
    wait_for_ajaximations

    f('.discussion-title').text.should == @topic_title
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

  it "should allow edits to entries with replies" do
    edit_text = 'edit message '
    entry       = @topic.discussion_entries.create!(:user => @student, :message => 'new threaded reply from student')
    child_entry = @topic.discussion_entries.create!(:user => @student, :message => 'new threaded child reply from student', :parent_entry => entry)
    get "/courses/#{@course.id}/discussion_topics/#{@topic.id}"
    wait_for_ajax_requests
    edit_entry(entry, edit_text)
    entry.reload.message.should match(edit_text)
  end

  it "should edit a reply" do
    edit_text = 'edit message '
    entry = @topic.discussion_entries.create!(:user => @student, :message => "new threaded reply from student")
    get "/courses/#{@course.id}/discussion_topics/#{@topic.id}"
    wait_for_ajax_requests
    edit_entry(entry, edit_text)
  end

  it "should delete a reply" do
    entry = @topic.discussion_entries.create!(:user => @student, :message => "new threaded reply from student")
    get "/courses/#{@course.id}/discussion_topics/#{@topic.id}"
    wait_for_ajaximations
    delete_entry(entry)
  end

  it "should display editor name and timestamp after edit" do
    edit_text = 'edit message '
    entry = @topic.discussion_entries.create!(:user => @student, :message => "new threaded reply from student")
    get "/courses/#{@course.id}/discussion_topics/#{@topic.id}"
    wait_for_ajax_requests
    edit_entry(entry, edit_text)
    f("#entry-#{entry.id} .discussion-fyi").text.should match("Edited by #{@teacher.name} on")
  end

  it "should support repeated editing" do
    entry = @topic.discussion_entries.create!(:user => @student, :message => "new threaded reply from student")
    get "/courses/#{@course.id}/discussion_topics/#{@topic.id}"
    wait_for_ajaximations
    edit_entry(entry, 'New text 1')
    f("#entry-#{entry.id} .discussion-fyi").text.should match("Edited by #{@teacher.name} on")
    # second edit
    edit_entry(entry, 'New text 2')
    entry.reload
    entry.message.should match 'New text 2'
  end

  it "should display editor name and timestamp after delete" do
    entry_text = 'new entry'
    get "/courses/#{@course.id}/discussion_topics/#{@topic.id}"
    wait_for_ajax_requests

    add_reply(entry_text)
    entry = DiscussionEntry.last
    delete_entry(entry)
    f("#entry-#{entry.id} .discussion-title").text.should match("Deleted by #{@teacher.name} on")
  end
end
