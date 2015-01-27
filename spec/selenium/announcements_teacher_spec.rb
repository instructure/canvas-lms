require File.expand_path(File.dirname(__FILE__) + '/common')
require File.expand_path(File.dirname(__FILE__) + '/helpers/announcements_common')

describe "announcements" do
  include_examples "in-process server selenium tests"

  context "announcements as a teacher" do
    before (:each) do
      course_with_teacher_logged_in
    end

    describe "shared bulk topics specs" do
      let(:url) { "/courses/#{@course.id}/announcements/" }
      let(:what_to_create) { Announcement }

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

      it "should bulk delete topics" do
        5.times { |i| @checkboxes[i].click }
        f('#delete').click
        driver.switch_to.alert.accept
        wait_for_ajax_requests
        expect(ff('.discussion-topic').count).to eq 0
        expect(what_to_create.where(:workflow_state => 'active').count).to eq 0
      end

      it "should bulk lock topics" do
        5.times { |i| @checkboxes[i].click }
        f('#lock').click
        wait_for_ajax_requests
        #TODO: check the UI to make sure the topics have a locked symbol
        expect(what_to_create.where(:locked => true).count).to eq 5
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

    describe "shared main page topics specs" do
      let(:url) { "/courses/#{@course.id}/announcements/" }
      let(:what_to_create) { Announcement }

      before (:each) do
        @topic_title = 'new discussion'
        @context = @course
      end

      it "should start a new topic" do
        get url

        expect_new_page_load { f('.btn-primary').click }
        edit(@topic_title, 'new topic')
      end

      it "should add an attachment to a new topic" do
        topic_title = 'new topic with file'
        get url

        expect_new_page_load { f('.btn-primary').click }
        replace_content(f('input[name=title]'), topic_title)
        add_attachment_and_validate
        expect(what_to_create.where(title: topic_title).first.attachment_id).to be_present
      end

      it "should add an attachment to a graded topic" do
        what_to_create == DiscussionTopic ? @course.discussion_topics.create!(:title => 'graded attachment topic', :user => @user) : announcement_model(:title => 'graded attachment topic', :user => @user)
        if what_to_create == DiscussionTopic
          what_to_create.last.update_attributes(:assignment => @course.assignments.create!(:name => 'graded topic assignment'))
        end
        get url
        expect_new_page_load { f('.discussion-title').click }
        expect_new_page_load { f(".edit-btn").click }

        add_attachment_and_validate
      end

      it "should edit a topic" do
        edit_name = 'edited discussion name'
        topic = what_to_create == DiscussionTopic ? @course.discussion_topics.create!(:title => @topic_title, :user => @user) : announcement_model(:title => @topic_title, :user => @user)
        get url + "#{topic.id}"
        expect_new_page_load { f(".edit-btn").click }

        edit(edit_name, 'edit message')
      end

      it "should delete a topic" do
        what_to_create == DiscussionTopic ? @course.discussion_topics.create!(:title => @topic_title, :user => @user) : announcement_model(:title => @topic_title, :user => @user)
        get url

        f('.toggleSelected').click
        f('#delete').click
        driver.switch_to.alert.accept
        wait_for_ajaximations
        expect(what_to_create.last.workflow_state).to eq 'deleted'
        expect(f('.discussionTopicIndexList')).to be_nil
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
        expect(new_topics[0]).not_to include_text('new topic 0')
      end
    end

    it "should create a delayed announcement" do
      skip("193")
      get course_announcements_path(@course)
      create_announcement_option('input[type=checkbox][name=delay_posting]')
      f('.ui-datepicker-trigger').click
      datepicker_next
      f('.ui-datepicker-time .ui-datepicker-ok').click
      expect_new_page_load { submit_form('.form-actions') }
      expect(f('.discussion-fyi')).to include_text('This topic will not be visible')
    end

    it "should add and remove an external feed to announcements" do
      get "/courses/#{@course.id}/announcements"
      wait_for_ajaximations

      #add external feed to announcements
      feed_name = 'http://www.google.com'

      f(".add_external_feed_link").click
      wait_for_ajaximations
      expect(f("#external_feed_url")).to be_displayed
      f('#external_feed_url').send_keys(feed_name)

      f('#external_feed_enable_header_match').click
      wait_for_ajaximations
      expect(f('#external_feed_header_match')).to be_displayed
      f('#external_feed_header_match').send_keys('blah')

      expect {
        submit_form(f('#add_external_feed_form'))
        wait_for_ajaximations
      }.to change(ExternalFeed, :count).by(1)

      #delete external feed
      expect(f(".external_feed")).to include_text('feed')
      expect {
        f('.external_feed .close').click
        wait_for_ajax_requests
        expect(element_exists('.external_feed')).to be_falsey
      }.to change(ExternalFeed, :count).by(-1)
    end

    it "should remove delayed_post_at when unchecking delay_posting" do
      topic = announcement_model(:title => @topic_title, :user => @user, :delayed_post_at => 10.days.ago)
      get "/courses/#{@course.id}/announcements/#{topic.id}"
      expect_new_page_load { f(".edit-btn").click }

      f('input[type=checkbox][name="delay_posting"]').click
      expect_new_page_load { f('.form-actions button[type=submit]').click }

      topic.reload
      expect(topic.delayed_post_at).to be_nil
    end

    it "should have a teacher add a new entry to its own announcement" do
      skip "delayed jobs"
      create_announcement
      get [@course, @announcement]

      f('#content .add_entry_link').click
      entry_text = 'new entry text'
      type_in_tiny('textarea[name=message]', entry_text)
      expect_new_page_load { submit_form('.form-actions') }
      expect(f('#entry_list .discussion_entry .content')).to include_text(entry_text)
      f('#left-side .announcements').click
      expect(f('.topic_reply_count').text).to eq '1'
    end

    it "should show announcements to student view student" do
      create_announcement
      enter_student_view
      get "/courses/#{@course.id}/announcements"

      announcement = f('.discussionTopicIndexList .discussion-topic')
      expect(announcement.find_element(:css, '.discussion-summary')).to include_text(@announcement.message)
    end

    it "should always see student replies when 'initial post required' is turned on" do
      student_entry = 'this is my reply'

      create_announcement_initial

      # Create reply as a student
      enter_student_view
      reply_to_announcement(@announcement.id, student_entry)
      f('.logout').click
      wait_for_ajaximations

      #As a teacher, verify that you can see the student's reply even though you have not responded
      get "/courses/#{@course.id}/discussion_topics/#{@announcement.id}"
      expect(ff('.discussion_entry .message')[1]).to include_text(student_entry)
    end

    def setup_search()
      create_announcement('day one', 'partridge')
      create_announcement('day two', 'turtle doves')
      create_announcement('day three', 'french hens')
    end


    # Search for an announcement by the content of the announcement
    it "should search by body" do
      setup_search
      get "/courses/#{@course.id}/announcements/"
      f('#searchTerm').send_keys('turtle')

      # The keyword 'turtle' is in the body. Due to the layout of the html, it
      #is more efficient to look for the title that matches the body
      expect(f('.discussion-title')).not_to include_text("one")
      expect(f('.discussion-title')).to include_text("two")
      expect(f('.discussion-title')).not_to include_text("three")
    end

    # Search for an announcement by the title of the announcement
    it "should search by title" do
      setup_search
      get "/courses/#{@course.id}/announcements/"
      f('#searchTerm').send_keys('o')

      #Two of our titles have an 'o' in them. There are two announcements
      #so we store the ones we find in an array. Sorting algorithms will put
      # "two" first and "one" second. We should not see three.
      expect(ff('.discussion-title')[1]).to include_text("one")
      expect(ff('.discussion-title')[0]).to include_text("two")
      expect(f('.discussion-title')[2]).to be_nil #No 3rd one listed
    end

    # Search for an announcement by the author of the announcement
    it "should search by author" do
      setup_search
      # Creating users through the rails function does not set an author.
      # Manual setup is needed
      create_announcement_manual("title 1", "jocoga")
      create_announcement_manual("title 2", "hotdog")
      get "/courses/#{@course.id}/announcements/"
      f('#searchTerm').send_keys('nob')

      # Only 2 of the 5 announcements will have an author
      expect(ff('.discussion-author')[0]).to include_text("nobody")
      expect(ff('.discussion-author')[1]).to include_text("nobody")
      expect(ff('.discussion-author')[2]).to be_nil #No 3rd one listed
    end
  end
end
