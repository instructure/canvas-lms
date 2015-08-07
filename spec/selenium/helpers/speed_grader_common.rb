require File.expand_path(File.dirname(__FILE__) + '/../common')

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

def add_attachment_student_assignment(file, student, path)
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
  expect(f('#grading-box-extended').attribute 'value').to eq ''
  f('a.next').click
  expect(f('#grading-box-extended').attribute 'value').to eq ''
end
