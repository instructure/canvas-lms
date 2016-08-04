require File.expand_path(File.dirname(__FILE__) + '/../common')

module SpeedGraderCommon
  def student_submission(options = {})
    submission_model({:assignment => @assignment, :body => "first student submission text"}.merge(options))
  end

  def goto_section(section_id)
    f("#combo_box_container .ui-selectmenu-icon").click
    driver.execute_script("$('#section-menu-link').trigger('mouseenter')")
    f("#section-menu .section_#{section_id}").click
    wait_for_ajaximations
  end

  def set_turnitin_asset(asset, asset_data)
    @submission.turnitin_data ||= {}
    @submission.turnitin_data[asset.asset_string] = asset_data
    @submission.turnitin_data_changed!
    @submission.save!
  end

  def create_and_enroll_students(num_to_create)
    @students = []
    num_to_create.times do |i|
      s = User.create!(:name => "student #{i}")
      @course.enroll_student(s)
      @students << s
    end
    @students
  end

  def add_attachment_student_assignment(_file, student, path)
    attachment = student.attachments.new
    attachment.uploaded_data = Rack::Test::UploadedFile.new(path, Attachment.mimetype(path))
    attachment.save!
    @assignment.submit_homework(student, :submission_type => :online_upload, :attachments => [attachment])
  end

  def submit_and_grade_homework(student, grade)
    @assignment.submit_homework(student)
    @assignment.grade_student(student, :grade => grade)
  end

  # Creates a dummy rubric and scores its criteria as specified in the parameters (passed as strings)
  def setup_and_grade_rubric(score1, score2)
    student_submission
    @association.save!

    get "/courses/#{@course.id}/gradebook/speed_grader?assignment_id=#{@assignment.id}"
    wait_for_ajaximations

    f('.toggle_full_rubric').click
    wait_for_ajaximations
    rubric = f('#rubric_full')

    rubric_inputs = rubric.find_elements(:css, 'input.criterion_points')
    rubric_inputs[0].send_keys(score1)
    rubric_inputs[1].send_keys(score2)
  end

  def clear_grade_and_validate
    @assignment.grade_student @students[0], {grade: ''}
    @assignment.grade_student @students[1], {grade: ''}

    refresh_page
    expect(f('#grading-box-extended')).to have_value ''
    f('#next-student-button').click
    expect(f('#grading-box-extended')).to have_value ''
  end

  def cycle_students_correctly(direction_string)
    current_index = @students.index(@students.find { |l| l.name == f(selectedStudent).text })

    f(direction_string).click

    direction = direction_string.include?(next_) ? 1 : -1
    new_index = (current_index + direction) % @students.length
    student_X_of_X_string = "Student #{new_index + 1} of #{@students.length}"

    f(selectedStudent).text.include?(@students[new_index].name) &&
        f(studentXofXlabel).text.include?(student_X_of_X_string)
  end

  def expand_right_pane
    # attempting to click things that were on the very edge of the page
    # was causing certain specs to flicker. this fixes that issue by
    # increasing the width of the right pane
    driver.execute_script("$('#right_side').width('500px')")
  end

  def submit_comment(text)
    f('#speedgrader_comment_textarea').send_keys(text)
    scroll_into_view('#add_a_comment button[type="submit"]')
    f('#add_a_comment button[type="submit"]').click
    wait_for_ajaximations
  end
end
