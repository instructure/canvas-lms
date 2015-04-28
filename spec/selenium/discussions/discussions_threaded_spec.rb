require File.expand_path(File.dirname(__FILE__) + '/../helpers/discussions_common')

describe "threaded discussions" do
  include_examples "in-process server selenium tests"

  before(:each) do
    @topic_title = 'threaded discussion topic'
    course_with_teacher_logged_in
    @topic = create_discussion(@topic_title, 'threaded')
    @student = student_in_course.user
  end

  it "should create a threaded discussion" do
    get "/courses/#{@course.id}/discussion_topics/#{@topic.id}"

    expect(f('.discussion-title').text).to eq @topic_title
  end

  it "should reply to the threaded discussion" do
    entry_text = 'new entry'
    get "/courses/#{@course.id}/discussion_topics/#{@topic.id}"

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
    expect(DiscussionEntry.last.depth).to eq reply_depth
  end

  it "should allow edits to entries with replies" do
    edit_text = 'edit message'
    entry       = @topic.discussion_entries.create!(:user => @student, :message => 'new threaded reply from student')
    child_entry = @topic.discussion_entries.create!(:user => @student, :message => 'new threaded child reply from student', :parent_entry => entry)
    get "/courses/#{@course.id}/discussion_topics/#{@topic.id}"
    edit_entry(entry, edit_text)
    expect(entry.reload.message).to match(edit_text)
  end

  it "should edit a reply" do
    edit_text = 'edit message'
    entry = @topic.discussion_entries.create!(:user => @student, :message => "new threaded reply from student")
    get "/courses/#{@course.id}/discussion_topics/#{@topic.id}"
    edit_entry(entry, edit_text)
  end

  it "should not allow students to edit replies to a locked topic" do
    user_session(@student)
    entry = @topic.discussion_entries.create!(:user => @student, :message => "new threaded reply from student")
    @topic.lock!
    get "/courses/#{@course.id}/discussion_topics/#{@topic.id}"
    wait_for_ajaximations

    fj("#entry-#{entry.id} .al-trigger").click
    wait_for_ajaximations

    expect(fj('.al-options:visible').text).to_not include("Edit")
  end

  it "should show a reply time that is different from the creation time", priority: "2", test_id: 113813 do
    # Reset discussion created_at time to two minutes ago
    @topic.update_attribute(:posted_at, Time.zone.now - 2.minute)

    # Create reply message and reset created_at to one minute ago
    @topic.reply_from(user: @student, html: "New test reply")
    reply = DiscussionEntry.last
    reply.update_attribute(:created_at, Time.zone.now - 1.minute)

    # Navigate to discussion URL
    get "/courses/#{@course.id}/discussion_topics/#{@topic.id}"

    replied_at = f('.discussion-pubdate.hide-if-collapsed > time').attribute("data-html-tooltip-title")

    edit_entry(reply, "Reply edited")
    edited_at = (reply[:updated_at].to_time.strftime('%b %-d at %-l:%M') << reply[:updated_at].to_time.strftime('%p').downcase).to_s
    displayed_edited_at = f('.discussion-fyi').text

    # Verify displayed edit time includes object update time
    expect(displayed_edited_at).to include(edited_at)

    # Verify edit time is later than reply time
    expect(replied_at).to be < (edited_at)

  end

  it "should delete a reply" do
    entry = @topic.discussion_entries.create!(:user => @student, :message => "new threaded reply from student")
    get "/courses/#{@course.id}/discussion_topics/#{@topic.id}"
    delete_entry(entry)
  end

  it "should display editor name and timestamp after edit" do
    edit_text = 'edit message'
    entry = @topic.discussion_entries.create!(:user => @student, :message => "new threaded reply from student")
    get "/courses/#{@course.id}/discussion_topics/#{@topic.id}"
    edit_entry(entry, edit_text)
    expect(f("#entry-#{entry.id} .discussion-fyi").text).to match("Edited by #{@teacher.name} on")
  end

  it "should support repeated editing" do
    entry = @topic.discussion_entries.create!(:user => @student, :message => "new threaded reply from student")
    get "/courses/#{@course.id}/discussion_topics/#{@topic.id}"
    edit_entry(entry, 'New text 1')
    expect(f("#entry-#{entry.id} .discussion-fyi").text).to match("Edited by #{@teacher.name} on")
    # second edit
    edit_entry(entry, 'New text 2')
    entry.reload
    expect(entry.message).to match 'New text 2'
  end

  it "should re-render replies after editing" do
    edit_text = 'edit message'
    entry = @topic.discussion_entries.create!(:user => @student, :message => "new threaded reply from student")

    get "/courses/#{@course.id}/discussion_topics/#{@topic.id}"
    @last_entry = f("#entry-#{entry.id}")
    reply_text = "this is a reply"
    add_reply(reply_text)
    subentry = DiscussionEntry.last

    expect(f("#entry-#{entry.id} #entry-#{subentry.id}")).to be_truthy, "precondition"
    edit_entry(entry, edit_text)
    expect(f("#entry-#{entry.id} #entry-#{subentry.id}")).to be_truthy
  end

  it "should display editor name and timestamp after delete" do
    entry_text = 'new entry'
    get "/courses/#{@course.id}/discussion_topics/#{@topic.id}"

    add_reply(entry_text)
    entry = DiscussionEntry.last
    delete_entry(entry)
    expect(f("#entry-#{entry.id} .discussion-title").text).to match("Deleted by #{@teacher.name} on")
  end
end
