require File.expand_path(File.dirname(__FILE__) + '/helpers/gradebook2_common')

describe 'Student Gradebook' do
  include_context "in-process server selenium tests"

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

      course_with_user 'StudentEnrollment', {user: student, course_name: 'Course B', active_all: true}
      course2 = @course
      course_with_user 'StudentEnrollment', {user: student, course_name: 'Course C', active_all: true}
      course3 = @course

      gi = 0

      [course1, course2, course3].each do |course|
        assignments = []

        (1..3).each do |i|

          assignment = course.assignments.create!(
            title: "Assignment #{i}",
            points_possible: 20
          )
          assignment.grade_student student, {grade: grades[gi]}
          assignments.push assignment
          gi += 1
        end
      end

      scores = []
      if role == 'observer'
        observer = user(name: 'Observer', active_all: true, active_state: 'active')
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
        options = Selenium::WebDriver::Support::Select.new f('#course_url')
        options.select_by :text, course.name

        details = ff('[id^="submission_"].assignment_graded .grade')
        details.each {|detail| scores.push detail.text[/\d+/].to_i}
      end

      expect(scores).to eq grades
    end
  end

  it 'shows assignment details', priority: '1', test_id: 164023 do
    init_course_with_students 3

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
      assignments[index / 3].grade_student @students[index % 3], {grade: grade}
    end

    get "/courses/#{@course.id}/grades/#{@students[0].id}"
    f('#show_all_details_link').click
    details = ff('[id^="score_details"] td')

    expectations.each_with_index do |expectation, index|
      i = index * 4 # each detail row has 4 items, we only want the first 3
      expect(details[i].text).to eq "Mean: #{expectation[:mean]}"
      expect(details[i + 1].text).to eq "High: #{expectation[:high]}"
      expect(details[i + 2].text).to eq "Low: #{expectation[:low]}"
    end

    f('#show_all_details_link').click
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

    assignments[0].grade_student @students[0], {grade: 20}
    assignments[1].grade_student @students[0], {grade: 20}

    get "/courses/#{@course.id}/grades/#{@students[0].id}"
    expect(f('.final_grade .grade').text).to eq '100%'

    f('#only_consider_graded_assignments').click
    expect(f('.final_grade .grade').text).to eq '66.67%'
  end
end

