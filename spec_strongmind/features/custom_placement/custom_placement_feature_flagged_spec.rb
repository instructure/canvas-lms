
require_relative '../../rails_helper'

RSpec.describe 'As a System with custom placement behind feature flag', type: :feature, js: true do

  include_context 'stubbed_network'

  before(:each) do
    student_in_course(active_all: true)
    course_with_teacher_logged_in(course: @course)
  end

  it "should be off by default" do
    visit "/courses/#{@course.id}"
    allow(@teacher.teacher_enrollments.last).to receive(:has_permission_to?).with(:read_roster).and_return(true)
    allow(@teacher.teacher_enrollments.last).to receive(:has_permission_to?).with(:manage_grades).and_return(true)
    allow(@teacher.teacher_enrollments.last).to receive(:has_permission_to?).with(:custom_placement).and_return(false)

    click_link 'People'

    within find("#user_#{@student.id}") do
      find('.al-trigger').click()
      sleep 2
      expect(page).not_to have_selector('a[href="#"][data-event=editEnrollments]', text: 'Custom Placement')
    end
  end

  it "can be turned on with a 'enable_custom_placement' feature flag" do
    visit "/courses/#{@course.id}"

    allow_any_instance_of(TeacherEnrollment).to receive(:has_permission_to?).and_return(true)

    click_link 'People'

    within find("#user_#{@student.id}") do
      find('.al-trigger').click()
      sleep 2
      expect(page).to have_selector('a[href="#"][data-event=editEnrollments]', text: 'Custom Placement')
    end
  end
end
