require File.expand_path(File.dirname(__FILE__) + '/helpers/gradebook2_common')
require File.expand_path(File.dirname(__FILE__) + '/helpers/groups_common')

describe 'Excuse an Assignment' do
  include_examples "in-process server selenium tests"

  context 'SpeedGrader' do
    before do
      course_with_teacher_logged_in
      course_with_student(course: @course, active_all: true, name: 'Student')
    end

    it 'can excuse complete/incomplete assignments', priority: "1", test_id: 209315 do
      @assignment = @course.assignments.build
      @assignment.grading_type = 'pass_fail'
      @assignment.publish

      get "/courses/#{@course.id}/gradebook/speed_grader?assignment_id=#{@assignment.id}"
      Selenium::WebDriver::Support::Select.new(f('#grading-box-extended'))
                                          .select_by(:text, 'Excused')

      get "/courses/#{@course.id}/grades"
      dropped = f('#gradebook_grid .container_1 .slick-row :first-child')
      expect(dropped.text).to eq 'EX'
      expect(dropped).to have_class 'dropped'
    end

    it 'excuses an assignment properly', priority: "1", test_id: 201949 do
      a1 = @course.assignments.create! title: 'Excuse Me', points_possible: 20
      a2 = @course.assignments.create! title: 'Don\'t Excuse Me', points_possible: 10
      a1.grade_student(@student, {grade: 20})
      a2.grade_student(@student, {grade: 5})

      get "/courses/#{@course.id}/gradebook/speed_grader?assignment_id=#{a2.id}"
      replace_content f('#grading-box-extended'), "EX\n"

      get "/courses/#{@course.id}/grades"
      row = ff('#gradebook_grid .container_1 .slick-row .slick-cell')

      expect(row[0].text).to eq '20'
      # this should show 'EX' and have dropped class
      expect(row[1].text).to eq('EX')
      expect(row[1]).to have_class 'dropped'

      # only one cell should have 'dropped' class
      dropped = ff('#gradebook_grid .container_1 .slick-row .dropped')
      expect(dropped.length).to eq 1

      # 'EX' should only affect that one cell
      expect(row[2].text).to eq '100%'
    end

    it 'indicates excused assignment as graded', priority: "1", test_id: 209316 do
      assignment = @course.assignments.build
      assignment.publish

      assignment.grade_student(@student, {excuse: true})

      get "/courses/#{@course.id}/gradebook/speed_grader?assignment_id=#{assignment.id}"
      expect(f('#combo_box_container .ui-selectmenu-item-icon i')).to have_class 'icon-check'
      expect(f('#combo_box_container .ui-selectmenu-item-header').text).to eq 'Student'
    end
  end

  shared_examples 'Basic Behavior' do |view|
    context 'Group Assignments', :group do
      it 'preserves assignment excused status', priority: "1", test_id: view == 'srgb' ? 216318 : 207117 do
        course_with_teacher_logged_in
        group_test_setup 4, 1, 1

        @students.each {|student| @testgroup[0].add_user student}
        @testgroup[0].save!

        assignment = @course.assignments.create!(
            title: 'Group Assignment',
            group_category_id: @testgroup[0].id,
            grade_group_students_individually: false,
            points_possible: 20
        )

        assignment.grade_student @students[1], {excuse: true }
        assignment.grade_student @students[0], {grade: 15}

        score_values = []

        if view == 'srgb'
          get "/courses/#{@course.id}/gradebook/change_gradebook_version?version=srgb"
          Selenium::WebDriver::Support::Select.new(f('#assignment_select'))
                                              .select_by(:text, assignment.title)
          next_student = f('.student_navigation button.next_object')
          4.times do
            next_student.click
            score_values << f('#student_and_assignment_grade').attribute('value')
          end
        else
          get "/courses/#{@course.id}/gradebook/"
          score_values = ff('.canvas_1 .slick-row .slick-cell:first-child').map(& :text)
        end

        expect(score_values).to eq ['15', 'EX', '15', '15']
      end

      it 'excuses assignments on individual basis', priority: "1", test_id: view == 'srgb' ? 209405 : 209384 do
        course_with_teacher_logged_in
        group_test_setup 2, 1, 1

        @students.each {|student| @testgroup[0].add_user student}
        @testgroup[0].save!

        a1 = @course.assignments.create!(
            title: 'Group Assignment',
            group_category_id: @testgroup[0].id,
            grade_group_students_individually: false,
            points_possible: 10
        )
        a2 = @course.assignments.create! title: 'Assignment', points_possible: 20

        @students.each do |student|
          a1.grade_student student, grade: 5
          a2.grade_student student, grade: 20
        end

        a1.grade_student @students[1], excuse: true

        totals = []
        if view == 'srgb'
          get "/courses/#{@course.id}/gradebook/change_gradebook_version?version=srgb"
          next_student = f('.student_navigation button.next_object')
          2.times do
            next_student.click
            totals << f('span.total-grade').text[/\d+(\.\d+)?%/]
          end
        else
          get "/courses/#{@course.id}/gradebook/"
          totals = ff('.canvas_1 .slick-row .slick-cell:last-child').map(& :text)
        end

        expect(totals).to eq(['83.33%', '100%']).or eq ['83.3%', '100%']
      end
    end

    it 'formats excused grade like dropped assignment', priority: "1", test_id: view == 'srgb' ? 216380 : 197051 do
      assignment = @course.assignments.create! title: 'Excuse Me', points_possible: 20

      if view == 'srgb'
        skip "Skipped because this spec fails if not run in foreground\n"\
          "This is believed to be the issue: https://code.google.com/p/selenium/issues/detail?id=7346"
        get "/courses/#{@course.id}/gradebook/change_gradebook_version?version=srgb"
        Selenium::WebDriver::Support::Select.new(f('#assignment_select'))
                                            .select_by(:text, assignment.title)
        Selenium::WebDriver::Support::Select.new(f('#student_select'))
                                            .select_by(:text, @students[0].name)
        replace_content f('#student_and_assignment_grade'), "EX\t"
        wait_for_ajaximations
      else
        assignment.grade_student(@students[0], {excuse: true})
      end

      user_session(@students[0])
      get "/courses/#{@course.id}/grades"

      grade_row = f("#submission_#{assignment.id}")
      grade_cell = f(".assignment_score .grade", grade_row)
      grade = grade_cell.text.scan(/\d+|EX/).first

      expect(grade_row).to have_class '.excused'
      expect(grade).to eq 'EX'
      expect(grade_row.attribute 'title').to eq 'This assignment is excused ' \
       'and will not be considered in the total calculation'
    end

    ['percent', 'letter_grade', 'gpa_scale', 'points'].each do |type|
      it "is not included in grade calculations (#{type})", priority: "1", test_id: view == 'srgb' ? 216379 : 196596 do
        a1 = @course.assignments.create! title: 'Excuse Me', grading_type: type, points_possible: 20
        a2 = @course.assignments.create! title: 'Don\'t Excuse Me', grading_type: type, points_possible: 20

        if type == 'points'
          a1.grade_student(@students[0], {grade: 20})
          a2.grade_student(@students[0], {grade: 13.2})
        else
          a1.grade_student(@students[0], {grade: '100%'})
          a2.grade_student(@students[0], {grade: '66%'})
        end

        total = ''
        if view == 'srgb'
          skip "Skipped because this spec fails if not run in foreground\n"\
          "This is believed to be the issue: https://code.google.com/p/selenium/issues/detail?id=7346"
          get "/courses/#{@course.id}/gradebook/change_gradebook_version?version=srgb"
          Selenium::WebDriver::Support::Select.new(f('#student_select'))
                                              .select_by(:text, @students[0].name)

          total = f('span.total-grade').text[/\d+(\.\d+)?%/]
          expect(total).to eq '83%'

          Selenium::WebDriver::Support::Select.new(f('#assignment_select'))
                                              .select_by(:text, a2.title)
          replace_content f('#student_and_assignment_grade'), "EX"
          wait_for_ajaximations
          total = f('span.total-grade').text[/\d+(\.\d+)?%/]
        else
          get "/courses/#{@course.id}/gradebook/"

          total = f('.canvas_1 .slick-row .slick-cell:last-child').text
          expect(total).to eq '83%'

          excused = f('.canvas_1 .slick-row .slick-cell:nth-child(2)')
          excused.click
          replace_content f('.grade', excused), "EX\n"

          total = f('.canvas_1 .slick-row .slick-cell:last-child').text
        end


        expect(total).to eq '100%'

      end
    end
  end

  context 'Gradebook Grid' do
    before do |example|
      unless example.metadata[:group]
        init_course_with_students
      end
    end

    it_behaves_like 'Basic Behavior'

    it 'default grade cannot be set to excused', priority: "1", test_id: 209380 do
      assignment = @course.assignments.create! title: 'Test Me!', points_possible: 20
      get "/courses/#{@course.id}/grades"
      f('.assignment_header_drop').click
      f('.gradebook-header-menu [data-action="setDefaultGrade"]').click

      ['EX', 'eX', 'Ex', 'ex'].each_with_index do |ex, i|
        replace_content f("#student_grading_#{assignment.id}"), "#{ex}\n"
        wait_for_ajaximations
        expect(ff('.ic-flash-error').length).to be i + 1
        expect(f('.ic-flash-error').text).to include 'Default grade cannot be set to EX'
      end

    end

    it 'excused grade shows up in grading modal', priority: "1", test_id: 209324 do
      assignment = @course.assignments.create! title: 'Excuse Me', points_possible: 20
      assignment.grade_student @students[0], excuse: true

      get "/courses/#{@course.id}/gradebook/"
      driver.action.move_to(f('.canvas_1 .slick-cell')).perform
      f('a.gradebook-cell-comment').click
      wait_for_ajaximations

      expect(f("#student_grading_#{assignment.id}").attribute 'value').to eq 'EX'
    end

    it 'assignments can be excused from grading modal', priority: "1", test_id: 217594 do
      assignment = @course.assignments.create! title: 'Excuse Me', points_possible: 20

      get "/courses/#{@course.id}/gradebook/"

      ['EX', 'ex', 'Ex', 'eX'].each_with_index do |ex, i|
        driver.action.move_to(f('.canvas_1 .slick-cell')).perform
        f('a.gradebook-cell-comment').click
        wait_for_ajaximations

        arr = ff("#student_grading_#{assignment.id}")
        replace_content arr[i], "#{ex}\n"
        wait_for_ajaximations

        f('.canvas_1 .slick-row .slick-cell:first-child .grade-and-outof-wrapper input').send_keys "\n"
        wait_for_ajaximations
        expect(f('.canvas_1 .slick-row .slick-cell:first-child').text).to eq 'EX'
      end
    end

    ['EX', 'ex', 'Ex', 'eX'].each do |ex|
      it "#{ex} can be used to excuse assignments", priority: "1", test_id: 225630 do
        @course.assignments.create! title: 'Excuse Me', points_possible: 20

        get "/courses/#{@course.id}/gradebook/"

        excused = f('.canvas_1 .slick-row .slick-cell:first-child')
        excused.click
        replace_content f('.grade', excused), "#{ex}\n"

        excused = f('.canvas_1 .slick-row .slick-cell:first-child')
        expect(excused.text).to eq 'EX'
        expect(excused).to have_class 'dropped'
      end
    end
  end


  context 'Individual View' do
    before do |example|
      unless example.metadata[:group]
        init_course_with_students
      end
    end

    it_behaves_like 'Basic Behavior', 'srgb'
  end
end