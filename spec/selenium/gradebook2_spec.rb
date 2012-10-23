require File.expand_path(File.dirname(__FILE__) + '/helpers/gradebook2_common')

describe "gradebook2" do
  it_should_behave_like "gradebook2 selenium tests"

  before (:each) do
    data_setup
  end

  it "should not show 'not-graded' assignments" do
    get "/courses/#{@course.id}/gradebook2"
    wait_for_ajaximations

    f('.slick-header-columns').should_not include_text(@ungraded_assignment.title)
  end

  def filter_student(text)
    f('.gradebook_filter input').send_keys text
  end

  def get_visible_students
    ff('.student-name')
  end

  it 'should filter students' do
    get "/courses/#{@course.id}/gradebook2"
    wait_for_ajaximations
    get_visible_students.length.should == @all_students.size
    filter_student 'student 1'
    sleep 1 # InputFilter has a delay
    visible_students = get_visible_students
    visible_students.length.should == 1
    visible_students[0].text.should == 'student 1'
  end

  it "should link to a student's grades page" do
    get "/courses/#{@course.id}/gradebook2"
    wait_for_ajaximations
    els = ff('.student-name')
    links = els.map { |e| URI.parse(e.find_element(:css, 'a').attribute('href')).path }
    expected_links = @all_students.map { |s| "/courses/#{@course.id}/grades/#{s.id}" }
    links.should == expected_links
  end

  it "should not show 'not-graded' assignments" do
    f('#gradebook_grid .slick-header').should_not include_text(@ungraded_assignment.title)
  end

  it "should notify user that no updates are made if default grade assignment doesn't change anything" do
    get "/courses/#{@course.id}/gradebook2"

    ##
    # borrowed this code from set_default_grade method. not calling it directly because
    # we need to assert the content of the alert box.
    open_assignment_options(0)
    f('[data-action="setDefaultGrade"]').click
    dialog = fj('.ui-dialog:visible')
    f('.grading_value').send_keys(5)
    submit_dialog(dialog, '.ui-button')
    keep_trying_until do
      driver.switch_to.alert.should_not be_nil
      driver.switch_to.alert.text.should == 'None to Update'
      driver.switch_to.alert.dismiss
      true
    end
    driver.switch_to.default_content
  end

  it "should validate correct number of students showing up in gradebook" do
    get "/courses/#{@course.id}/gradebook2"
    wait_for_ajaximations

    ff('.student-name').count.should == @course.students.count
  end

  it "should not show concluded enrollments in active courses by default" do
    @student_1.enrollments.find_by_course_id(@course.id).conclude

    @course.students.count.should == @all_students.size - 1
    @course.all_students.count.should == @all_students.size

    get "/courses/#{@course.id}/gradebook2"
    wait_for_ajaximations

    ff('.student-name').count.should == @course.students.count

    # select the option and we'll now show concluded
    expect_new_page_load { open_gradebook_settings(driver.find_element(:css, 'label[for="show_concluded_enrollments"]')) }
    wait_for_ajaximations

    driver.find_elements(:css, '.student-name').count.should == @course.all_students.count
  end

  it "should show concluded enrollments in concluded courses by default" do
    @course.complete!

    @course.students.count.should == 0
    @course.all_students.count.should == @all_students.size

    get "/courses/#{@course.id}/gradebook2"
    wait_for_ajaximations
    driver.find_elements(:css, '.student-name').count.should == @course.all_students.count

    # the checkbox should fire an alert rather than changing to not showing concluded
    expect_fired_alert { open_gradebook_settings(driver.find_element(:css, 'label[for="show_concluded_enrollments"]')) }
    driver.find_elements(:css, '.student-name').count.should == @course.all_students.count
  end

  it "should show students sorted by their sortable_name" do
    get "/courses/#{@course.id}/gradebook2"
    wait_for_ajaximations

    dom_names = ff('.student-name').map(&:text)
    dom_names.should == @all_students.map(&:name)
  end

  it "should not show student avatars until they are enabled" do
    get "/courses/#{@course.id}/gradebook2"
    wait_for_ajaximations

    ff('.student-name').length.should == @all_students.size
    ff('.avatar img').length.should == 0

    @account = Account.default
    @account.enable_service(:avatars)
    @account.save!
    @account.service_enabled?(:avatars).should be_true
    get "/courses/#{@course.id}/gradebook2"
    wait_for_ajaximations

    ff('.student-name').length.should == @all_students.size
    ff('.avatar img').length.should == @all_students.size
  end


  it "should allow showing only a certain section" do
    get "/courses/#{@course.id}/gradebook2"
    wait_for_ajaximations
    # grade the first assignment
    edit_grade(f('#gradebook_grid [row="0"] .l0'), 0)
    edit_grade(f('#gradebook_grid [row="1"] .l0'), 1)

    button = f('#section_to_show')
    button.should include_text "All Sections"
    switch_to_section(@other_section)
    button.should include_text @other_section.name
    validate_cell_text(f('#gradebook_grid [row="0"] .l0'), '1')

    # verify that it remembers the section to show across page loads
    get "/courses/#{@course.id}/gradebook2"
    wait_for_ajaximations
    button = f('#section_to_show')
    button.should include_text @other_section.name
    validate_cell_text(f('#gradebook_grid [row="0"] .l0'), '1')

    # now verify that you can set it back
    switch_to_section()
    button.should include_text "All Sections"
    # validate all grades (i.e. submissions) were loaded
    validate_cell_text(f('#gradebook_grid [row="0"] .l0'), '0')
    validate_cell_text(f('#gradebook_grid [row="1"] .l0'), '1')
  end


  it "should handle muting/unmuting correctly" do
    get "/courses/#{@course.id}/gradebook2"
    wait_for_ajaximations

    toggle_muting(@second_assignment)
    fj(".slick-header-column[id*='assignment_#{@second_assignment.id}'] .muted").should be_displayed
    @second_assignment.reload.should be_muted

    # reload the page and make sure it remembered the setting
    get "/courses/#{@course.id}/gradebook2"
    wait_for_ajaximations
    fj(".slick-header-column[id*='assignment_#{@second_assignment.id}'] .muted").should be_displayed

    # make sure you can un-mute
    toggle_muting(@second_assignment)
    fj(".slick-header-column[id*='assignment_#{@second_assignment.id}'] .muted").should be_nil
    @second_assignment.reload.should_not be_muted
  end

  context "concluded course" do
    before do
      @course.complete!

      get "/courses/#{@course.id}/gradebook2"
      wait_for_ajaximations
    end

    it "should not allow editing grades" do
      cell = driver.find_element(:css, '#gradebook_grid [row="0"] .l0')
      cell.text.should == '10'
      cell.click
      ff('.grade', cell).should be_blank
    end

    it "should hide mutable actions from the menu" do
      open_gradebook_settings do |menu|
        ff("a.gradebook_upload_link", menu).should be_blank
        ff("a.set_group_weights", menu).should be_blank
      end
    end
  end

  it "should validate that gradebook settings is displayed when button is clicked" do
    get "/courses/#{@course.id}/gradebook2"
    wait_for_ajaximations

    open_gradebook_settings
  end

  it "should validate posting a comment to a graded assignment" do
    comment_text = "This is a new comment!"

    get "/courses/#{@course.id}/gradebook2"
    wait_for_ajaximations

    dialog = open_comment_dialog
    set_value(dialog.find_element(:id, "add_a_comment"), comment_text)
    f("form.submission_details_add_comment_form.clearfix > button.button").click
    wait_for_ajaximations

    #make sure it is still there if you reload the page
    refresh_page
    wait_for_ajaximations

    comment = open_comment_dialog.find_element(:css, '.comment')
    comment.should include_text(comment_text)
  end

  it "should let you post a group comment to a group assignment" do
    group_assignment = @course.assignments.create!({
                                                       :title => 'group assignment',
                                                       :due_at => (Time.now + 1.week),
                                                       :points_possible => ASSIGNMENT_3_POINTS,
                                                       :submission_types => 'online_text_entry',
                                                       :assignment_group => @group,
                                                       :group_category => GroupCategory.create!(:name => "groups", :context => @course),
                                                       :grade_group_students_individually => true
                                                   })
    project_group = group_assignment.group_category.groups.create!(:name => 'g1', :context => @course)
    project_group.users << @student_1
    project_group.users << @student_2

    comment_text = "This is a new group comment!"

    get "/courses/#{@course.id}/gradebook2"
    wait_for_ajaximations

    dialog = open_comment_dialog(3)
    set_value(dialog.find_element(:id, "add_a_comment"), comment_text)
    dialog.find_element(:id, "group_comment").click
    f("form.submission_details_add_comment_form.clearfix > button.button").click
    wait_for_ajaximations

    #make sure it's on the other student's submission
    comment = open_comment_dialog(3, 1).find_element(:css, '.comment')
    comment.should include_text(comment_text)
  end

  it "should validate assignment details" do
    submissions_count = @second_assignment.submissions.count.to_s + ' submissions'

    get "/courses/#{@course.id}/gradebook2"
    wait_for_ajaximations

    open_assignment_options(1)
    f('[data-action="showAssignmentDetails"]').click
    wait_for_ajaximations
    details_dialog = f('#assignment-details-dialog')
    details_dialog.should be_displayed
    table_rows = ff('#assignment-details-dialog-stats-table tr')
    table_rows[3].find_element(:css, 'td').text.should == submissions_count
  end

  it "should not throw an error when setting the default grade when concluded enrollments exist" do
    pending("bug 7413 - Error assigning default grade for all students when one student's enrollment has been concluded.") do
      conclude_and_unconclude_course
      3.times { student_in_course }

      get "/courses/#{@course.id}/gradebook2"
      wait_for_ajaximations

      #TODO - when show concluded enrollments fix goes in we probably have to add that code right here
      #for the test to work correctly

      set_default_grade(2, 5)
      grade_grid = f('#gradebook_grid')
      @course.student_enrollments.each_with_index do |e, n|
        next if e.completed?
        find_slick_cells(n, grade_grid)[2].text.should == 5
      end
    end
  end

  it "should give a quiz submission 30 extra seconds before making it late" do
    submission = Submission.last
    assignment = submission.assignment
    assignment.update_attribute(:due_at, Time.now)
    submission.update_attribute(:submitted_at, assignment.due_at + 30.seconds)
    submission.update_attribute(:submission_type, 'online_quiz')

    get "/courses/#{@course.id}/gradebook2"
    wait_for_ajaximations
    ff('.late').count.should == 0
  end

  describe "message students who" do
    it "should send messages" do
      message_text = "This is a message"

      get "/courses/#{@course.id}/gradebook2"
      wait_for_ajaximations

      open_assignment_options(2)
      f('[data-action="messageStudentsWho"]').click
      expect {
        message_form = f('#message_assignment_recipients')
        message_form.find_element(:css, '#body').send_keys(message_text)
        submit_form(message_form)
        wait_for_ajax_requests
      }.to change(ConversationMessage, :count).by_at_least(2)
    end

    it "should only send messages to students who have not submitted and have not been graded" do
      # student 1 submitted but not graded yet
      @third_submission = @third_assignment.submit_homework(@student_1, :body => ' student 1 submission assignment 4')
      @third_submission.save!

      # student 2 graded without submission (turned in paper by hand)
      @third_assignment.grade_student(@student_2, :grade => 42)

      # student 3 has neither submitted nor been graded

      message_text = "This is a message"
      get "/courses/#{@course.id}/gradebook2"
      wait_for_ajaximations
      open_assignment_options(2)
      f('[data-action="messageStudentsWho"]').click
      expect {
        message_form = f('#message_assignment_recipients')
        click_option('#message_assignment_recipients .message_types', "Haven't submitted yet")
        message_form.find_element(:css, '#body').send_keys(message_text)
        submit_form(message_form)
        wait_for_ajax_requests
      }.to change {ConversationMessage.count(:conversation_id)}.by(1)
    end

    it "should send messages when 'Scored more than' X points" do
      message_text = "This is a message"
      get "/courses/#{@course.id}/gradebook2"
      wait_for_ajaximations

      open_assignment_options(1)
      f('[data-action="messageStudentsWho"]').click
      expect {
        message_form = f('#message_assignment_recipients')
        click_option('#message_assignment_recipients .message_types', 'Scored more than')
        message_form.find_element(:css, '.cutoff_score').send_keys('3')  # both assignments have score of 5
        message_form.find_element(:css, '#body').send_keys(message_text)
        submit_form(message_form)
        wait_for_ajax_requests
      }.to change(ConversationMessage, :count).by_at_least(2)
    end

    it "should have a 'Haven't been graded' option" do
      # student 2 has submitted assignment 3, but it hasn't been graded
      submission = @third_assignment.submit_homework(@student_2, :body => 'student 2 submission assignment 3')
      submission.save!

      get "/courses/#{@course.id}/gradebook2"
      wait_for_ajaximations
      # set grade for first student, 3rd assignment
      edit_grade(f('#gradebook_grid [row="0"] .l2'), 0)
      open_assignment_options(2)

      # expect dialog to show 1 more student with the "Haven't been graded" option
      f('[data-action="messageStudentsWho"]').click
      visible_students = ffj('.student_list li:visible')
      visible_students.size.should == 1
      visible_students[0].text.strip.should == STUDENT_NAME_3
      click_option('#message_assignment_recipients .message_types', "Haven't been graded")
      visible_students = ffj('.student_list li:visible')
      visible_students.size.should == 2
      visible_students[0].text.strip.should == STUDENT_NAME_2
      visible_students[1].text.strip.should == STUDENT_NAME_3
    end
  end


  it "should handle multiple enrollments correctly" do
    @course.enroll_student(@student_1, :section => @other_section, :allow_multiple_enrollments => true)

    get "/courses/#{@course.id}/gradebook2"
    wait_for_ajaximations

    meta_cells = find_slick_cells(0, f('.grid-canvas'))
    meta_cells[0].should include_text @course.default_section.display_name
    meta_cells[0].should include_text @other_section.display_name

    switch_to_section(@course.default_section)
    meta_cells = find_slick_cells(0, f('.grid-canvas'))
    meta_cells[0].should include_text STUDENT_NAME_1

    switch_to_section(@other_section)
    meta_cells = find_slick_cells(0, f('.grid-canvas'))
    meta_cells[0].should include_text STUDENT_NAME_1
  end

  it "should display for users with only :view_all_grades permissions" do
    user_logged_in
    RoleOverride.create!(:enrollment_type => 'CustomAdmin',
                         :permission => 'view_all_grades',
                         :context => Account.default,
                         :enabled => true)
    AccountUser.create!(:user => @user,
                        :account => Account.default,
                        :membership_type => 'CustomAdmin')

    get "/courses/#{@course.id}/gradebook2"
    wait_for_ajaximations
    ff('.ui-state-error').count.should == 0
  end

  it "should display for users with only :manage_grades permissions" do
    user_logged_in
    RoleOverride.create!(:enrollment_type => 'CustomAdmin',
                         :permission => 'manage_grades',
                         :context => Account.default,
                         :enabled => true)
    AccountUser.create!(:user => @user,
                        :account => Account.default,
                        :membership_type => 'CustomAdmin')

    get "/courses/#{@course.id}/gradebook2"
    wait_for_ajaximations
    ff('.ui-state-error').count.should == 0
  end

  it "should include student view student for grading" do
    @fake_student = @course.student_view_student
    @fake_submission = @first_assignment.submit_homework(@fake_student, :body => 'fake student submission')

    get "/courses/#{@course.id}/gradebook2"
    wait_for_ajaximations

    ff('.student-name').map(&:text).join(" ").should match @fake_student.name
  end

  it "should not include non-graded group assignment in group total" do
    graded_assignment = @course.assignments.create!({
                                                        :title => 'group assignment 1',
                                                        :due_at => (Time.now + 1.week),
                                                        :points_possible => 10,
                                                        :submission_types => 'online_text_entry',
                                                        :assignment_group => @group,
                                                        :group_category => GroupCategory.create!(:name => 'groups', :context => @course),
                                                        :grade_group_students_individually => true
                                                    })
    group_assignment = @course.assignments.create!({
                                                       :title => 'group assignment 2',
                                                       :due_at => (Time.now + 1.week),
                                                       :points_possible => 0,
                                                       :submission_types => 'not_graded',
                                                       :assignment_group => @group,
                                                       :group_category => GroupCategory.create!(:name => 'groups', :context => @course),
                                                       :grade_group_students_individually => true
                                                   })
    project_group = group_assignment.group_category.groups.create!(:name => 'g1', :context => @course)
    project_group.users << @student_1
    #project_group.users << @student_2
    graded_assignment.submissions.create(:user => @student)
    graded_assignment.grade_student @student_1, :grade => 10 # 10 points possible
    group_assignment.submissions.create(:user => @student)
    group_assignment.grade_student @student_1, :grade => 2 # 0 points possible

    get "/courses/#{@course.id}/gradebook2"
    wait_for_ajaximations
    f('#gradebook_grid [row="0"] .assignment-group-cell .percentage').should include_text('100%') # otherwise 108%
    f('#gradebook_grid [row="0"] .total-cell .percentage').should include_text('100%') # otherwise 108%
  end

  it "should hide and show student names" do

    def toggle_hiding_students
      keep_trying_until do
        f('#gradebook_settings').click
        student_toggle = f('.student_names_toggle')
        student_toggle.should be_displayed
        student_toggle.click
        true
      end
    end

    get "/courses/#{@course.id}/gradebook2"
    wait_for_ajaximations

    toggle_hiding_students
    fj('.student-name:visible').should be_nil
    ffj('.student-placeholder:visible').length.should be > 0

    toggle_hiding_students
    ffj('.student-name:visible').length.should be > 0
    fj('.student-placeholder:visible').should be_nil
  end

  context "turnitin" do
    it "should show turnitin data" do
      s1 = @first_assignment.submit_homework(@student_1, :submission_type => 'online_text_entry', :body => 'asdf')
      s1.update_attribute :turnitin_data, {"submission_#{s1.id}" => {:similarity_score => 0.0, :web_overlap => 0.0, :publication_overlap => 0.0, :student_overlap => 0.0, :state => 'none'}}
      a = attachment_model(:context => @student_2, :content_type => 'text/plain')
      s2 = @first_assignment.submit_homework(@student_2, :submission_type => 'online_upload', :attachments => [a])
      s2.update_attribute :turnitin_data, {"attachment_#{a.id}" => {:similarity_score => 1.0, :web_overlap => 5.0, :publication_overlap => 0.0, :student_overlap => 0.0, :state => 'acceptable'}}

      get "/courses/#{@course.id}/gradebook2"
      wait_for_ajaximations
      icons = ffj('.gradebook-cell-turnitin')
      icons.size.should == 2

      # make sure it appears in each submission dialog
      icons.each do |icon|
        cell = icon.find_element(:xpath, '..')
        driver.action.move_to(cell).perform
        cell.find_element(:css, "a").click
        wait_for_ajaximations
        fj('.turnitin_similarity_score:visible').should be_present
        fj('.ui-icon-closethick:visible').click
      end
    end
  end

  context "downloading and uploading submissions" do
    it "updates the dropdown menu after downloading and processes submission uploads" do
      # Given I have a student with an uploaded submission
      a = attachment_model(:context => @student_2, :content_type => 'text/plain')
      s2 = @first_assignment.submit_homework(@student_2, :submission_type => 'online_upload', :attachments => [a])

      # When I go to the gradebook
      get "/courses/#{@course.id}/gradebook2"
      wait_for_ajaximations

      # And I click the dropdown menu on the assignment
      f('.gradebook-header-drop').click

      # And I click the download submissions button
      f('[data-action="downloadSubmissions"]').click

      # And I close the download submissions dialog
      fj("div:contains('Download Assignment Submissions'):first .ui-dialog-titlebar-close").click

      # And I click the dropdown menu on the assignment again
      f('.gradebook-header-drop').click

      # And I click the re-upload submissions link
      f('[data-action="reuploadSubmissions"]').click

      # When I attach a submissions zip file
      fixtureFile = Rails.root.join('spec/fixtures/files/submissions.zip')
      f('input[name=submissions_zip]').send_keys(fixtureFile)

      # And I upload it
      fj('button:contains("Upload Files")').click

      # Then I should see a message indicating the file was processed
      f('body').should include_text 'Attached files to the following user submissions'
    end
  end
end
