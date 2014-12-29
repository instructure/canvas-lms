require File.expand_path(File.dirname(__FILE__) + '/../helpers/discussions_common')

context "threaded discussions" do
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

    expect(f('.discussion-title').text).to eq @topic_title
  end

  it "should reply to the threaded discussion" do
    entry_text = 'new entry'
    get "/courses/#{@course.id}/discussion_topics/#{@topic.id}"
    wait_for_ajax_requests

    add_reply(entry_text)
    last_entry = DiscussionEntry.last
    expect(get_all_replies.count).to eq 1
    expect(@last_entry.find_element(:css, '.message').text).to eq entry_text
    expect(last_entry.depth).to eq 1
  end

  it "should allow replies more than 2 levels deep" do
    reply_depth = 10
    reply_depth.times { |i| @topic.discussion_entries.create!(:user => @student, :message => "new threaded reply #{i} from student", :parent_entry => DiscussionEntry.last) }
    get "/courses/#{@course.id}/discussion_topics/#{@topic.id}"
    wait_for_ajax_requests
    expect(DiscussionEntry.last.depth).to eq reply_depth
  end

  it "should allow edits to entries with replies" do
    edit_text = 'edit message '
    entry       = @topic.discussion_entries.create!(:user => @student, :message => 'new threaded reply from student')
    child_entry = @topic.discussion_entries.create!(:user => @student, :message => 'new threaded child reply from student', :parent_entry => entry)
    get "/courses/#{@course.id}/discussion_topics/#{@topic.id}"
    wait_for_ajax_requests
    edit_entry(entry, edit_text)
    expect(entry.reload.message).to match(edit_text)
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
    expect(f("#entry-#{entry.id} .discussion-fyi").text).to match("Edited by #{@teacher.name} on")
  end

  it "should support repeated editing" do
    entry = @topic.discussion_entries.create!(:user => @student, :message => "new threaded reply from student")
    get "/courses/#{@course.id}/discussion_topics/#{@topic.id}"
    wait_for_ajaximations
    edit_entry(entry, 'New text 1')
    expect(f("#entry-#{entry.id} .discussion-fyi").text).to match("Edited by #{@teacher.name} on")
    # second edit
    edit_entry(entry, 'New text 2')
    entry.reload
    expect(entry.message).to match 'New text 2'
  end

  it "should display editor name and timestamp after delete" do
    entry_text = 'new entry'
    get "/courses/#{@course.id}/discussion_topics/#{@topic.id}"
    wait_for_ajax_requests

    add_reply(entry_text)
    entry = DiscussionEntry.last
    delete_entry(entry)
    expect(f("#entry-#{entry.id} .discussion-title").text).to match("Deleted by #{@teacher.name} on")
  end
end
