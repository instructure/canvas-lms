#
# Copyright (C) 2015 - present Instructure, Inc.
#
# This file is part of Canvas.
#
# Canvas is free software: you can redistribute it and/or modify it under
# the terms of the GNU Affero General Public License as published by the Free
# Software Foundation, version 3 of the License.
#
# Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
# A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
# details.
#
# You should have received a copy of the GNU Affero General Public License along
# with this program. If not, see <http://www.gnu.org/licenses/>.

require_relative '../../helpers/gradebook_common'
require_relative './gradebook_student_common'
require_relative '../setup/gradebook_setup'
require_relative '../pages/student_grades_page'


describe 'Student Gradebook' do
  include_context "in-process server selenium tests"
  include GradebookCommon
  include GradebookSetup

  let(:assignments) do
    assignments = []
    (1..3).each do |i|
      assignment = @course.assignments.create!(
        title: "Assignment #{i}",
        points_possible: 20
      )
      assignments.push assignment
    end
    assignments
  end

  grades = [
    5, 10, 15,
    19, 15, 10,
    4,  6, 17
  ]

  shared_examples 'Student Gradebook View' do |role|
    it "for #{role == 'observer' ? 'an Observer' : 'a Student'}", priority: '1',
       test_id: role == 'observer' ? 164027 : 164024 do
      course_with_student_logged_in({course_name: 'Course A'})
      course1 = @course
      student = @user
      @teacher = User.create!

      course_with_user 'StudentEnrollment', {user: student, course_name: 'Course B', active_all: true}
      course2 = @course
      course_with_user 'StudentEnrollment', {user: student, course_name: 'Course C', active_all: true}
      course3 = @course

      gi = 0
      [course1, course2, course3].each do |course|
        course.enroll_teacher(@teacher)
        assignments = []

        (1..3).each do |i|

          assignment = course.assignments.create!(
            title: "Assignment #{i}",
            points_possible: 20
          )
          assignment.grade_student(student, grade: grades[gi], grader: @teacher)
          assignments.push assignment
          gi += 1
        end
      end

      scores = []
      if role == 'observer'
        observer = user_factory(name: 'Observer', active_all: true, active_state: 'active')
        [course1, course2, course3].each do |course|

          enrollment = ObserverEnrollment.new(user: observer,
                                     course: course,
                                 workflow_state: 'active')

          enrollment.associated_user_id = student
          enrollment.save!
        end
      user_session(observer)
      end

      get "/courses/#{@course.id}/grades/#{student.id}"
      [course1, course2, course3].each do |course|
        options = Selenium::WebDriver::Support::Select.new f('#course_select_menu')
        options.select_by :text, course.name
        expect_new_page_load { f('#apply_select_menus').click }
        details = ff('[id^="submission_"].assignment_graded .grade')
        details.each {|detail| scores.push detail.text[/\d+/].to_i}
      end

      expect(scores).to eq grades
    end
  end

  it 'shows assignment details', priority: '1', test_id: 164023 do
    init_course_with_students 3
    user_session(@teacher)

    means = []
    [0, 3, 6].each do |i|
      # the format below ensures that 18.0 is displayed as 18.
      mean = format('%g' % (('%.1f' % (grades[i, 3].inject {|a, e| a + e}.to_f / 3))))
      means.push mean
    end

    expectations = [
      {high: '15', low: '5', mean: means[0]},
      {high: '19', low: '10', mean: means[1]},
      {high: '17', low: '4', mean: means[2]}
    ]

    grades.each_with_index do |grade, index|
      assignments[index / 3].grade_student @students[index % 3], grade: grade, grader: @teacher
    end

    get "/courses/#{@course.id}/grades/#{@students[0].id}"
    f('#show_all_details_button').click
    details = ff('[id^="score_details"] td')

    expectations.each_with_index do |expectation, index|
      i = index * 4 # each detail row has 4 items, we only want the first 3
      expect(details[i]).to include_text "Mean: #{expectation[:mean]}"
      expect(details[i + 1]).to include_text "High: #{expectation[:high]}"
      expect(details[i + 2]).to include_text "Low: #{expectation[:low]}"
    end

    f('#show_all_details_button').click
    details = ff('[id^="grade_info"]')
    details.each do |detail|
      expect(detail.css_value 'display').to eq 'none'
    end
  end

  context 'Student Grades' do
    it_behaves_like 'Student Gradebook View', 'observer'
    it_behaves_like 'Student Gradebook View'

  end

  it 'calculates grades based on graded assignments', priority: '1', test_id: 164025 do
    init_course_with_students
    user_session(@teacher)

    assignments[0].grade_student @students[0], grade: 20, grader: @teacher
    assignments[1].grade_student @students[0], grade: 20, grader: @teacher

    get "/courses/#{@course.id}/grades/#{@students[0].id}"
    expect(f('.final_grade .grade')).to include_text '100%'

    f('#only_consider_graded_assignments_wrapper').click
    expect(f('.final_grade .grade')).to include_text '66.67%'
  end

  it 'follows grade dropping rules', test_id: 164009, priority: '1' do
    add_teacher_and_student
    @group = @course.assignment_groups.create!(name: 'Group1', rules: 'drop_lowest:1')

    a1 = @course.assignments.create!(points_possible: 20, title: "Assignment 1", assignment_group: @group)
    a2 = @course.assignments.create!(points_possible: 20, title: "Assignment 2", assignment_group: @group)
    a3 = @course.assignments.create!(points_possible: 40, title: "Assignment 3", assignment_group: @group)

    a1.grade_student(@student, grade: 15, grader: @teacher)
    a2.grade_student(@student, grade: 10, grader: @teacher)
    a3.grade_student(@student, grade: 19, grader: @teacher)

    user_session(@teacher)
    StudentGradesPage.visit_as_teacher(@course, @student)
    expect(StudentGradesPage.assignment_row(a3)).to have_class 'dropped'

    user_session(@student)
    StudentGradesPage.visit_as_student(@course)
    expect(StudentGradesPage.assignment_row(a3)).to have_class 'dropped'
  end

  context 'Comments' do
    # create a course, publish and enroll teacher and student
    let_once(:test_course) { course_factory() }
    let_once(:teacher) { user_factory(active_all: true) }
    let_once(:student) { user_factory(active_all: true) }
    let_once(:published_course) do
      test_course.workflow_state = 'available'
      test_course.save!
      test_course
    end
    let_once(:enroll_teacher_and_students) do
      published_course.enroll_teacher(teacher).accept!
      published_course.enroll_student(student, enrollment_state: 'active')
    end
    # create an assignment and submit as a student
    let_once(:assignment) do
      published_course.assignments.create!(
        title: 'Assignment Yay',
        grading_type: 'points',
        points_possible: 10,
        submission_types: 'online_upload'
      )
    end
    let_once(:file_attachment) { attachment_model(content_type: 'application/pdf', context: student) }
    let_once(:student_submission) do
      assignment.submit_homework(
        student,
        submission_type: 'online_upload',
        attachments: [file_attachment]
      )
    end
    # leave a comment as a teacher
    let_once(:teacher_comment) { student_submission.submission_comments.create!(comment: 'good job')}

    it 'should display comments from a teacher on student grades page', priority: "1", test_id: 537621 do
      user_session(student)
      get "/courses/#{published_course.id}/grades"

      StudentGradesPage.toggle_comment_module
      unless f('.score_details_table').displayed?
        # 1st click seems to fail on chrome 1 out of 5 times so adding a second click
        StudentGradesPage.toggle_comment_module
      end
      expect(fj('.score_details_table span:first')).to include_text('good job')
    end

    it 'should not display comments from a teacher on student grades page if assignment is muted', priority: "1", test_id: 537620 do
      assignment.muted = true
      assignment.save!
      user_session(student)

      get "/courses/#{published_course.id}/grades"
      expect(fj('.score_details_table span:first')).not_to include_text('good job')
    end

    it 'should display comments from a teacher on assignment show page if assignment is muted', priority: "1", test_id: 537868 do
      user_session(student)

      get "/courses/#{published_course.id}/assignments/#{assignment.id}"
      expect(fj('.comments.module .comment:first')).to include_text('good job')
    end

    it 'should not display comments from a teacher on assignment show page if assignment is muted', priority: "1", test_id: 537867 do
      assignment.muted = true
      assignment.save!
      user_session(student)

      get "/courses/#{published_course.id}/assignments/#{assignment.id}"
      expect(fj('.comments.module p')).to include_text('You may not see all comments right now because the assignment is currently being graded.')
    end
  end

  describe "Arrange By dropdown" do
    before :once do
      course_with_student(name: "Student", active_all: true)

      # create multiple assignments in different modules and assignment groups
      group0 = @course.assignment_groups.create!(name: "Physics Group")
      group1 = @course.assignment_groups.create!(name: "Chem Group")

      @assignment0 = @course.assignments.create!(
        name: "Physics Alpha Assign",
        due_at: Time.now.utc + 3.days,
        assignment_group: group0,
      )

      @quiz = @course.quizzes.create!(
        title: "Chem Alpha Quiz",
        due_at: Time.now.utc + 5.days,
        assignment_group_id: group1.id
      )
      @quiz.publish!

      assignment = @course.assignments.create!(
        due_at: Time.now.utc + 5.days,
        assignment_group: group0
      )

      @discussion = @course.discussion_topics.create!(
        assignment: assignment,
        title: "Physics Beta Discussion"
      )

      @assignment1 = @course.assignments.create!(
        name: "Chem Beta Assign",
        due_at: Time.now.utc + 6.days,
        assignment_group: group1
      )

      module0 = ContextModule.create!(name: "Beta Mod", context: @course)
      module1 = ContextModule.create!(name: "Alpha Mod", context: @course)

      module0.content_tags.create!(context: @course, content: @quiz, tag_type: 'context_module')
      module0.content_tags.create!(context: @course, content: @assignment0, tag_type: 'context_module')
      module1.content_tags.create!(context: @course, content: @assignment1, tag_type: 'context_module')
      module1.content_tags.create!(context: @course, content: @discussion, tag_type: 'context_module')
    end

    context "as a student" do
      it_behaves_like 'Arrange By dropdown', :student
    end

    context "as a teacher" do
      it_behaves_like 'Arrange By dropdown', :teacher
    end

    context "as an admin" do
      it_behaves_like 'Arrange By dropdown', :admin
    end

    context "as a ta" do
      it_behaves_like 'Arrange By dropdown', :ta
    end
  end
end

