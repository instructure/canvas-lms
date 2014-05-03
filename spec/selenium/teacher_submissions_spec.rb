require File.expand_path(File.dirname(__FILE__) + '/common')
require File.expand_path(File.dirname(__FILE__) + '/helpers/files_common')
require File.expand_path(File.dirname(__FILE__) + '/helpers/submissions_common')

describe "submissions" do
  include_examples "in-process server selenium tests"

  context 'as a teacher' do

    before (:each) do
      course_with_teacher_logged_in
    end

    it "should allow media comments" do
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
      number_of_comments.should == 2
    end

    it "should display the grade in grade field" do
      student_in_course
      assignment = create_assignment
      assignment.submissions.create(:user => @student)
      assignment.grade_student @student, :grade => 2
      get "/courses/#{@course.id}/assignments/#{assignment.id}/submissions/#{@student.id}"
      f('.grading_value')[:value].should == '2'
    end
  end

  context "student view" do

    before (:each) do
      course_with_teacher_logged_in
    end

    it "should allow a student view student to view/submit assignments" do
      @assignment = @course.assignments.create(
          :title => 'Cool Assignment',
          :points_possible => 10,
          :submission_types => "online_text_entry",
          :due_at => Time.now.utc + 2.days)

      enter_student_view
      get "/courses/#{@course.id}/assignments/#{@assignment.id}"

      f('.assignment .title').should include_text @assignment.title
      f('.submit_assignment_link').click
      assignment_form = f('#submit_online_text_entry_form')
      wait_for_tiny(assignment_form)

      type_in_tiny('#submission_body', 'my assigment submission')
      expect_new_page_load { submit_form(assignment_form) }

      @course.student_view_student.submissions.count.should == 1
      f('#sidebar_content .details').should include_text "Turned In!"
    end

    it "should allow a student view student to submit file upload assignments" do
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

      keep_trying_until do
        f('.details .header').should include_text "Turned In!"
        f('.details .file-big').should include_text "testfile1"
      end
    end
  end
end
