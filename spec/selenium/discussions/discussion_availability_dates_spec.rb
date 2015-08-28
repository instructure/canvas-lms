require File.expand_path(File.dirname(__FILE__) + '/../helpers/assignments_common')
require File.expand_path(File.dirname(__FILE__) + '/../helpers/discussions_common')

describe "discussion availability" do
  include_examples "in-process server selenium tests"

  before :each do
    course_with_teacher_logged_in.course
    @student1 = student_in_course.user
    @discussion_topic1 = @course.discussion_topics.create!(user: @student1,
                                                           title: 'assignment topic title not available',
                                                           message: 'assignment topic message')
    @discussion_topic1.delayed_post_at = 15.seconds.from_now
    @discussion_topic1.save!
  end

  it "should show the appropriate availability dates", priority: "1", test_id: 150522 do
    discussion_topic2 = @course.discussion_topics.create!(user: @teacher,
                                                          title: 'assignment topic title available',
                                                          message: 'assignment topic message')
    discussion_topic2.save!
    discussion_topic3 = @course.discussion_topics.create!(user: @teacher,
                                                          title: 'assignment topic title closed',
                                                          message: 'assignment topic message')
    discussion_topic3.lock_at = 2.days.ago
    discussion_topic3.save!
    assignment_group = @course.assignment_groups.create!(name: 'assignment group')
    assignment = @course.assignments.create!(name: 'assignment', assignment_group: assignment_group,
                                             due_at: Time.zone.now.advance(days: 3))
    discussion_topic4 = @course.discussion_topics.create!(user: @teacher,
                                                          title: 'assignment topic title due date set',
                                                          message: 'assignment topic message',
                                                          assignment: assignment)
    unlock_at_time = @discussion_topic1.delayed_post_at.strftime('%b %-d')
    due_at_time = assignment.due_at.strftime('%b %-d at %-l:%M')
    get "/courses/#{@course.id}/discussion_topics"
    expect(f(" .collectionViewItems .discussion[data-id = '#{@discussion_topic1.id}'] .discussion-date-available")).
                                                                to include_text("Not available until #{unlock_at_time}")
    expect(f(" .collectionViewItems .discussion[data-id = '#{discussion_topic4.id}'] .discussion-due-date")).
                                                                                   to include_text("Due #{due_at_time}")
    expect(f(" .collectionViewItems .discussion[data-id = '#{discussion_topic2.id}'] .discussion-date-available")).
                                                                to include_text("")
    expect(f(" .collectionViewItems .discussion[data-id = '#{discussion_topic3.id}'] .discussion-due-date")).
                                                                to include_text("")

  end

  it "should not allow posting to a delayed discussion created by a student", priority: "1", test_id: 150523 do
    student2 = user_with_pseudonym(username: 'student2@example.com', active_all: 1)
    student_in_course(user: student2)
    user_session(student2)
    unlock_at_time = @discussion_topic1.delayed_post_at.strftime('%b %-d')
    get "/courses/#{@course.id}/discussion_topics"
    expect(f(" .collectionViewItems .discussion[data-id = '#{@discussion_topic1.id}'] .discussion-date-available")).
                                                              to include_text("Not available until #{unlock_at_time}")
    fln('assignment topic title not available').click
    expect(f('.discussion-reply-action')).not_to be_present
    sleep(15.seconds)
    refresh_page
    expect(f('.discussion-reply-action')).to be_present
  end

  it "should show delayed discussion created by student under 'discussions' section", priority: "1", test_id: 150510 do
    user_session(@student1)
    discussion_student_topic = @course.discussion_topics.create!(user: @student1,
                                                                 title: 'assignment topic by student available',
                                                                 message: 'assignment topic message')
    discussion_student_topic.save!
    get "/courses/#{@course.id}/discussion_topics"
    expect(f("#open-discussions li:nth-of-type(1) .discussion-title").text).
                                                                          to include(discussion_student_topic.title)
    expect(f('#open-discussions li:nth-of-type(2) .discussion-title').text).to include(@discussion_topic1.title)
  end
end