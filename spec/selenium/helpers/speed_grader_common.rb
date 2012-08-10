require File.expand_path(File.dirname(__FILE__) + '/../common')

shared_examples_for "speed grader tests" do
  it_should_behave_like "in-process server selenium tests"

  before (:each) do
    stub_kaltura

    course_with_teacher_logged_in
    outcome_with_rubric
    @assignment = @course.assignments.create(:name => 'assignment with rubric')
    @association = @rubric.associate_with(@assignment, @course, :purpose => 'grading')
  end

  def student_submission(options = {})
    submission_model({:assignment => @assignment, :body => "first student submission text"}.merge(options))
  end

  def goto_section(section_id)
    f("#combo_box_container .ui-selectmenu-icon").click
    driver.execute_script("$('#section-menu-link').trigger('mouseenter')")
    f("#section-menu .section_#{section_id}").click
    wait_for_dom_ready
    wait_for_ajaximations
  end

  def set_turnitin_asset(asset, asset_data)
    @submission.turnitin_data ||= {}
    @submission.turnitin_data[asset.asset_string] = asset_data
    @submission.turnitin_data_changed!
    @submission.save!
  end
end