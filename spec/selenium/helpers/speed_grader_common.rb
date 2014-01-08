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
