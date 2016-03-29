require File.expand_path(File.dirname(__FILE__) + "/common")

describe "gradebook uploads" do
  include_context "in-process server selenium tests"

  before do
    course_with_teacher_logged_in(:active_all => 1, :username => 'teacher@example.com')
    @student = user(:username => 'student@example.com', :active_all => 1)
    @course.enroll_student(@student).accept!

    get "/courses/#{@course.id}/gradebook_uploads/new"
    @upload_element = f('#gradebook_upload_uploaded_data')
    @upload_form = f('#new_gradebook_upload')
  end

  def gradebook_file(filename, *rows)
    get_file(filename, rows.join("\n"))
  end

  def assert_assignment_is_highlighted
    expect(ff('.left-highlight').length).to eq 1
    expect(ff('.right-highlight').length).to eq 1
  end

  def assert_assignment_is_not_highlighted
    expect(ff('.left-highlight').length).to be 0
    expect(ff('.right-highlight').length).to be 0
  end

  it "should correctly update grades for assignments with GPA Scale grading type",priority: "1", test_id: 209969 do
    assignment = @course.assignments.create!(:title => "GPA Scale Assignment",
      :grading_type => "gpa_scale", :points_possible => 5)
    assignment.grade_student(@student, :grade => "D")
    filename, fullpath, data = gradebook_file("gradebook0.csv",
      "Student Name,ID,Section,GPA Scale Assignment",
      "User,#{@student.id},,B-")
    @upload_element.send_keys(fullpath)
    @upload_form.submit
    run_jobs
    wait_for_ajaximations
    keep_trying_until { !f("#spinner").displayed? }
    submit_form('#gradebook_grid_form')
    driver.switch_to.alert.accept
    wait_for_ajaximations
    run_jobs
    expect(assignment.submissions.last.grade).to eq "B-"
  end

  it "should say no changes if no changes", priority: "1", test_id: 209970 do
    assignment = @course.assignments.create!(:title => "Assignment 1")
    assignment.grade_student(@student, :grade => 10)

    filename, fullpath, data = gradebook_file("gradebook1.csv",
          "Student Name,ID,Section,Assignment 1",
          "User,#{@student.id},,10")
    @upload_element.send_keys(fullpath)
    @upload_form.submit
    wait_for_ajaximations
    run_jobs

  expect(f('#gradebook_importer_resolution_section')).not_to be_displayed
  end

  it "should show only changed assignment", priority: "1", test_id: 209972 do
    assignment1 = @course.assignments.create!(:title => "Assignment 1")
    assignment1.grade_student(@student, :grade => 10)
    assignment2 = @course.assignments.create!(:title => "Assignment 2")
    assignment2.grade_student(@student, :grade => 10)

    filename, fullpath, data = gradebook_file("gradebook2.csv",
          "Student Name,ID,Section,Assignment 1,Assignment 2",
          "User,#{@student.id},,10,9")
    @upload_element.send_keys(fullpath)
    @upload_form.submit
    wait_for_ajaximations
    run_jobs

    expect(f('#gradebook_importer_resolution_section')).not_to be_displayed
    expect(f('#no_changes_detected')).not_to be_displayed

    expect(ff('.slick-header-column.assignment').length).to eq 1
    expect(f('#assignments_without_changes_alert')).to be_displayed
  end

  it "should show a new assignment", priority: "1", test_id: 209975 do
    filename, fullpath, data = gradebook_file("gradebook3.csv",
      "Student Name,ID,Section,New Assignment",
      "User,#{@student.id},,0")
    @upload_element.send_keys(fullpath)
    @upload_form.submit
    wait_for_ajaximations
    run_jobs

    keep_trying_until { !f("#spinner").displayed? }
    expect(f('#gradebook_importer_resolution_section')).to be_displayed

    expect(ff('.assignment_section #assignment_resolution_template').length).to eq 1
    expect(f('.assignment_section #assignment_resolution_template .title').text).to eq 'New Assignment'

    click_option('.assignment_section #assignment_resolution_template select', 'new', :value)

    submit_form('#gradebook_importer_resolution_section')

    expect(f('#no_changes_detected')).not_to be_displayed

    expect(ff('.slick-header-column.assignment').length).to eq 1
    expect(f('#assignments_without_changes_alert')).not_to be_displayed

    assignment_count = @course.assignments.count
    submit_form('#gradebook_grid_form')
    accept_alert
    wait_for_ajaximations
    run_jobs
    expect(@course.assignments.count).to eql (assignment_count + 1)
    assignment = @course.assignments.order(:created_at).last
    submission = assignment.submissions.last
    expect(submission.score).to eq 0

  end

  it "should say no changes if no changes after matching assignment" do
    assignment = @course.assignments.create!(:title => "Assignment 1")
    assignment.grade_student(@student, :grade => 10)

    filename, fullpath, data = gradebook_file("gradebook4.csv",
          "Student Name,ID,Section,Assignment 2",
          "User,#{@student.id},,10")
    @upload_element.send_keys(fullpath)
    @upload_form.submit
    wait_for_ajaximations
    run_jobs

    keep_trying_until { !f("#spinner").displayed? }
    expect(f('#gradebook_importer_resolution_section')).to be_displayed

    expect(ff('.assignment_section #assignment_resolution_template').length).to eq 1
    expect(f('.assignment_section #assignment_resolution_template .title').text).to eq 'Assignment 2'

    click_option('.assignment_section #assignment_resolution_template select', assignment.id.to_s, :value)

    submit_form('#gradebook_importer_resolution_section')

    expect(f('#no_changes_detected')).to be_displayed
  end

  it "should show assignment with changes after matching assignment", priority: "1", test_id: 209977 do
    assignment1 = @course.assignments.create!(:title => "Assignment 1")
    assignment1.grade_student(@student, :grade => 10)
    assignment2 = @course.assignments.create!(:title => "Assignment 2")
    assignment2.grade_student(@student, :grade => 10)

    filename, fullpath, data = gradebook_file("gradebook5.csv",
          "Student Name,ID,Section,Assignment 1,Assignment 3",
          "User,#{@student.id},,10,9")
    @upload_element.send_keys(fullpath)
    @upload_form.submit
    wait_for_ajaximations
    run_jobs

    keep_trying_until { !f("#spinner").displayed? }
    expect(f('#gradebook_importer_resolution_section')).to be_displayed

    expect(ff('.assignment_section #assignment_resolution_template').length).to eq 1
    expect(f('.assignment_section #assignment_resolution_template .title').text).to eq 'Assignment 3'

    click_option('.assignment_section #assignment_resolution_template select', assignment2.id.to_s, :value)

    submit_form('#gradebook_importer_resolution_section')

    keep_trying_until { !f("#spinner").displayed? }
    expect(f('#no_changes_detected')).not_to be_displayed

    expect(ff('.slick-header-column.assignment').length).to eq 1
    expect(f('#assignments_without_changes_alert')).to be_displayed
  end

  it "should say no changes after matching student", priority: "1", test_id: 209978  do
    assignment = @course.assignments.create!(:title => "Assignment 1")
    assignment.grade_student(@student, :grade => 10)

    filename, fullpath, data = gradebook_file("gradebook6.csv",
          "Student Name,ID,Section,Assignment 1",
          "Student,,,10")
    @upload_element.send_keys(fullpath)
    @upload_form.submit
    wait_for_ajaximations
    run_jobs

    keep_trying_until { !f("#spinner").displayed? }
    expect(f('#gradebook_importer_resolution_section')).to be_displayed

    expect(ff('.student_section #student_resolution_template').length).to eq 1
    expect(f('.student_section #student_resolution_template .name').text).to eq 'Student'

    click_option('.student_section #student_resolution_template select', @student.id.to_s, :value)

    submit_form('#gradebook_importer_resolution_section')

    expect(f('#no_changes_detected')).to be_displayed
  end

  it "should show assignment with changes after matching student", priority: "1", test_id: 209979 do
    assignment1 = @course.assignments.create!(:title => "Assignment 1")
    assignment1.grade_student(@student, :grade => 10)
    assignment2 = @course.assignments.create!(:title => "Assignment 2")
    assignment2.grade_student(@student, :grade => 10)

    filename, fullpath, data = gradebook_file("gradebook7.csv",
          "Student Name,ID,Section,Assignment 1,Assignment 2",
          "Student,,,10,9")
    @upload_element.send_keys(fullpath)
    @upload_form.submit
    wait_for_ajaximations
    run_jobs

    keep_trying_until { !f("#spinner").displayed? }
    expect(f('#gradebook_importer_resolution_section')).to be_displayed

    expect(ff('.student_section #student_resolution_template').length).to eq 1
    expect(f('.student_section #student_resolution_template .name').text).to eq 'Student'

    click_option('.student_section #student_resolution_template select', @student.id.to_s, :value)

    submit_form('#gradebook_importer_resolution_section')

    expect(f('#no_changes_detected')).not_to be_displayed

    expect(ff('.slick-header-column.assignment').length).to eq 1
    expect(f('#assignments_without_changes_alert')).to be_displayed
  end

  it "should highlight scores if the original grade is more than the new grade", priority: "1", test_id: 209981 do
    assignment1 = @course.assignments.create!(:title => "Assignment 1")
    assignment1.grade_student(@student, :grade => 10)

    filename, fullpath, data = gradebook_file("gradebook2.csv",
          "Student Name,ID,Section,Assignment 1",
          "User,#{@student.id},,9")

    @upload_element.send_keys(fullpath)
    @upload_form.submit
    wait_for_ajaximations
    run_jobs
    keep_trying_until { !f("#spinner").displayed? }

    assert_assignment_is_highlighted
  end

  it "should highlight scores if the original grade is replaced by empty grade", priority: "1", test_id: 209982 do
    assignment1 = @course.assignments.create!(:title => "Assignment 1")
    assignment1.grade_student(@student, :grade => 10)

    filename, fullpath, data = gradebook_file("gradebook2.csv",
          "Student Name,ID,Section,Assignment 1",
          "User,#{@student.id},,")

    @upload_element.send_keys(fullpath)
    @upload_form.submit
    wait_for_ajaximations
    run_jobs
    keep_trying_until { !f("#spinner").displayed? }

    assert_assignment_is_highlighted
  end

  it "should not highlight scores if the original grade is less than the new grade", priority: "1", test_id: 209983 do
    assignment1 = @course.assignments.create!(:title => "Assignment 1")
    assignment1.grade_student(@student, :grade => 10)

    filename, fullpath, data = gradebook_file("gradebook2.csv",
          "Student Name,ID,Section,Assignment 1",
          "User,#{@student.id},,100")

    @upload_element.send_keys(fullpath)
    @upload_form.submit
    wait_for_ajaximations
    run_jobs
    keep_trying_until { !f("#spinner").displayed? }

    assert_assignment_is_not_highlighted
  end

  it "should not highlight scores if the assignment is excused", priority: "1", test_id: 209983 do
    assignment1 = @course.assignments.create!(:title => "Assignment 1")
    assignment1.grade_student(@student, :grade => 10)

    filename, fullpath, data = gradebook_file("gradebook2.csv",
          "Student Name,ID,Section,Assignment 1",
          "User,#{@student.id},,EX")

    @upload_element.send_keys(fullpath)
    @upload_form.submit
    wait_for_ajaximations
    run_jobs
    keep_trying_until { !f("#spinner").displayed? }

    assert_assignment_is_not_highlighted
  end
end
