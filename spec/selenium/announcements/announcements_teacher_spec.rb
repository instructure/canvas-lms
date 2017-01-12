require_relative '../common'
require_relative '../helpers/announcements_common'

describe "announcements" do
  include_context "in-process server selenium tests"
  include AnnouncementsCommon

  context "announcements as a teacher" do
    before :once do
      @teacher = user_with_pseudonym(active_user: true)
      course_with_teacher(user: @teacher, active_course: true, active_enrollment: true)
    end

    before :each do
      user_session(@teacher)
    end

    describe "shared bulk topics specs" do
      let(:url) { "/courses/#{@course.id}/announcements/" }
      let(:what_to_create) { Announcement }

      before :once do
        @context = @course
        5.times do |i|
          title = "new #{i.to_s.rjust(3, '0')}"
          what_to_create == DiscussionTopic ? @course.discussion_topics.create!(:title => title, :user => @user) : announcement_model(:title => title, :user => @user)
        end
      end

      before :each do
        get url
        @checkboxes = ff('.toggleSelected')
      end

      it "should bulk delete topics", priority: "1", test_id: 220360 do
        5.times { |i| @checkboxes[i].click }
        f('#delete').click
        driver.switch_to.alert.accept
        wait_for_ajax_requests
        expect(f("#content")).not_to contain_css('.discussion-topic')
        expect(what_to_create.where(:workflow_state => 'active').count).to eq 0
      end

      it "should bulk lock topics", priority: "1", test_id: 220361 do
        5.times { |i| @checkboxes[i].click }
        scroll_page_to_top # if we only scroll until it's in view, its tooltip can interfere with clicks
        move_to_click('label[for=lock]')
        wait_for_ajax_requests
        #TODO: check the UI to make sure the topics have a locked symbol
        expect(what_to_create.where(locked: true).count).to eq 5
      end

      it "should search by title", priority: "1", test_id: 150525 do
        expected_text = 'hey there'
        update_attributes_and_validate(:title, expected_text)
      end

      it "should search by body", priority: "1", test_id: 220358 do
        body_text = 'new topic body'
        update_attributes_and_validate(:message, body_text, 'topic')
      end

      it "should search by author", priority: "1", test_id: 220359 do
        user_name = 'jake@instructure.com'
        title = 'new one'
        new_teacher = teacher_in_course(:course => @course, :active_all => true, :name => user_name)
        what_to_create == DiscussionTopic ? @course.discussion_topics.create!(:title => title, :user => new_teacher.user) : announcement_model(:title => title, :user => new_teacher.user)
        refresh_and_filter(:string, 'jake', user_name)
      end

      it "should search an entire phrase" do
        replace_content(f('#searchTerm'), 'new 001')
        expect(ff('.discussionTopicIndexList .discussion-topic').count).to eq 1
      end

      it "should return multiple items in the search", priority: "1", test_id: 220362 do
        new_title = 'updated'
        what_to_create.first.update_attributes(:title => "#{new_title} first")
        what_to_create.last.update_attributes(:title => "#{new_title} last")
        refresh_and_filter(:string, new_title, new_title, 2)
      end

      it "should filter by unread", priority: "1", test_id: 220363 do
        what_to_create.last.change_read_state('unread', @user)
        refresh_and_filter(:css, '#discussionsFilter', 'new 004')
      end
    end

    describe "shared main page topics specs" do
      let(:url) { "/courses/#{@course.id}/announcements/" }
      let(:what_to_create) { Announcement }

      before :once do
        @topic_title = 'new discussion'
        @context = @course
      end

      it "should have a lock that appears and disappears when the cog menu is used to lock/unlock the announcement for comments", priority: "1", test_id: 220365 do
        title = "My announcement"
        announcement_model(:title => title, :user => @user)
        get url

        expect(f("#content")).not_to contain_css('.discussion-info-icons .icon-lock')
        f('.discussion-actions .al-trigger').click
        wait_for_ajaximations
        f('.al-options li a.icon-lock').click
        wait_for_ajaximations
        expect(f('.discussion-info-icons .icon-lock')).not_to be_nil
        f('.discussion-actions .al-trigger').click
        wait_for_ajaximations
        f('.al-options li a.icon-lock').click
        wait_for_ajaximations
        expect(f("#content")).not_to contain_css('.discussion-info-icons .icon-lock')
      end

      it "should remove an announcement when it is deleted from the delete option in the cog menu", priority: "1", test_id: 220364 do
        title = "My announcement"
        announcement_model(:title => title, :user => @user)
        get url

        expect(f('.discussion-topic')).not_to be_nil
        f('.discussion-actions .al-trigger').click
        f('.al-options li a.icon-trash').click
        alert_present?
        alert = driver.switch_to.alert
        expect(alert.text).to match "Are you sure you want to delete this announcement?"
        alert.accept
        expect(f("#content")).not_to contain_css('.discussion-topic')
      end

      it "should start a new topic", priority: "1", test_id: 150528 do
        get url

        expect_new_page_load { f('.btn-primary').click }
        edit(@topic_title, 'new topic')
      end

      it "should add an attachment to a new topic", priority: "1", test_id: 150529 do
        topic_title = 'new topic with file'
        get url

        expect_new_page_load { f('.btn-primary').click }
        replace_content(f('input[name=title]'), topic_title)
        add_attachment_and_validate
        expect(what_to_create.where(title: topic_title).first.attachment_id).to be_present
      end

      it "should perform front-end validation for message", priority: "1", test_id: 220366 do
        topic_title = 'new topic with file'
        get url

        expect_new_page_load { f('.btn-primary').click }
        replace_content(f('input[name=title]'), topic_title)
        filename, fullpath, data = get_file("testfile5.zip")
        f('input[name=attachment]').send_keys(fullpath)
        submit_form('.form-actions')
        wait_for_ajaximations

        expect(ff('.error_box').any?{|box| box.text.include?("A message is required")}).to be_truthy
      end

      it "should add an attachment to a graded topic", priority: "1", test_id: 220367 do
        what_to_create == DiscussionTopic ? @course.discussion_topics.create!(:title => 'graded attachment topic', :user => @user) : announcement_model(:title => 'graded attachment topic', :user => @user)
        if what_to_create == DiscussionTopic
          what_to_create.last.update_attributes(:assignment => @course.assignments.create!(:name => 'graded topic assignment'))
        end
        get url
        expect_new_page_load { f('.discussion-title').click }
        expect_new_page_load { f(".edit-btn").click }

        add_attachment_and_validate
      end

      it "should edit a topic", priority: "1", test_id: 150530 do
        edit_name = 'edited discussion name'
        topic = what_to_create == DiscussionTopic ? @course.discussion_topics.create!(:title => @topic_title, :user => @user) : announcement_model(:title => @topic_title, :user => @user)
        get url + "#{topic.id}"
        expect_new_page_load { f(".edit-btn").click }

        edit(edit_name, 'edit message')
      end

      it "should delete a topic", priority: "1", test_id: 150526 do
        what_to_create == DiscussionTopic ? @course.discussion_topics.create!(:title => @topic_title, :user => @user) : announcement_model(:title => @topic_title, :user => @user)
        get url

        f('.toggleSelected').click
        f('#delete').click
        driver.switch_to.alert.accept
        wait_for_ajaximations
        expect(what_to_create.last.workflow_state).to eq 'deleted'
        expect(f("#content")).not_to contain_css('.discussionTopicIndexList')
      end
    end

    it "should create a delayed announcement", priority: "1", test_id: 150531 do
      get course_announcements_path(@course)
      create_announcement_option('input[type=checkbox][name=delay_posting]')
      f('.ui-datepicker-trigger').click
      datepicker_next
      f('.ui-datepicker-time .ui-datepicker-ok').click
      expect_new_page_load { submit_form('.form-actions') }
      expect(f('.discussion-fyi')).to include_text('The content of this announcement will not be visible to users until')
    end

    it "allows creating a delayed announcement with an attachment", priority: "1", test_id: 220369 do
      get course_announcements_path(@course)
      create_announcement_option('input[type=checkbox][name=delay_posting]')
      f('.ui-datepicker-trigger').click
      datepicker_next
      f('.ui-datepicker-time .ui-datepicker-ok').click
      name, path, data = get_file('testfile1.txt')
      f('#discussion_attachment_uploaded_data').send_keys(path)
      expect_new_page_load { submit_form('.form-actions') }
      expect(f('.discussion-fyi')).to include_text('The content of this announcement will not be visible to users until')
    end

    it "should add and remove an external feed to announcements", priority: "1", test_id: 220370 do
      get "/courses/#{@course.id}/announcements"

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
        expect(f("#content")).not_to contain_css('.external_feed')
      }.to change(ExternalFeed, :count).by(-1)
    end

    it "should remove delayed_post_at when unchecking delay_posting", priority: "1", test_id: 220371 do
      topic = @course.announcements.create!(:title => @topic_title, :user => @user, :delayed_post_at => 10.days.ago, :message => "message")
      get "/courses/#{@course.id}/announcements/#{topic.id}"
      expect_new_page_load { f(".edit-btn").click }

      f('input[type=checkbox][name="delay_posting"]').click
      expect_new_page_load { f('.form-actions button[type=submit]').click }

      topic.reload
      expect(topic.delayed_post_at).to be_nil
    end

    it "lets a teacher add a new entry to its own announcement", priority: "1", test_id: 220372 do
      create_announcement
      get [@course, @announcement]
      f('.discussion-reply-action').click
      entry_text = 'new entry text'
      type_in_tiny('textarea', entry_text)
      f('button[type=submit]').click
      wait_for_ajax_requests
      expect(DiscussionEntry.last.message).to include(entry_text)
    end

    it "should show announcements to student view student", priority: "1", test_id: 220373 do
      create_announcement
      enter_student_view
      get "/courses/#{@course.id}/announcements"

      announcement = f('.discussionTopicIndexList .discussion-topic')
      expect(announcement.find_element(:css, '.discussion-summary')).to include_text(@announcement.message)
    end

    it "should always see student replies when 'initial post required' is turned on", priority: "1", test_id: 150524 do
      skip_if_chrome('Student view breaks this test')
      student_entry = 'this is my reply'

      create_announcement_initial

      # Create reply as a student
      enter_student_view
      reply_to_announcement(@announcement.id, student_entry)
      expect_logout_link_present.click

      #As a teacher, verify that you can see the student's reply even though you have not responded
      get "/courses/#{@course.id}/discussion_topics/#{@announcement.id}"
      expect(ff('.discussion_entry .message')[1]).to include_text(student_entry)
    end
  end
end
