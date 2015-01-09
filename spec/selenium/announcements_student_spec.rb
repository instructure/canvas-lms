require File.expand_path(File.dirname(__FILE__) + '/common')
require File.expand_path(File.dirname(__FILE__) + '/helpers/announcements_common')

describe "announcements" do
  include_examples "in-process server selenium tests"

  it "should validate replies are not visible until after users post" do
    password = 'asdfasdf'
    student_2_entry = 'reply from student 2'
    topic_title = 'new replies hidden until post topic'

    course
    @course.offer
    student = user_with_pseudonym({:unique_id => 'student@example.com', :password => password})
    teacher = user_with_pseudonym({:unique_id => 'teacher@example.com', :password => password})
    @course.enroll_user(student, 'StudentEnrollment').accept!
    @course.enroll_user(teacher, 'TeacherEnrollment').accept!
    login_as(teacher.primary_pseudonym.unique_id, password)

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

    login_as(student.primary_pseudonym.unique_id, password)
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

    it "should not show an announcements section if there are no announcments" do
      get "/courses/#{@course.id}"
      expect(f(".announcements active")).to be_nil
    end

    it "should not show JSON when loading more announcements via pageless" do
      50.times { @course.announcements.create!(:title => 'Hi there!', :message => 'Announcement time!') }
      get "/courses/#{@course.id}/announcements"

      start = ff(".discussionTopicIndexList .discussion-topic").length
      driver.execute_script('window.scrollTo(0, 100000)')
      keep_trying_until { ffj(".discussionTopicIndexList .discussion-topic").length > start }

      expect(f(".discussionTopicIndexList")).not_to include_text('discussion_topic')
    end

    it "should validate that a student can not see an announcement with a delayed posting date" do
      announcement_title = 'Hi there!'
      announcement = @course.announcements.create!(:title => announcement_title, :message => 'Announcement time!', :delayed_post_at => Time.now + 1.day)
      get "/courses/#{@course.id}/announcements"
      wait_for_ajaximations

      expect(f('#content')).to include_text('There are no announcements to show')
      announcement.update_attributes(:delayed_post_at => nil)
      announcement.reload
      refresh_page # in order to see the announcement
      expect(f(".discussion-topic")).to include_text(announcement_title)
    end

    it "should allow a group member to create an announcement" do
      gc = group_category
      group = gc.groups.create!(:context => @course)
      group.add_user(@student, 'accepted')

      get "/groups/#{group.id}/announcements"
      wait_for_ajaximations
      expect {
        create_announcement_option(nil)
        expect_new_page_load { submit_form('.form-actions') }
      }.to change(Announcement, :count).by 1
    end

    it "should have deleted announcement removed from student account" do
      @announcement = @course.announcements.create!(:title => 'delete me', :message => 'Here is my message')
      get "/courses/#{@course.id}/announcements/"
      expect(f(".discussion-title")).to include_text('delete me')
      @announcement.destroy
      get "/courses/#{@course.id}/announcements/"
      expect(f(".discussion-title")).to be_nil
    end
  end
end