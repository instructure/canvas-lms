require_relative "common"
require_relative "helpers/speed_grader_common"
require_relative "helpers/gradebook2_common"
require_relative "helpers/quizzes_common"
require_relative "helpers/groups_common"

describe "speed grader" do
  include_context "in-process server selenium tests"
  include QuizzesCommon
  include Gradebook2Common
  include SpeedGraderCommon
  include GroupsCommon

  before(:each) do
    stub_kaltura
    course_with_teacher_logged_in
    @assignment = @course.assignments.create(:name => 'assignment with rubric', :points_possible => 10)
  end

  context "as a course limited ta" do
    before(:each) do
      @taenrollment = course_with_ta(:course => @course, :active_all => true)
      @taenrollment.limit_privileges_to_course_section = true
      @taenrollment.save!
      user_logged_in(:user => @ta, :username => "imata@example.com")

      @section = @course.course_sections.create!
      student_in_course(:active_all => true); @student1 = @student
      student_in_course(:active_all => true); @student2 = @student
      @enrollment.course_section = @section; @enrollment.save

      @assignment.submission_types = "online_upload"
      @assignment.save!

      @submission1 = @assignment.submit_homework(@student1, :submission_type => "online_text_entry", :body => "hi")
      @submission2 = @assignment.submit_homework(@student2, :submission_type => "online_text_entry", :body => "there")
    end

    it "lists the correct number of students", priority: "2", test_id: 283737 do
      get "/courses/#{@course.id}/gradebook/speed_grader?assignment_id=#{@assignment.id}"

      expect(f("#x_of_x_students")).to include_text("1 of 1")
      expect(ff("#students_selectmenu-menu li").count).to eq 1
    end
  end

  context "alerts" do
    it "should alert the teacher before leaving the page if comments are not saved", priority: "1", test_id: 283736 do
      student_in_course(active_user: true).user
      get "/courses/#{@course.id}/gradebook/speed_grader?assignment_id=#{@assignment.id}"
      comment_textarea = f("#speedgrader_comment_textarea")
      replace_content(comment_textarea, "oh no i forgot to save this comment!")
      # navigate away
      driver.navigate.refresh
      alert_shown = alert_present?
      dismiss_alert
      expect(alert_shown).to eq(true)
    end
  end

  context "url submissions" do
    before do
      @assignment.update_attributes! submission_types: 'online_url',
                                     title: "url submission"
      student_in_course
      @assignment.submit_homework(@student, :submission_type => "online_url", :workflow_state => "submitted", :url => "http://www.instructure.com")
    end

    it "properly shows and hides student name when name hidden toggled", priority: "2", test_id: 283741 do
      get "/courses/#{@course.id}/gradebook/speed_grader?assignment_id=#{@assignment.id}"

      in_frame 'speedgrader_iframe' do
        expect(f('.not_external')).to include_text("instructure")
        expect(f('.open_in_a_new_tab')).to include_text("View")
      end
    end
  end



  it "creates a comment on assignment", priority: "1", test_id: 283754 do
    #pending("failing because it is dependant on an external kaltura system")

    student_submission
    get "/courses/#{@course.id}/gradebook/speed_grader?assignment_id=#{@assignment.id}"
    wait_for_ajaximations

    #check media comment
    f('#add_a_comment .media_comment_link').click
    expect(f("#audio_record_option")).to be_displayed
    expect(f("#video_record_option")).to be_displayed
    close_visible_dialog
    expect(f("#audio_record_option")).not_to be_displayed

    #check for file upload comment
    f('#add_attachment').click
    expect(f('#comment_attachments input')).to be_displayed
    f('#comment_attachments a').click
    expect(f("#comment_attachments")).not_to contain_css("input")

    #add comment
    f('#add_a_comment > textarea').send_keys('grader comment')
    submit_form('#add_a_comment')
    expect(f('#comments > .comment')).to be_displayed
    expect(f('#comments > .comment')).to include_text('grader comment')

    #make sure gradebook link works
    expect_new_page_load do
      f('#speed_grader_gradebook_link').click
    end
    expect(fj('body.grades')).to be_displayed
  end

  it "shows comment post time", priority: "1", test_id: 283755 do
    @submission = student_submission
    get "/courses/#{@course.id}/gradebook/speed_grader?assignment_id=#{@assignment.id}"
    wait_for_ajaximations

    #add comment
    f('#add_a_comment > textarea').send_keys('grader comment')
    submit_form('#add_a_comment')
    expect(f('#comments > .comment')).to be_displayed
    @submission.reload
    @comment = @submission.submission_comments.first

    # immediately from javascript
    extend TextHelper
    expected_posted_at = datetime_string(@comment.created_at).gsub(/\s+/, ' ')
    expect(f('#comments > .comment .posted_at')).to include_text(expected_posted_at)

    # after refresh
    get "/courses/#{@course.id}/gradebook/speed_grader?assignment_id=#{@assignment.id}"
    wait_for_ajaximations
    expect(f('#comments > .comment .posted_at')).to include_text(expected_posted_at)
  end

  it "properly shows avatar images only if avatars are enabled on the account", priority: "1", test_id: 283756 do
    # enable avatars
    @account = Account.default
    @account.enable_service(:avatars)
    @account.save!
    expect(@account.service_enabled?(:avatars)).to be_truthy

    student_submission

    get "/courses/#{@course.id}/gradebook/speed_grader?assignment_id=#{@assignment.id}"
    wait_for_ajaximations

    # make sure avatar shows up for current student
    expect(ff("#avatar_image").length).to eq 1
    expect(f("#avatar_image")).not_to have_attribute('src', 'blank.png')

    #add comment
    f('#add_a_comment > textarea').send_keys('grader comment')
    submit_form('#add_a_comment')
    expect(f('#comments > .comment')).to be_displayed
    expect(f('#comments > .comment')).to include_text('grader comment')

    # make sure avatar shows up for user comment
    expect(ff("#comments > .comment .avatar")[0]).to have_attribute('style', "display: inline\;")
    # disable avatars
    @account = Account.default
    @account.disable_service(:avatars)
    @account.save!
    expect(@account.service_enabled?(:avatars)).to be_falsey
    get "/courses/#{@course.id}/gradebook/speed_grader?assignment_id=#{@assignment.id}"
    wait_for_ajaximations

    expect(f("#content")).not_to contain_css("#avatar_image")
    expect(ff("#comments > .comment .avatar").length).to eq 1
    expect(ff("#comments > .comment .avatar")[0]).to have_attribute('style', "display: none\;")
  end

  it "hides student names and avatar images if Hide student names is checked", priority: "1", test_id: 283757 do
    # enable avatars
    @account = Account.default
    @account.enable_service(:avatars)
    @account.save!
    expect(@account.service_enabled?(:avatars)).to be_truthy

    sub = student_submission
    sub.add_comment(:comment => "ohai teacher")

    get "/courses/#{@course.id}/gradebook/speed_grader?assignment_id=#{@assignment.id}"
    expect(f("#avatar_image")).to be_displayed

    f("#settings_link").click
    f('#hide_student_names').click
    expect_new_page_load { fj('.ui-dialog-buttonset .ui-button:visible:last').click }
    wait_for_ajaximations

    expect(f("#avatar_image")).not_to be_displayed
    expect(f('#students_selectmenu-button .ui-selectmenu-item-header')).to include_text "Student 1"

    expect(f('#comments > .comment')).to include_text('ohai')
    expect(f("#comments > .comment .avatar")).not_to be_displayed
    expect(f('#comments > .comment .author_name')).to include_text('Student')

    # add teacher comment
    f('#add_a_comment > textarea').send_keys('grader comment')
    submit_form('#add_a_comment')
    expect(ff('#comments > .comment')).to have_size(2)

    # make sure name and avatar show up for teacher comment
    expect(ffj("#comments > .comment .avatar:visible").size).to eq 1
    expect(ff('#comments > .comment .author_name')[1]).to include_text('nobody@example.com')
  end

  it "does not show students in other sections if visibility is limited", priority: "1", test_id: 283758 do
    @enrollment.update_attribute(:limit_privileges_to_course_section, true)
    student_submission
    student_submission(:username => 'otherstudent@example.com', :section => @course.course_sections.create(:name => "another section"))
    get "/courses/#{@course.id}/gradebook/speed_grader?assignment_id=#{@assignment.id}"
    wait_for_ajaximations

    expect(ff('#students_selectmenu option').size).to eq 1 # just the one student
    expect(ff('#section-menu ul li').size).to eq 1 # "Show all sections"
    expect(f("#students_selectmenu")).not_to contain_css('#section-menu') # doesn't get inserted into the menu
  end

  it "displays inactive students" do
    student_submission(:username => 'inactivestudent@example.com')
    en = @student.student_enrollments.first
    en.deactivate

    get "/courses/#{@course.id}/gradebook/speed_grader?assignment_id=#{@assignment.id}"
    wait_for_ajaximations

    expect(ff('#students_selectmenu option').size).to eq 1 # just the one student
    expect(f('#enrollment_inactive_notice').text).to eq 'Notice: Inactive Student'

    replace_content f('#grading-box-extended'), "5", tab_out: true
    wait_for_ajaximations
    @submission.reload
    expect(@submission.score).to eq 5

    f('#speedgrader_comment_textarea').send_keys('srsly')
    f('#add_a_comment button[type="submit"]').click
    wait_for_ajaximations
    expect(@submission.submission_comments.first.comment).to eq 'srsly'
  end

  context "multiple enrollments" do
    before(:each) do
      student_in_course
      @course_section = @course.course_sections.create!(:name => "<h1>Other Section</h1>")
      @enrollment = @course.enroll_student(@student,
                                           :enrollment_state => "active",
                                           :section => @course_section,
                                           :allow_multiple_enrollments => true)
    end

    it "does not duplicate students", priority: "1", test_id: 283985 do
      get "/courses/#{@course.id}/gradebook/speed_grader?assignment_id=#{@assignment.id}"
      wait_for_ajaximations

      expect(ff("#students_selectmenu option").length).to eq 1
    end

    it "filters by section properly", priority: "1", test_id: 283986 do
      get "/courses/#{@course.id}/gradebook/speed_grader?assignment_id=#{@assignment.id}"
      wait_for_ajaximations

      sections = @course.course_sections
      expect(ff("#section-menu ul li a")[1]).to have_attribute("text", @course_section.name)
      goto_section(sections[0].id)
      expect(ff("#students_selectmenu option").length).to eq 1
      goto_section(sections[1].id)
      expect(ff("#students_selectmenu option").length).to eq 1
    end
  end

  it "shows the first ungraded student with a submission", priority: "1", test_id: 283987 do
    s1, s2, s3 = n_students_in_course(3)
    s1.update_attribute :name, "A"
    s2.update_attribute :name, "B"
    s3.update_attribute :name, "C"

    @assignment.grade_student s1, score: 10
    @assignment.find_or_create_submission(s2).tap { |submission|
      submission.student_entered_score = 5
    }.save!
    @assignment.submit_homework(s3, body: "Homework!?")

    get "/courses/#{@course.id}/gradebook/speed_grader?assignment_id=#{@assignment.id}"
    wait_for_ajaximations

    expect(fj("#students_selectmenu option[value=#{s3.id}]")[:selected]).to be_truthy
  end

  it "allows the user to change sorting and hide student names", priority: "1", test_id: 283988 do
    student_submission(name: 'student@example.com')

    get "/courses/#{@course.id}/gradebook/speed_grader?assignment_id=#{@assignment.id}"
    wait_for_ajaximations

    # sort by submission date
    f("#settings_link").click
    f('select#eg_sort_by option[value="submitted_at"]').click
    expect_new_page_load { fj('.ui-dialog-buttonset .ui-button:visible:last').click }
    expect(f('#combo_box_container .ui-selectmenu .ui-selectmenu-item-header')).to include_text "student@example.com"

    # hide student names
    f("#settings_link").click
    f('#hide_student_names').click
    expect_new_page_load { fj('.ui-dialog-buttonset .ui-button:visible:last').click }
    expect(f('#combo_box_container .ui-selectmenu .ui-selectmenu-item-header')).to include_text "Student 1"

    # make sure it works a second time too
    f("#settings_link").click
    f('select#eg_sort_by option[value="alphabetically"]').click
    expect_new_page_load { fj('.ui-dialog-buttonset .ui-button:visible:last').click }
    expect(f('#combo_box_container .ui-selectmenu .ui-selectmenu-item-header')).to include_text "Student 1"

    # unselect the hide option
    f("#settings_link").click
    f('#hide_student_names').click
    expect_new_page_load { fj('.ui-dialog-buttonset .ui-button:visible:last').click }
    expect(f('#combo_box_container .ui-selectmenu .ui-selectmenu-item-header')).to include_text "student@example.com"
  end

  context "student dropdown" do
    before(:each) do
      @section0 = @course.course_sections.create!(name: "Section0")
      @section1 = @course.course_sections.create!(name: "Section1")

      @student0 = User.create!(name: "Test Student 0")
      @student1 = User.create!(name: "Test Student 1")
      @course.enroll_student(@student0, section: @section0)
      @course.enroll_student(@student1, section: @section1)

      get "/courses/#{@course.id}/gradebook/speed_grader?assignment_id=#{@assignment.id}"
    end

    it "show all sections menu item is present", priority: "2", test_id: "164207" do
      f("#students_selectmenu-button").click
      hover(f("#section-menu-link"))
      wait_for_ajaximations
      expect(f("#section-menu .ui-menu")).to include_text("Show all sections")
    end

    it "should list all course sections", priority: "2", test_id: "588914" do
      f("#students_selectmenu-button").click
      hover(f("#section-menu-link"))
      wait_for_ajaximations
      expect(f("#section-menu .ui-menu")).to include_text(@section0.name)
      expect(f("#section-menu .ui-menu")).to include_text(@section1.name)
    end
  end

  it "includes the student view student for grading", priority: "1", test_id: 283990 do
    @course.student_view_student
    get "/courses/#{@course.id}/gradebook/speed_grader?assignment_id=#{@assignment.id}"
    wait_for_ajaximations

    expect(ff("#students_selectmenu option").length).to eq 1
  end

  it "marks the checkbox of students for graded assignments", priority: "1", test_id: 283992 do
    student_submission

    get "/courses/#{@course.id}/gradebook/speed_grader?assignment_id=#{@assignment.id}"
    wait_for_ajaximations

    expect(f("#students_selectmenu-button")).to have_class("not_graded")

    f('#grade_container input[type=text]').click
    set_value(f('#grade_container input[type=text]'), 1)
    f(".ui-selectmenu-icon").click
    wait_for_ajaximations
    expect(f("#students_selectmenu-button")).to have_class("graded")
  end

  context "Pass / Fail assignments" do
    it "displays correct options in the speedgrader dropdown", priority: "1", test_id: 283996 do
      course_with_teacher_logged_in
      course_with_student(course: @course, active_all: true)

      @assignment = @course.assignments.build
      @assignment.grading_type = 'pass_fail'
      @assignment.publish

      get "/courses/#{@course.id}/gradebook/speed_grader?assignment_id=#{@assignment.id}"
      select_box_values = ff('#grading-box-extended option').map(&:text)
      expect(select_box_values).to eql(["---", "Complete", "Incomplete", "Excused"])
    end
  end

  it 'should let you enter in a float for a quiz question point value', priority: "1", test_id: 369250 do
    init_course_with_students
    quiz = seed_quiz_with_submission
    get "/courses/#{@course.id}/gradebook/speed_grader?assignment_id=#{quiz.assignment_id}"
    # In the left panel modify the grade to 0.5
    driver.switch_to.frame f('#speedgrader_iframe')
    points_input = ff('#questions .user_points input')
    driver.execute_script("$('#questions .user_points input').focus()")
    replace_content(points_input[0], '0')
    replace_content(points_input[1], '.5')
    replace_content(points_input[2], '0')
    f('.update_scores button[type="submit"]').click
    wait_for_ajaximations
    # Switch to the right panel
    # Verify that the grade is .5
    driver.switch_to.default_content
    expect(f('#grading-box-extended')['value']).to eq('0.5')
    expect(f("#students_selectmenu-button")).to_not have_class("not_graded")
    expect(f("#students_selectmenu-button")).to have_class("graded")
  end

  context 'Crocodocable Submissions' do
    # set up course and users
    let(:test_course) { @course }
    let(:student)     { user(active_all: true) }
    let!(:crocodoc_plugin) { PluginSetting.create! name: "crocodoc", settings: {api_key: "abc123"} }
    let!(:enroll_student) do
      test_course.enroll_user(student, 'StudentEnrollment', enrollment_state: 'active')
    end
    # create an assignment with online_upload type submission
    let!(:assignment) { test_course.assignments.create!(title: 'Assignment A', submission_types: 'online_text_entry,online_upload') }
    # submit to the assignment as a student twice, one with file and other with text
    let!(:file_attachment) { attachment_model(:content_type => 'application/pdf', :context => student) }
    let!(:submit_with_attachment) do
      assignment.submit_homework(
        student,
        submission_type: 'online_upload',
        attachments: [file_attachment]
      )
    end

    it 'should display a flash warning banner when viewed in Firefox', priority: "2", test_id: 571755 do
      skip_if_chrome('This test applies to Firefox')
      skip_if_ie('This test applies to Firefox')
      get "/courses/#{test_course.id}/gradebook/speed_grader?assignment_id=#{assignment.id}"
      expect(fj('#flash_message_holder')).to include_text('Warning: Crocodoc has limitations when used in Firefox. Comments will not always be saved.')
    end
  end
end

