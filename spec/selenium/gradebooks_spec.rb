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
        :points_possible => 10,
        :submission_types => 'online_text_entry,online_upload'
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
    @course.enroll_student(@student1, :section => @section2, :allow_multiple_enrollments => true)

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

  it "should show turnitin data" do
    s1 = @assignment.submit_homework(@student1, :submission_type => 'online_text_entry', :body => 'asdf')
    s1.update_attribute :turnitin_data, {"submission_#{s1.id}" => {:similarity_score => 0.0, :web_overlap => 0.0, :publication_overlap => 0.0, :student_overlap => 0.0, :state => 'none'}}
    a = attachment_model(:context => @user, :content_type => 'text/plain')
    s2 = @assignment.submit_homework(@student2, :submission_type => 'online_upload', :attachments => [a])
    s2.update_attribute :turnitin_data, {"attachment_#{a.id}" => {:similarity_score => 1.0, :web_overlap => 5.0, :publication_overlap => 0.0, :student_overlap => 0.0, :state => 'acceptable'}}

    get "/courses/#{@course.id}/gradebook"
    wait_for_ajaximations
    ffj('img.turnitin:visible').size.should eql 2

    # now create a ton of students so that the data loads via ajax
    100.times { |i| student_in_course(:active_all => true, :name => "other guy #{i}") }

    get "/courses/#{@course.id}/gradebook"
    wait_for_ajaximations
    ffj('img.turnitin:visible').size.should eql 2
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
      fj('#submission_information').displayed?
    }
    link_el = f('#submission_information .submission_details .view_submission_link')
    URI.decode(URI.parse(link_el.attribute(:href)).fragment).should == "{\"student_id\":#{@student2.id}}"
  end
end
