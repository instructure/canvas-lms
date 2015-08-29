require File.expand_path(File.dirname(__FILE__) + '/../helpers/discussions_common')
require File.expand_path(File.dirname(__FILE__) + '/../common')
require File.expand_path(File.dirname(__FILE__) + '/../helpers/assignment_overrides')

describe "discussions" do
  include AssignmentOverridesSeleniumHelper
  include_context 'in-process server selenium tests'

  before do
    @course = course_model
    @course.offer!
    @assignment = @course.assignments.create!(name: 'assignment', assignment_group: @assignment_group,
                                               due_at: Time.zone.now.advance(days:2),
                                               unlock_at: Time.zone.now,
                                               lock_at: Time.zone.now.advance(days:3))
    @discussion_topic = @course.discussion_topics.create!(title: 'Discussion 1',
                                                           message: 'Discussion with multiple due dates',
                                                           assignment: @assignment)
    add_user_specific_due_date_override(@assignment, due_at: Time.zone.now.advance(days:4),
                                         unlock_at: Time.zone.now.advance(days:1),
                                         lock_at: Time.zone.now.advance(days:4))
  end

  it "should be accessible for student in the main section", priority: "1", test_id: 304663 do
    @student1 = user_with_pseudonym(username: 'student1@example.com', active_all: 1)
    student_in_course(course: @course, user: @student1)
    user_session(@student1)
    find_vdd_time(@assignment)
    get "/courses/#{@course.id}/discussion_topics"
    expect(f("#open-discussions .discussion-date-available").text).to include("Available until #{@lock_at_time[0, 6].strip}")
    expect(f("#open-discussions .discussion-due-date").text).to include("Due #{@due_at_time}")
    expect_new_page_load{f('#open-discussions .discussion-title').click}
    expect(f('.discussion-reply-action')).to be_present
  end

  it "should not be accessible for student in the additional section", priority: "1", test_id: 304664 do
    # we can make use of the section created when creating the due date override
    student2 = student_in_section(@new_section)
    user_session(student2)
    find_vdd_time(@override)
    get "/courses/#{@course.id}/discussion_topics"
    expect(f("#open-discussions .discussion-date-available").text).
                                                              to include("Not available until #{@unlock_at_time[0, 6].strip}")
    expect(f("#open-discussions .discussion-due-date").text).to include("Due #{@due_at_time}")
    expect_new_page_load{f('#open-discussions .discussion-title').click}
    expect(f('.discussion-reply-action')).not_to be_present
    expect(f('.discussion-fyi').text).to include("This topic is locked until #{@unlock_at_time}")
  end

  it "should show the due dates and accessible for ta in additional section", priority: "1", test_id: 304665 do
    ta = ta_in_section(@new_section)
    user_session(ta)
    get "/courses/#{@course.id}/discussion_topics/#{@discussion_topic.id}"
    f('.toggle_due_dates').click
    wait_for_ajaximations

    # Find the due, available and lock dates of the assignment(everyone)
    find_vdd_time(@assignment)
    expect(f('.discussion-topic-due-dates')).to be_present
    expect(f('.discussion-topic-due-dates tbody tr td:nth-of-type(1)').text).to include(@due_at_time[0, 6].strip)
    expect(f('.discussion-topic-due-dates tbody tr td:nth-of-type(2)').text).to include('Everyone else')
    expect(f('.discussion-topic-due-dates tbody tr td:nth-of-type(3)').text).to include(@unlock_at_time)
    expect(f('.discussion-topic-due-dates tbody tr td:nth-of-type(4)').text).to include(@lock_at_time)

    # Find the due, available and lock dates of the override(dates assigned to section)
    find_vdd_time(@override)
    expect(f('.discussion-topic-due-dates tbody tr:nth-of-type(2) td:nth-of-type(1)').text).
                                                                                   to include(@due_at_time[0, 6].strip)
    expect(f('.discussion-topic-due-dates tbody tr:nth-of-type(2) td:nth-of-type(2)').text).to include('New Section')
    expect(f('.discussion-topic-due-dates tbody tr:nth-of-type(2) td:nth-of-type(3)').text).
                                                                                 to include(@unlock_at_time)
    expect(f('.discussion-topic-due-dates tbody tr:nth-of-type(2) td:nth-of-type(4)').text).
                                                                                 to include(@lock_at_time)
  end
end
