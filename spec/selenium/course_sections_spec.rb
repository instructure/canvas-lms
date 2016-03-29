require File.expand_path(File.dirname(__FILE__) + '/common')

describe "course sections" do
  include_context "in-process server selenium tests"

  def add_enrollment(enrollment_state, section)
    enrollment = student_in_course(:workflow_state => enrollment_state, :course_section => section)
    enrollment.accept! if enrollment_state == 'active' || enrollment_state == 'completed'
  end

  def table_rows
    ff('#enrollment_table tr')
  end

  before (:each) do
    course_with_teacher_logged_in
    @section = @course.default_section
  end

  it "should validate the display when multiple enrollments exist" do
    add_enrollment('active', @section)
    get "/courses/#{@course.id}/sections/#{@section.id}"

    wait_for_ajaximations
    expect(table_rows.count).to eq 1
    expect(table_rows[0]).to include_text('2 Active Enrollments')
  end

  it "should validate the display when only 1 enrollment exists" do
    get "/courses/#{@course.id}/sections/#{@section.id}"

    wait_for_ajaximations
    expect(table_rows.count).to eq 1
    expect(table_rows[0]).to include_text('1 Active Enrollment')
  end

  it "should display the correct pending enrollments count" do
    add_enrollment('pending', @section)
    add_enrollment('invited', @section)
    get "/courses/#{@course.id}/sections/#{@section.id}"

    wait_for_ajaximations
    expect(table_rows.count).to eq 2
    expect(table_rows[0]).to include_text('2 Pending Enrollments')
  end

  it "should display the correct completed enrollments count" do
    add_enrollment('completed', @section)
    @course.complete!
    get "/courses/#{@course.id}/sections/#{@section.id}"

    wait_for_ajaximations
    expect(table_rows.count).to eq 1
    expect(table_rows[0]).to include_text('2 Completed Enrollments')
  end

  it "should edit the section" do
    edit_name = 'edited section name'
    get "/courses/#{@course.id}/sections/#{@section.id}"

    f('.edit_section_link').click
    edit_form = f('#edit_section_form')
    replace_content(edit_form.find_element(:id, 'course_section_name'), edit_name)
    submit_form(edit_form)
    wait_for_ajaximations
    expect(f('#section_name')).to include_text(edit_name)
  end

  it "should parse dates" do
    get "/courses/#{@course.id}/sections/#{@section.id}"

    f('.edit_section_link').click
    edit_form = f('#edit_section_form')
    replace_content(edit_form.find_element(:id, 'course_section_start_at'), '1/2/15')
    replace_content(edit_form.find_element(:id, 'course_section_end_at'), '04 Mar 2015')
    submit_form(edit_form)
    wait_for_ajax_requests
    @section.reload
    expect(@section.start_at).to eq(Date.new(2015, 1, 2))
    expect(@section.end_at).to eq(Date.new(2015, 3, 4))
  end
end