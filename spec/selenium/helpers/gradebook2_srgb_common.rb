require File.expand_path(File.dirname(__FILE__) + '/../common')

module Gradebook2SRGBCommon
  def basic_setup(num=1)
    init_course_with_students num
    @course.assignments.create!(
      title: 'Test 1',
      submission_types: 'online_text_entry',
      points_possible: 20,
      grading_type: 'percent'
    )
  end

  def select_assignment(assignment)
    click_option('#assignment_select', assignment.name)
  end
end
