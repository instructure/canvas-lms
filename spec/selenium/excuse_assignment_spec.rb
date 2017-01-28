require File.expand_path(File.dirname(__FILE__) + '/helpers/gradebook_common')
require File.expand_path(File.dirname(__FILE__) + '/helpers/groups_common')

describe 'Excuse an Assignment' do
  include_context "in-process server selenium tests"
  include GradebookCommon
  include GroupsCommon

  before do |example|
    unless example.metadata[:group]
      course_with_teacher_logged_in
      course_with_student(course: @course, active_all: true, name: 'Student')
    end
  end

  context 'Student view details' do
    before do
      @assignment = @course.assignments.create! title: 'Excuse Me', submission_types: 'online_text_entry', points_possible: 20
      @assignment.grade_student @student, excuse: true, grader: @teacher

      user_session @student
    end

    it 'Assignment index displays scores as excused', priority: "1", test_id: 246616 do
      get "/courses/#{@course.id}/assignments"
      wait_for_ajaximations
      expect(f('[id^="assignment_"] span.non-screenreader').text).to eq 'Excused'
    end

    it 'Assignment details displays scores as excused', priority: "1", test_id: 201937 do
      get "/courses/#{@course.id}/assignments/#{@assignment.id}"
      wait_for_ajaximations
      expect(f('#sidebar_content .details .header').text).to eq 'Excused!'
    end

    it 'Submission details displays scores as excused', priority: "1", test_id: 246617 do
      get "/courses/#{@course.id}/assignments/#{@assignment.id}/submissions/#{@student.id}"
      wait_for_ajaximations
      expect(f('#content span.published_grade').text).to eq 'Excused'
    end
  end

  it 'Gradebook export accounts for excused assignment', priority: "1", test_id: 209242 do
    assignment = @course.assignments.create! title: 'Excuse Me', points_possible: 20
    assignment.grade_student @student, excuse: true, grader: @teacher

    csv = CSV.parse(GradebookExporter.new(@course, @teacher).to_csv)
    _name, _id, _section, _sis_login_id, score = csv[-1]
    expect(score).to eq 'EX'
  end

  it 'Gradebook import accounts for excused assignment', priority: "1", test_id: 223509 do
    skip_if_chrome('fragile upload process')
    @course.assignments.create! title: 'Excuse Me', points_possible: 20
    rows = ['Student Name,ID,Section,Excuse Me',
            "Student,#{@student.id},,EX"]
    _filename, fullpath, _data = get_file('gradebook.csv', rows.join("\n"))

    get "/courses/#{@course.id}/gradebook_uploads/new"

    f('#gradebook_upload_uploaded_data').send_keys(fullpath)
    f('#new_gradebook_upload').submit
    run_jobs
    wait_for_ajaximations
    expect(f('.canvas_1 .new-grade').text).to eq 'EX'

    submit_form('#gradebook_grid_form')
    driver.switch_to.alert.accept
    wait_for_ajaximations
    run_jobs

    get "/courses/#{@course.id}/gradebook"
    expect(f('.canvas_1 .slick-row .slick-cell:first-child').text).to eq 'EX'

    # Test case insensitivity on 'EX'
    assign = @course.assignments.create! title: 'Excuse Me 2', points_possible: 20
    assign.grade_student @student, excuse: true, grader: @teacher
    rows = ['Student Name,ID,Section,Excuse Me 2',
            "Student,#{@student.id},,Ex"]
    _filename, fullpath, _data = get_file('gradebook.csv', rows.join("\n"))

    get "/courses/#{@course.id}/gradebook_uploads/new"

    f('#gradebook_upload_uploaded_data').send_keys(fullpath)
    f('#new_gradebook_upload').submit
    run_jobs
    wait_for_ajaximations

    expect(f('#no_changes_detected')).not_to be_nil
  end

  context 'SpeedGrader' do
    it 'can excuse complete/incomplete assignments', priority: "1", test_id: 209315 do
      assignment = @course.assignments.create! title: 'Excuse Me', points_possible: 20, grading_type: 'pass_fail'

      get "/courses/#{@course.id}/gradebook/speed_grader?assignment_id=#{assignment.id}"
      click_option f('#grading-box-extended'), 'Excused'

      get "/courses/#{@course.id}/grades"
      dropped = f('#gradebook_grid .container_1 .slick-row :first-child')
      expect(dropped.text).to eq 'EX'
      expect(dropped).to have_class 'dropped'
    end

    it 'excuses an assignment properly', priority: "1", test_id: 201949 do
      a1 = @course.assignments.create! title: 'Excuse Me', points_possible: 20
      a2 = @course.assignments.create! title: 'Don\'t Excuse Me', points_possible: 10
      a1.grade_student(@student, grade: 20, grader: @teacher)
      a2.grade_student(@student, grade: 5, grader: @teacher)

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

      assignment.grade_student(@student, excuse: true, grader: @teacher)

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
            group_category_id: @group_category[0].id,
            grade_group_students_individually: false,
            points_possible: 20
        )

        assignment.grade_student @students[1], excuse: true, grader: @teacher
        assignment.grade_student @students[0], grade: 15, grader: @teacher

        score_values = []

        if view == 'srgb'
          get "/courses/#{@course.id}/gradebook/change_gradebook_version?version=srgb"
          click_option f('#assignment_select'), assignment.title
          next_student = f('.student_navigation button.next_object')
          4.times do
            next_student.click
            wait_for_ajaximations
            score_values << f('#student_and_assignment_grade').attribute('value')
          end
        else
          get "/courses/#{@course.id}/gradebook/"
          wait_for_ajaximations
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
            group_category_id: @group_category[0].id,
            grade_group_students_individually: false,
            points_possible: 10
        )
        a2 = @course.assignments.create! title: 'Assignment', points_possible: 20

        @students.each do |student|
          a1.grade_student student, grade: 5, grader: @teacher
          a2.grade_student student, grade: 20, grader: @teacher
        end

        a1.grade_student @students[1], excuse: true, grader: @teacher

        totals = []
        if view == 'srgb'
          get "/courses/#{@course.id}/gradebook/change_gradebook_version?version=srgb"
          next_student = f('.student_navigation button.next_object')
          2.times do
            next_student.click
            wait_for_ajaximations
            totals << f('span.total-grade').text[/\d+(\.\d+)?%/]
          end
        else
          get "/courses/#{@course.id}/gradebook/"
          wait_for_ajaximations
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
        click_option f('#assignment_select'), assignment.title
        click_option f('#student_select'), @student.name
        replace_content f('#student_and_assignment_grade'), "EX\t"
        wait_for_ajaximations
      else
        assignment.grade_student(@student, excuse: true, grader: @teacher)
      end

      user_session(@student)
      get "/courses/#{@course.id}/grades"

      grade_row = f("#submission_#{assignment.id}")
      grade_cell = f(".assignment_score .grade", grade_row)
      grade = grade_cell.text.scan(/\d+|EX/).first

      expect(grade_row).to have_class '.excused'
      expect(grade).to eq 'EX'
      expect(grade_row).to have_attribute('title', 'This assignment is excused ' \
       'and will not be considered in the total calculation')
    end

    ['percent', 'letter_grade', 'gpa_scale', 'points'].each do |type|
      it "is not included in grade calculations with type '#{type}'", priority: "1", test_id: view == 'srgb' ? 216379 : 1196596 do
        a1 = @course.assignments.create! title: 'Excuse Me', grading_type: type, points_possible: 20
        a2 = @course.assignments.create! title: 'Don\'t Excuse Me', grading_type: type, points_possible: 20

        if type == 'points'
          a1.grade_student(@student, grade: 13.2, grader: @teacher)
          a2.grade_student(@student, grade: 20, grader: @teacher)
        else
          a1.grade_student(@student, grade: '66%', grader: @teacher)
          a2.grade_student(@student, grade: '100%', grader: @teacher)
        end

        total = ''
        if view == 'srgb'
          skip "Skipped because this spec fails if not run in foreground\n"\
          "This is believed to be the issue: https://code.google.com/p/selenium/issues/detail?id=7346"
          get "/courses/#{@course.id}/gradebook/change_gradebook_version?version=srgb"
          click_option f('#student_select'), @student.name
          total = f('span.total-grade').text[/\d+(\.\d+)?%/]
          expect(total).to eq '83%'

          click_option f('#assignment_select'), a1.title
          replace_content f('#student_and_assignment_grade'), "EX\t"
          wait_for_ajaximations
          total = f('span.total-grade').text[/\d+(\.\d+)?%/]
        else
          get "/courses/#{@course.id}/gradebook/"

          total = f('.canvas_1 .slick-row .slick-cell:last-child').text
          expect(total).to eq '83%'

          excused = f('.canvas_1 .slick-row .slick-cell:first-child')
          excused.click
          replace_content f('.grade', excused), "EX\n"

          total = f('.canvas_1 .slick-row .slick-cell:last-child').text
        end
        expect(total).to eq '100%'
      end
    end
  end

  context 'Gradebook Grid' do
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
      assignment.grade_student @student, excuse: true, grader: @teacher

      get "/courses/#{@course.id}/gradebook/"
      driver.action.move_to(f('.canvas_1 .slick-cell')).perform
      wait_for_ajaximations
      f('a.gradebook-cell-comment').click
      wait_for_ajaximations

      expect(f("#student_grading_#{assignment.id}")).to have_value 'EX'
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
      it "'#{ex}' can be used to excuse assignments", priority: "1", test_id: 225630 do
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
    it_behaves_like 'Basic Behavior', 'srgb'
  end
end
