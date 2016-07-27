require_relative '../common'
require_relative '../helpers/announcements_common'

describe "announcements" do
  include_context "in-process server selenium tests"
  include AnnouncementsCommon

  it "should validate replies are not visible until after users post", priority: "1", test_id: 150533 do
    password = 'asdfasdf'
    student_2_entry = 'reply from student 2'
    topic_title = 'new replies hidden until post topic'

    course
    @course.offer
    student = user_with_pseudonym(:unique_id => 'student@example.com', :password => password, :active_user => true)
    teacher = user_with_pseudonym(:unique_id => 'teacher@example.com', :password => password, :active_user => true)
    @course.enroll_user(student, 'StudentEnrollment').accept!
    @course.enroll_user(teacher, 'TeacherEnrollment').accept!
    create_session(teacher.primary_pseudonym)

    get "/courses/#{@course.id}/announcements"
    expect_new_page_load { f('.btn-primary').click }
    replace_content(f('input[name=title]'), topic_title)
    type_in_tiny('textarea[name=message]', 'hi, first announcement')
    f('#require_initial_post').click
    wait_for_ajaximations
    expect_new_page_load { submit_form('.form-actions') }
    announcement = Announcement.where(title: topic_title).first
    expect(announcement[:require_initial_post]).to eq true
    student_2 = student_in_course.user
    announcement.discussion_entries.create!(:user => student_2, :message => student_2_entry)

    create_session(student.primary_pseudonym)
    get "/courses/#{@course.id}/announcements/#{announcement.id}"
    expect(f('#discussion_subentries span').text).to eq "Replies are only visible to those who have posted at least one reply."
    ff('.discussion_entry').each { |entry| expect(entry).not_to include_text(student_2_entry) }
    f('.discussion-reply-action').click
    wait_for_ajaximations
    type_in_tiny('textarea', 'reply')
    submit_form('#discussion_topic .discussion-reply-form')
    wait_for_ajaximations
    expect(ff('.discussion_entry .message')[1]).to include_text(student_2_entry)
  end

  context "announcements as a student" do
    before (:each) do
      course_with_student_logged_in
    end

    it "should not show an announcements section if there are no announcements", priority: "1", test_id: 150534 do
      get "/courses/#{@course.id}"
      expect(f("#content")).not_to contain_css(".announcements active")
    end

    it "should not show JSON when loading more announcements via pageless", priority: "2", test_id: 220375 do
      50.times { @course.announcements.create!(:title => 'Hi there!', :message => 'Announcement time!') }
      get "/courses/#{@course.id}/announcements"

      start = ff(".discussionTopicIndexList .discussion-topic").length
      scroll_page_to_bottom
      expect(ff(".discussionTopicIndexList .discussion-topic")).not_to have_size(start)

      expect(f(".discussionTopicIndexList")).not_to include_text('discussion_topic')
    end

    it "should validate that a student can not see an announcement with a delayed posting date", priority: "1", test_id: 220376 do
      announcement_title = 'Hi there!'
      announcement = @course.announcements.create!(:title => announcement_title, :message => 'Announcement time!', :delayed_post_at => Time.now + 1.day)
      get "/courses/#{@course.id}/announcements"

      expect(f('#content')).to include_text('There are no announcements to show')
      announcement.update_attributes(:delayed_post_at => nil)
      announcement.reload
      refresh_page # in order to see the announcement
      expect(f(".discussion-topic")).to include_text(announcement_title)
    end

    it "should not allow a student to close/open announcement for comments or delete an announcement", priority: "1", test_id: 220377 do
      announcement_title = "Announcement 1"
      announcement = @course.announcements.create!(:title => announcement_title, :message => "Hey")
      get "/courses/#{@course.id}/announcements"
      wait_for_ajaximations

      expect(f("#content")).not_to contain_css('.discussion_actions a.al-trigger')
      expect(f("#content")).not_to contain_css('.discussion_actions ul.al-options')
    end

    it "should allow a group member to create an announcement", priority: "1", test_id: 220378 do
      gc = group_category
      group = gc.groups.create!(:context => @course)
      group.add_user(@student, 'accepted')

      get "/groups/#{group.id}/announcements"
      expect {
        create_announcement_option(nil)
        expect_new_page_load { submit_form('.form-actions') }
      }.to change(Announcement, :count).by 1
    end

    it "should have deleted announcement removed from student account", priority: "1", test_id: 220379 do
      @announcement = @course.announcements.create!(:title => 'delete me', :message => 'Here is my message')
      get "/courses/#{@course.id}/announcements/"
      expect(f(".discussion-title")).to include_text('delete me')
      @announcement.destroy
      get "/courses/#{@course.id}/announcements/"
      expect(f("#content")).not_to contain_css(".discussion-title")
    end

    it "should remove notifications from unenrolled courses", priority: "1", test_id: 220380 do
      enable_cache do
        @student.enrollments.first.update_attribute(:workflow_state, 'active')
        @course.announcements.create!(:title => 'Something', :message => 'Announcement time!')
        get "/"
        f('#dashboardToggleButton').click if ENV['CANVAS_FORCE_USE_NEW_STYLES']
        expect(ff('.title .count')[0].text).to eq '1'
        @student.enrollments.first.update_attribute(:workflow_state, 'deleted')
        get "/"
        expect(f("#content")).not_to contain_css('.title .count')
      end
    end

    it "allows rating when enabled", priority: "1", test_id: 603587 do
      announcement = @course.announcements.create!(title: 'stuff', message: 'things', allow_rating: true)
      get "/courses/#{@course.id}/discussion_topics/#{announcement.id}"

      f('.discussion-reply-action').click
      wait_for_ajaximations
      type_in_tiny('textarea', 'stuff and things')
      submit_form('.discussion-reply-form')
      wait_for_ajaximations

      expect(f('.discussion-rate-action')).to be_displayed

      f('.discussion-rate-action').click
      wait_for_ajaximations

      expect(f('.discussion-rate-action--checked')).to be_displayed
    end

    it "doesn't allow rating when not enabled", priority: "1", test_id: 603588 do
      announcement = @course.announcements.create!(title: 'stuff', message: 'things', allow_rating: false)
      get "/courses/#{@course.id}/discussion_topics/#{announcement.id}"

      f('.discussion-reply-action').click
      wait_for_ajaximations
      type_in_tiny('textarea', 'stuff and things')
      submit_form('.discussion-reply-form')
      wait_for_ajaximations

      expect(f("#content")).not_to contain_css('.discussion-rate-action')
    end
  end
end
