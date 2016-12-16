require_relative '../common'
require_relative '../helpers/files_common'
require_relative '../helpers/submissions_common'

describe "submissions" do
  include_context "in-process server selenium tests"
  include FilesCommon
  include SubmissionsCommon

  context 'as a teacher' do

    before(:each) do
      course_with_teacher_logged_in
    end

    it "should allow media comments", priority: "1", test_id: 237032 do
      stub_kaltura
      #pending("failing because it is dependant on an external kaltura system")

      student_in_course
      assignment = create_assignment
      assignment.submissions.create(:user => @student)
      get "/courses/#{@course.id}/assignments/#{assignment.id}/submissions/#{@student.id}"

      # make sure the JS didn't burn any bridges, and submit two
      submit_media_comment_1
      submit_media_comment_2

      # check that the thumbnails show up on the right sidebar
      number_of_comments = driver.execute_script("return $('.comment_list').children().length")
      expect(number_of_comments).to eq 2
    end

    it "should display the grade in grade field", priority: "1", test_id: 237033 do
      student_in_course
      assignment = create_assignment
      assignment.submissions.create(:user => @student)
      assignment.grade_student @student, grade: 2, grader: @teacher
      get "/courses/#{@course.id}/assignments/#{assignment.id}/submissions/#{@student.id}"
      expect(f('.grading_value')[:value]).to eq '2'
    end
  end

  context "student view" do

    before(:each) do
      course_with_teacher_logged_in
    end

    it "should allow a student view student to view/submit assignments", priority: "1", test_id: 237034 do
      skip_if_chrome('Student view breaks test in Chrome')
      @assignment = @course.assignments.create(
          :title => 'Cool Assignment',
          :points_possible => 10,
          :submission_types => "online_text_entry",
          :due_at => Time.now.utc + 2.days)

      enter_student_view
      get "/courses/#{@course.id}/assignments/#{@assignment.id}"

      expect(f('.assignment .title')).to include_text @assignment.title
      f('.submit_assignment_link').click
      assignment_form = f('#submit_online_text_entry_form')
      wait_for_tiny(assignment_form)

      type_in_tiny('#submission_body', 'my assignment submission')
      expect_new_page_load { submit_form(assignment_form) }

      expect(@course.student_view_student.submissions.count).to eq 1
      expect(f('#sidebar_content .details')).to include_text "Turned In!"
    end

    it "should allow a student view student to submit file upload assignments", priority: "1", test_id: 237035 do
      skip_if_chrome('Student view breaks test in Chrome')
      @assignment = @course.assignments.create(
          :title => 'Cool Assignment',
          :points_possible => 10,
          :submission_types => "online_upload",
          :due_at => Time.now.utc + 2.days)

      enter_student_view
      get "/courses/#{@course.id}/assignments/#{@assignment.id}"

      f('.submit_assignment_link').click

      filename, fullpath, data = get_file("testfile1.txt")
      f('.submission_attachment input').send_keys(fullpath)
      expect_new_page_load { f('#submit_file_button').click }

      expect(f('.details .header')).to include_text "Turned In!"
      expect(f('.details')).to include_text "testfile1"
    end
  end
end
