require File.expand_path(File.dirname(__FILE__) + "/common")

describe "gradebook1" do
  include_examples "in-process server selenium tests"

  before(:each) do
    course_with_teacher_logged_in(:active_all => true)
    @course.update_attribute(:group_weighting_scheme, 'percent')
    @section1 = @course.default_section
    @section2 = @course.course_sections.create!(:name => "Other Section")

    student_in_course(:active_all => true, :name => "Alice Ackers");
    @student1 = @student

    e = student_in_course(:active_all => true, :name => "Zeno Zopp");
    e.course_section = @section2
    e.save!
    @student2 = @student

    @assignments_group = @course.assignment_groups.create!(
      :name => 'Assignments',
      :group_weight => 25
    )
    @projects_group = @course.assignment_groups.create!(
      :name => 'Projects',
      :group_weight => 75
    )
    @project = assignment_model(
      :course => @course,
      :name => 'project',
      :due_at => nil,
      :points_possible => 20,
      :submission_types => 'online_text_entry,online_upload',
      :assignment_group => @projects_group
    )
    @assignment = assignment_model(
      :course => @course,
      :name => 'first assignment',
      :due_at => nil,
      :points_possible => 10,
      :submission_types => 'online_text_entry,online_upload',
      :assignment_group => @assignments_group
    )
    Course.any_instance.stubs(:feature_enabled?).returns(false)
  end

  def switch_to_section(section_name="All")
    f("#gradebook_options").click
    wait_for_ajaximations

    driver.execute_script("$('#instructure_dropdown_list .option:last').click()")
    wait_for_ajaximations
    click_option("#section-to-show", section_name)
    driver.execute_script("$('#section-to-show').parent().parent().find('button').click()")
    wait_for_ajaximations
    sleep 2
  end

  it "should filter by section" do
    get "/courses/#{@course.id}/gradebook"
    wait_for_ajaximations

    switch_to_section(@section1.display_name)
    student_cell = f("#student_#{@student1.id}")
    student_cell.should include_text @student1.sortable_name
    student_cell.should include_text @section1.display_name

    switch_to_section(@section2.display_name)
    student_cell = f("#student_#{@student2.id}")
    student_cell.should include_text @student2.sortable_name
    student_cell.should include_text @section2.display_name
  end

  it "should handle multiple enrollments" do
    @course.enroll_student(@student1, :section => @section2, :allow_multiple_enrollments => true)

    get "/courses/#{@course.id}/gradebook"
    wait_for_ajaximations

    student_cell = f("#student_#{@student1.id}")
    student_cell.should include_text @student1.sortable_name
    student_cell.should include_text @section1.display_name
    student_cell.should include_text @section2.display_name

    switch_to_section(@section1.display_name)
    student_cell = f("#student_#{@student1.id}")
    student_cell.should include_text @student1.sortable_name
    student_cell.should include_text @section1.display_name
    student_cell.should include_text @section2.display_name

    switch_to_section(@section2.display_name)
    student_cell = f("#student_#{@student1.id}")
    student_cell.should include_text @student1.sortable_name
    student_cell.should include_text @section1.display_name
    student_cell.should include_text @section2.display_name
  end

  it "should show turnitin data" do
    s1 = @assignment.submit_homework(@student1, :submission_type => 'online_text_entry', :body => 'asdf')
    s1.update_attribute :turnitin_data, {"submission_#{s1.id}" => {:similarity_score => 0.0, :web_overlap => 0.0, :publication_overlap => 0.0, :student_overlap => 0.0, :state => 'none'}}
    a = attachment_model(:context => @user, :content_type => 'text/plain')
    s2 = @assignment.submit_homework(@student2, :submission_type => 'online_upload', :attachments => [a])
    s2.update_attribute :turnitin_data, {"attachment_#{a.id}" => {:similarity_score => 1.0, :web_overlap => 5.0, :publication_overlap => 0.0, :student_overlap => 0.0, :state => 'acceptable'}}

    get "/courses/#{@course.id}/gradebook"
    wait_for_ajaximations
    ffj('.turnitin:visible').size.should == 2

    # now create a ton of students so that the data loads via ajax
    100.times { |i| student_in_course(:active_all => true, :name => "other guy #{i}") }

    get "/courses/#{@course.id}/gradebook"
    wait_for_ajaximations
    ffj('.turnitin:visible').size.should == 2
  end

  it "should include student view student for grading" do
    @fake_student = @course.student_view_student
    @fake_submission = @assignment.submit_homework(@fake_student, :body => 'fake student submission')

    get "/courses/#{@course.id}/gradebook"
    wait_for_ajaximations

    f("#student_#{@fake_student.id} .display_name").should include_text @fake_student.sortable_name
  end

  it "should link to the correct student in speedgrader" do
    s1 = @assignment.submit_homework(@student1, :submission_type => 'online_text_entry', :body => 'asdf')
    s2 = @assignment.submit_homework(@student2, :submission_type => 'online_text_entry', :body => 'heyo')

    get "/courses/#{@course.id}/gradebook"
    wait_for_ajaximations

    keep_trying_until {
      fj('#datagrid_data .row:nth-child(3) .cell:first .grade').click
      fj('#submission_information').should be_displayed
    }
    link_el = f('#submission_information .submission_details .view_submission_link')
    URI.decode(URI.parse(link_el.attribute(:href)).fragment).should == "{\"student_id\":#{@student2.id}}"
  end

  def wait_for_grades
    keep_trying_until {
      f("[id^=submission][id$=final-grade]").text =~ /%/
    }
  end

  def grade_student(student, assignment, score)
    f("#submission_#{student.id}_#{assignment.id}").click
    grade_input_box = fj("[id=student_grading_#{assignment.id}]:visible")
    grade_input_box.send_keys(score)
    grade_input_box.send_keys(:tab)
  end

  def final_grade_for(student)
    f("#submission_#{student.id}_final-grade").text
  end

  def toggle_group_weighting_scheme
    fj('#gradebook_options:visible').click
    ff('#instructure_dropdown_list .option').find { |o|
      o.text =~ /Set Group Weights/
    }.click

    f('#class_weighting_policy').click
    fj('button:contains(Done):visible').click
  end

  it "allows you to toggle the group_weighting_scheme" do
    get "/courses/#{@course.id}/gradebook"
    wait_for_grades

    grade_student(@student1, @assignment, 2)
    grade_student(@student1, @project, 20)

    wait_for_ajaximations

    final_grade_for(@student1).to_f.should == 80 # (2/10*.25) + (20/20*.75)

    toggle_group_weighting_scheme

    keep_trying_until { final_grade_for(@student1).to_f != 80 }
    final_grade_for(@student1).to_f.should == 73.3 # (2+20)/(10+20)
  end
end
