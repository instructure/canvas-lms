require File.expand_path(File.dirname(__FILE__) + '/../helpers/discussions_common')

describe "discussions" do
  include_examples "in-process server selenium tests"

  let(:course) { course_model.tap{|course| course.offer!} }
  let(:student) { student_in_course(course: course, name: 'student', active_all: true).user }
  let(:teacher) { teacher_in_course(course: course, name: 'teacher', active_all: true).user }
  let(:student_topic) { course.discussion_topics.create!(user: student, title: 'student topic title', message: 'student topic message') }
  let(:teacher_topic) { course.discussion_topics.create!(user: teacher, title: 'teacher topic title', message: 'teacher topic message') }
  let(:assignment_group) { course.assignment_groups.create!(name: 'assignment group') }
  let(:assignment) { course.assignments.create!(
      name: 'assignment',
      #submission_types: 'discussion_topic',
      assignment_group: assignment_group
  ) }
  let(:assignment_topic) do
    course.discussion_topics.create!(user: teacher,
                                     title: 'assignment topic title',
                                     message: 'assignment topic message',
                                     assignment: assignment)
  end
  let(:entry) { topic.discussion_entries.create!(user: teacher, message: 'teacher entry') }

  context "on the show page" do
    let(:url) { "/courses/#{course.id}/discussion_topics/#{topic.id}/" }

    context "as a student" do
      let(:topic) { student_topic }

      before(:each) do
        user_session(student)
      end

      it "should not show admin options in gear menu to students who've created a discussion" do
        entry
        get url
        wait_for_ajax_requests
        expect(f('.headerBar .admin-links')).not_to be_nil
        expect(f('.mark_all_as_read')).not_to be_nil
        #f('.mark_all_as_unread').should_not be_nil
        expect(f('.delete_discussion')).to be_nil
        expect(f('.discussion_locked_toggler')).to be_nil
      end

      it "should validate a group assignment discussion" do
        get "/courses/#{course.id}/discussion_topics/#{assignment_topic.id}"
        expect(f('.entry-content')).to include_text('This is a graded discussion')
      end

      context "teacher topic" do
        let(:topic) { teacher_topic }

        it "should allow students to reply to a discussion even if they cannot create a topic" do
          course.allow_student_discussion_topics = false
          course.save!
          get url
          wait_for_ajax_requests
          new_student_entry_text = "'ello there"
          expect(f('#content')).not_to include_text(new_student_entry_text)
          add_reply new_student_entry_text
          expect(f('#content')).to include_text(new_student_entry_text)
        end

        it "should display the subscribe button after an initial post" do
          topic.unsubscribe(student)
          topic.require_initial_post = true
          topic.save!

          get url
          wait_for_ajaximations
          expect(f('.topic-unsubscribe-button')).not_to be_displayed
          expect(f('.topic-subscribe-button')).not_to be_displayed

          f('.discussion-reply-action').click
          wait_for_ajaximations
          type_in_tiny 'textarea', 'initial post text'
          submit_form('.discussion-reply-form')
          wait_for_ajaximations
          expect(f('.topic-unsubscribe-button')).to be_displayed
        end

        it "should validate that a student can see it and reply to a discussion" do
          new_student_entry_text = 'new student entry'
          get url
          wait_for_ajax_requests
          expect(f('.message_wrapper')).to include_text('teacher')
          expect(f('#content')).not_to include_text(new_student_entry_text)
          add_reply new_student_entry_text
          expect(f('#content')).to include_text(new_student_entry_text)
        end

        it "should let students post to a post-first discussion" do
          new_student_entry_text = 'new student entry'
          topic.require_initial_post = true
          topic.save
          entry
          get url
          wait_for_ajax_requests
          # shouldn't see the existing entry until after posting
          expect(f('#content')).not_to include_text("new entry from teacher")
          add_reply new_student_entry_text
          # now they should see the existing entry, and their entry
          entries = get_all_replies
          expect(entries.length).to eq 2
          expect(entries[0]).to include_text("teacher entry")
          expect(entries[1]).to include_text(new_student_entry_text)
        end
      end
    end

    context "as a teacher" do
      let(:topic) { teacher_topic }

      before(:each) do
        resize_screen_to_normal
        user_session(teacher)
      end

      describe "rubrics" do
        it "should change points when used for grading" do
          resize_screen_to_default
          get "/courses/#{course.id}/discussion_topics/#{assignment_topic.id}"
          wait_for_ajax_requests

          f('.al-trigger').click
          wait_for_ajaximations

          fj('.icon-rubric').click
          wait_for_ajaximations

          new_points = get_value(".criterion_points")
          dialog = fj(".ui-dialog:visible")

          keep_trying_until { expect(fj(".grading_rubric_checkbox:visible")).to be_displayed }
          set_value fj(".grading_rubric_checkbox:visible", dialog), true

          fj(".save_button:visible", dialog).click
          wait_for_ajaximations

          fj(".ui-button:contains('Change'):visible").click
          wait_for_ajaximations

          fj(".save_button:visible", dialog).click
          wait_for_ajaximations

          expect(fj(".discussion-title")).to include_text(new_points)
        end
      end

      it "should escape correctly when posting an attachment" do
        get url
        message = "message that needs escaping ' \" & !@#^&*()$%{}[];: blah"
        add_reply(message, 'graded.png')
        expect(@last_entry.find_element(:css, '.message').text).to eq message
      end

      it "should reply as a student and validate teacher can see reply" do
        skip "figure out delayed jobs"
        entry = topic.discussion_entries.create!(:user => student, :message => 'new entry from student')
        get url
        expect(f("#entry-#{entry.id}")).to include_text('new entry from student')
      end

      it "should clear lock_at when manually triggering unlock" do
        topic.delayed_post_at = 10.days.ago
        topic.lock_at         = 5.days.ago
        topic.locked          = true
        topic.save!

        get url
        wait_for_ajaximations

        f("#discussion-managebar .al-trigger").click
        expect_new_page_load { f(".discussion_locked_toggler").click }

        topic.reload
        expect(topic.lock_at).to be_nil
        expect(topic.active?).to be_truthy
        expect(topic.locked?).to be_falsey
      end

      it "should allow publishing and unpublishing from a topic's page" do
        topic.workflow_state = 'unpublished'
        topic.save!
        expect(topic.published?).to be_falsey
        get url
        f('#topic_publish_button').click
        wait_for_ajaximations
        topic.reload
        expect(topic.published?).to be_truthy
        f('#topic_publish_button').click
        wait_for_ajaximations
        topic.reload
        expect(topic.published?).to be_falsey
      end

      it "should edit a topic" do
        edit_name = 'edited discussion name'
        get url
        expect_new_page_load { f(".edit-btn").click }

        edit(edit_name, 'edit message')
      end

      it "should validate closing the discussion for comments" do
        get url
        f("#discussion-managebar .al-trigger").click
        expect_new_page_load { f(".discussion_locked_toggler").click }
        expect(f('.discussion-fyi').text).to eq 'This topic is closed for comments'
        expect(DiscussionTopic.last.locked?).to be_truthy

        expect(ff('.discussion-reply-action')).to_not be_empty # should let teachers reply

        student_in_course(:course => @course, :active_all => true)
        user_session(@student)
        get url
        expect(ff('.discussion-reply-action')).to be_empty
      end

      it "should validate reopening the discussion for comments" do
        topic.lock!
        get url
        f("#discussion-managebar .al-trigger").click
        expect_new_page_load { f(".discussion_locked_toggler").click }
        expect(ff('.discussion-reply-action')).not_to be_empty
        expect(DiscussionTopic.last.workflow_state).to eq 'active'
        expect(DiscussionTopic.last.locked?).to be_falsey
      end

      context "graded" do
        let(:topic) { assignment_topic }

        it "should hide the speedgrader in large courses" do
          course.large_roster = true
          course.save!
          get url

          f('.al-trigger').click
          expect(f('.al-options').text).not_to match(/Speed Grader/)
        end
      end

      context "in student view" do
        it "should allow student view student to read/post" do
          enter_student_view
          get url
          expect(get_all_replies.count).to eq 0
          add_reply
          expect(get_all_replies.count).to eq 1
        end

        # note: this isn't desirable, but it's the way it is for this release
        it "should show student view posts to teacher and other students" do
          fake_student = course.student_view_student
          entry = topic.reply_from(:user => fake_student, :text => 'i am a figment of your imagination')
          topic.create_materialized_view

          get url
          wait_for_ajaximations
          expect(get_all_replies.first).to include_text fake_student.name
        end
      end
    end

    it "should show only 10 root replies per page"
    it "should paginate root entries"
    it "should show only three levels deep"
    it "should show only three children of a parent"
    it "should display unrendered unread and total counts accurately"
    it "should expand descendents"
    it "should expand children"
    it "should deep link to an entry rendered on the first page"
    it "should deep link to an entry rendered on a different page"
    it "should deep link to a non-rendered child entry of a rendered parent"
    it "should deep link to a child entry of a non-rendered parent"
    it "should allow users to 'go to parent'"
    it "should collapse a thread"
    it "should filter entries by user display name search term"
    it "should filter entries by content search term"
    it "should filter entries by unread"
    it "should filter entries by unread and search term"
    it "should link to an entry in context of the discussion when clicked in result view"
  end
end
