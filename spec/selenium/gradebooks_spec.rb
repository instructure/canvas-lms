require File.expand_path(File.dirname(__FILE__) + "/common")

describe "gradebooks" do
  it_should_behave_like "in-process server selenium tests"

  before(:each) do
    course_with_teacher_logged_in(:active_all => true)
    @section1 = @course.default_section
    @section2 = @course.course_sections.create!(:name => "Other Section")

    student_in_course(:active_all => true, :name => "Alice Ackers");
    @student1 = @student

    e = student_in_course(:active_all => true, :name => "Zeno Zopp");
    e.course_section = @section2
    e.save!
    @student2 = @student

    @assignment = assignment_model(
      {
        :course => @course,
        :name => 'first assignment',
        :due_at => nil,
        :points_possible => 10
      }
    )
  end

  def switch_to_section(section_name="All")
    driver.find_element(:id, "gradebook_options").click

    driver.execute_script("$('#instructure_dropdown_list .option:last').click()")
    click_option("#section-to-show", section_name)
    driver.execute_script("$('#section-to-show').parent().parent().find('button').click()")
    wait_for_dom_ready
  end

  it "should filter by section" do
    get "/courses/#{@course.id}/gradebook"
    wait_for_ajaximations

    switch_to_section(@section1.display_name)
    student_cell = driver.find_element(:id, "student_#{@student1.id}")
    student_cell.should include_text @student1.sortable_name
    student_cell.should include_text @section1.display_name

    switch_to_section(@section2.display_name)
    student_cell = driver.find_element(:id, "student_#{@student2.id}")
    student_cell.should include_text @student2.sortable_name
    student_cell.should include_text @section2.display_name
  end

  it "should handle multiple enrollments" do
    @course.student_enrollments.create!(:user => @student1, :course_section => @section2)

    get "/courses/#{@course.id}/gradebook"
    wait_for_ajaximations

    student_cell = driver.find_element(:id, "student_#{@student1.id}")
    student_cell.should include_text @student1.sortable_name
    student_cell.should include_text @section1.display_name
    student_cell.should include_text @section2.display_name

    switch_to_section(@section1.display_name)
    student_cell = driver.find_element(:id, "student_#{@student1.id}")
    student_cell.should include_text @student1.sortable_name
    student_cell.should include_text @section1.display_name
    student_cell.should include_text @section2.display_name

    switch_to_section(@section2.display_name)
    student_cell = driver.find_element(:id, "student_#{@student1.id}")
    student_cell.should include_text @student1.sortable_name
    student_cell.should include_text @section1.display_name
    student_cell.should include_text @section2.display_name
  end
end
