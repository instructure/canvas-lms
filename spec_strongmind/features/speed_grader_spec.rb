
require_relative '../rails_helper'

RSpec.describe 'Speedgrader improvements for teacher productivity', type: :feature, js: true do

  before(:each) do
    course_with_teacher_logged_in
    outcome_with_rubric
    @assignment = @course.assignments.create(
      name: 'some topic',
      points_possible: 10,
      submission_types: 'discussion_topic',
      description: 'a little bit of content'
    )
    student = user_with_pseudonym(
      :name        => 'first student',
      :active_user => true,
      :username    => 'student@example.com',
      :password    => 'qwertyuiop'
    )
    @course.enroll_user(student, "StudentEnrollment", :enrollment_state => 'active')
    # create and enroll second student
    student_2 = user_with_pseudonym(
      :name        => 'second student',
      :active_user => true,
      :username    => 'student2@example.com',
      :password    => 'qwertyuiop'
    )
    @course.enroll_user(student_2, "StudentEnrollment", :enrollment_state => 'active')

    # create discussion entries
    @first_message    = 'first student message'
    @second_message   = 'second student message'
    @discussion_topic = DiscussionTopic.find_by_assignment_id(@assignment.id)

    entry = @discussion_topic.discussion_entries.
        create!(:user => student, :message => @first_message)
    entry.update_topic
    entry.context_module_action

    @attachment_thing = attachment_model(:context => student_2, :filename => 'horse.doc', :content_type => 'application/msword')

    entry_2 = @discussion_topic.discussion_entries.
        create!(:user => student_2, :message => @second_message, :attachment => @attachment_thing)
    entry_2.update_topic
    entry_2.context_module_action
  end

  it "displays discussion topic title and content to give the teacher more context when grading discussion boards responses" do
    visit "/courses/#{@course.id}/gradebook/speed_grader?assignment_id=#{@assignment.id}"

    expect(page).to have_selector('#speedgrader_iframe')
    sleep 2

    # check for discussion topic content above replies in speed grader iframe
    within_frame(find('#speedgrader_iframe')) do
      expect(page).to have_selector('.discussion-title', text: @discussion_topic.title)
      expect(page).to have_selector('.discussion-section', text: @discussion_topic.message)
    end
  end
end
