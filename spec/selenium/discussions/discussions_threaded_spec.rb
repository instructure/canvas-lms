require File.expand_path(File.dirname(__FILE__) + '/../helpers/discussions_common')

describe "threaded discussions" do
  include_context "in-process server selenium tests"
  include DiscussionsCommon

  before(:each) do
    @topic_title = 'threaded discussion topic'
    course_with_teacher_logged_in
    @topic = create_discussion(@topic_title, 'threaded')
    @student = student_in_course.user
  end

  it "should create a threaded discussion", priority: "1", test_id: 150511 do
    get "/courses/#{@course.id}/discussion_topics/#{@topic.id}"

    expect(f('.discussion-title').text).to eq @topic_title
  end

  it "should reply to the threaded discussion", priority: "2", test_id: 222519 do
    entry_text = 'new entry'
    get "/courses/#{@course.id}/discussion_topics/#{@topic.id}"

    add_reply(entry_text)
    last_entry = DiscussionEntry.last
    expect(get_all_replies.count).to eq 1
    expect(@last_entry.find_element(:css, '.message').text).to eq entry_text
    expect(last_entry.depth).to eq 1
  end

  it "should allow replies more than 2 levels deep", priority: "1", test_id: 150512 do
    reply_depth = 10
    reply_depth.times { |i| @topic.discussion_entries.create!(user: @student,
                                                              message: "new threaded reply #{i} from student",
                                                              parent_entry: DiscussionEntry.last) }
    get "/courses/#{@course.id}/discussion_topics/#{@topic.id}"
    expect(DiscussionEntry.last.depth).to eq reply_depth
    expect(DiscussionEntry.last.parent_entry).to_not eq DiscussionEntry.first
  end

  it "should only allow replies 2 levels deep for non threaded discussion", priority: "1", test_id: 150516 do
    non_threaded_topic = @course.discussion_topics.create!(user: @teacher,
                                                           title: 'Non threaded discussion',
                                                           message: 'discussion topic message')
    reply_depth = 3
    reply_depth.times { |i| non_threaded_topic.discussion_entries.create!(user: @student,
                                                              message: "new threaded reply #{i} from student",
                                                              parent_entry: DiscussionEntry.last) }
    get "/courses/#{@course.id}/discussion_topics/#{non_threaded_topic.id}"
    expect(DiscussionEntry.last.parent_entry).to eq DiscussionEntry.first
  end

  it "should allow edits to entries with replies", priority: "2", test_id: 222520 do
    edit_text = 'edit message'
    entry       = @topic.discussion_entries.create!(user: @student,
                                                    message: 'new threaded reply from student')
    child_entry = @topic.discussion_entries.create!(user: @student,
                                                    message: 'new threaded child reply from student',
                                                    parent_entry: entry)
    get "/courses/#{@course.id}/discussion_topics/#{@topic.id}"
    edit_entry(entry, edit_text)
    expect(entry.reload.message).to match(edit_text)
  end

  it "should not allow edits for a concluded student", priority: "2", test_id: 222526 do
    student_enrollment = course_with_student(:course => @course, :user => @student, :active_enrollment => true)
    entry = @topic.discussion_entries.create!(user: @student,
                                              message: 'new threaded reply from student')
    user_session(@student)
    get "/courses/#{@course.id}/discussion_topics/#{@topic.id}"
    student_enrollment.send("conclude")
    get "/courses/#{@course.id}/discussion_topics/#{@topic.id}"
    check_edit_entry(entry)
  end

  it "should not allow deletes for a concluded student", priority: "2", test_id: 222526 do
    student_enrollment = course_with_student(:course => @course, :user => @student, :active_enrollment => true)
    entry = @topic.discussion_entries.create!(user: @student,
                                              message: 'new threaded reply from student')
    user_session(@student)
    get "/courses/#{@course.id}/discussion_topics/#{@topic.id}"
    student_enrollment.send("conclude")
    get "/courses/#{@course.id}/discussion_topics/#{@topic.id}"
    check_delete_entry(entry)
  end

  it "should allow edits to discussion with replies", priority: "1", test_id: 150513 do
    reply_depth = 3
    reply_depth.times { |i| @topic.discussion_entries.create!(user: @student,
                                                              message: "new threaded reply #{i} from student",
                                                              parent_entry: DiscussionEntry.last) }
    get "/courses/#{@course.id}/discussion_topics/#{@topic.id}"
    expect_new_page_load{f(' .edit-btn').click}
    edit_topic('edited title', 'edited message')
    expect(get_all_replies.count).to eq 3
  end

  it "should edit a reply", priority: "1", test_id: 150514 do
    edit_text = 'edit message'
    entry = @topic.discussion_entries.create!(user: @student, message: "new threaded reply from student")
    get "/courses/#{@course.id}/discussion_topics/#{@topic.id}"
    edit_entry(entry, edit_text)
  end

  it "should not allow students to edit replies to a locked topic", priority: "1", test_id: 222521 do
    user_session(@student)
    entry = @topic.discussion_entries.create!(user: @student, message: "new threaded reply from student")
    @topic.lock!
    get "/courses/#{@course.id}/discussion_topics/#{@topic.id}"
    wait_for_ajaximations

    fj("#entry-#{entry.id} .al-trigger").click
    wait_for_ajaximations

    expect(fj('.al-options:visible').text).to_not include("Edit")
  end

  it "should show a reply time that is different from the creation time", priority: "2", test_id: 113813 do
    @enrollment.workflow_state = 'active'
    @enrollment.save!

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
    reply.reload
    edited_at = format_time_for_view(reply.updated_at)
    displayed_edited_at = f('.discussion-fyi').text

    # Verify displayed edit time includes object update time
    expect(displayed_edited_at).to include(edited_at)

    # Verify edit time is different than reply time
    expect(replied_at).not_to eql(edited_at)
  end

  it "should delete a reply", priority: "1", test_id: 150515 do
    entry = @topic.discussion_entries.create!(user: @student, message: "new threaded reply from student")
    get "/courses/#{@course.id}/discussion_topics/#{@topic.id}"
    delete_entry(entry)
  end

  it "should display editor name and timestamp after edit", priority: "2", test_id: 222522 do
    edit_text = 'edit message'
    entry = @topic.discussion_entries.create!(user: @student, message: "new threaded reply from student")
    get "/courses/#{@course.id}/discussion_topics/#{@topic.id}"
    edit_entry(entry, edit_text)
    wait_for_ajaximations
    expect(f("#entry-#{entry.id} .discussion-fyi").text).to match("Edited by #{@teacher.name} on")
  end

  it "should support repeated editing", priority: "2", test_id: 222523 do
    entry = @topic.discussion_entries.create!(user: @student, message: "new threaded reply from student")
    get "/courses/#{@course.id}/discussion_topics/#{@topic.id}"
    edit_entry(entry, 'New text 1')
    expect(f("#entry-#{entry.id} .discussion-fyi").text).to match("Edited by #{@teacher.name} on")
    # second edit
    edit_entry(entry, 'New text 2')
    entry.reload
    expect(entry.message).to match 'New text 2'
  end

  it "should re-render replies after editing", priority: "2", test_id: 222524 do
    edit_text = 'edit message'
    entry = @topic.discussion_entries.create!(user: @student, message: "new threaded reply from student")

    get "/courses/#{@course.id}/discussion_topics/#{@topic.id}"
    @last_entry = f("#entry-#{entry.id}")
    reply_text = "this is a reply"
    add_reply(reply_text)
    expect { DiscussionEntry.count }.to become(2)
    subentry = DiscussionEntry.last
    refresh_page

    expect(f("#entry-#{entry.id} #entry-#{subentry.id}")).to be_truthy, "precondition"
    edit_entry(entry, edit_text)
    expect(f("#entry-#{entry.id} #entry-#{subentry.id}")).to be_truthy
  end

  it "should display editor name and timestamp after delete", priority: "2", test_id: 222525  do
    entry_text = 'new entry'
    get "/courses/#{@course.id}/discussion_topics/#{@topic.id}"

    fj('label[for="showDeleted"]').click()
    add_reply(entry_text)
    entry = DiscussionEntry.last
    delete_entry(entry)
    expect(f("#entry-#{entry.id} .discussion-title").text).to match("Deleted by #{@teacher.name} on")
  end
end
