require File.expand_path(File.dirname(__FILE__) + '/common')

describe "assignment selenium tests" do
  it_should_behave_like "in-process server selenium tests"

  it "should properly show rubric criterion details for learning outcomes" do
    course_with_student_logged_in
    
    @assignment = @course.assignments.create(:name => 'assignment with rubric')
    outcome_with_rubric
 
    @rubric.associate_with(@assignment, @course, :purpose => 'grading')
    
    get "/courses/#{@course.id}/assignments/#{@assignment.id}"
    
    driver.find_element(:css, "#rubrics .rubric_title").text.should == "My Rubric"
    driver.find_element(:css, ".criterion_description .long_description_link").click
    driver.find_element(:css, ".ui-dialog div.long_description").text.should == "This is awesome."
  end

  it "should highlight mini-calendar dates where stuff is due" do
    course_with_student_logged_in
    
    due_date = Time.now.utc + 2.days
    @assignment = @course.assignments.create(:name => 'assignment', :due_at => due_date)
    
    get "/courses/#{@course.id}/assignments/syllabus"
    
    driver.find_element(:css, ".mini_calendar_day.date_#{due_date.strftime("%m_%d_%Y")}").
      attribute('class').should match /has_event/
  end

  it "should not allow XSS attacks through rubric descriptions" do
    course_with_teacher_logged_in
    
    student = user_with_pseudonym :active_user => true,
      :username => "student@example.com",
      :password => "password"
    @course.enroll_user(student, "StudentEnrollment", :enrollment_state => 'active')
    
    @assignment = @course.assignments.create(:name => 'assignment with rubric')
    @rubric = Rubric.new(:title => 'My Rubric', :context => @course)
    @rubric.data = [
      {
        :points => 3,
        :description => "XSS Attack!",
        :long_description => "<b>This text should not be bold</b>",
        :id => 1,
        :ratings => [
          {
            :points => 3,
            :description => "Rockin'",
            :criterion_id => 1,
            :id => 2
          },
          {
            :points => 0,
            :description => "Lame",
            :criterion_id => 1,
            :id => 3
          }
        ]
      }
    ]
    @rubric.save!
    @rubric.associate_with(@assignment, @course, :purpose => 'grading')
  
    get "/courses/#{@course.id}/assignments/#{@assignment.id}"
    
    driver.find_element(:id, "rubric_#{@rubric.id}").find_element(:css, ".long_description_link").click
    driver.find_element(:css, "#rubric_long_description_dialog div.displaying .long_description").
           text.should == "<b>This text should not be bold</b>"
    driver.find_element(:css, '.ui-icon-closethick').click 
   
    get "/courses/#{@course.id}/gradebook/speed_grader?assignment_id=#{@assignment.id}"
    
    driver.find_element(:css, ".toggle_full_rubric").click
    wait_for_animations
    driver.find_element(:css, '#criterion_1 .long_description_link').click
    keep_trying_until { driver.find_element(:id, 'rubric_long_description_dialog').should be_displayed }
    driver.find_element(:css, "#rubric_long_description_dialog div.displaying .long_description").
           text.should == "<b>This text should not be bold</b>"
  end

  it "should display assignment on calendar and link to assignment" do
    course_with_teacher_logged_in

    assignment_name = 'first assignment'
    current_date = Time.now.utc
    due_date = current_date + 2.days
    @assignment = @course.assignments.create(:name => assignment_name, :due_at => due_date)

    get "/calendar"

    #click on assignment in calendar
    if due_date.month > current_date.month
      driver.find_element(:css, '#content .next_month_link').click
      wait_for_ajax_requests
    end
    day_id = 'day_' + due_date.year.to_s() + '_' + due_date.strftime('%m') + '_' + due_date.strftime('%d')
    day_div = driver.find_element(:id, day_id)
    sleep 1 # this is one of those cases where if we click too early, no subsequent clicks will work
    day_div.find_element(:link, assignment_name).click
    wait_for_animations
    details_dialog = driver.find_element(:id, 'event_details').find_element(:xpath, '..')
    details_dialog.should include_text(assignment_name)
    details_dialog.find_element(:css, '.edit_event_link').click
    details_dialog = driver.find_element(:id, 'edit_event').find_element(:xpath, '..')
    details_dialog.find_element(:name, 'assignment[title]').should be_displayed
    details_dialog.find_element(:css, '#edit_assignment_form .more_options_link').click
    #make sure user is taken to assignment details
    driver.find_element(:css, 'h2.title').should include_text(assignment_name)

  end

  it "should create an assignment group" do
    course_with_teacher_logged_in
    get "/courses/#{@course.id}/assignments"

    wait_for_animations
    driver.find_element(:css, '#right-side .add_group_link').click
    driver.find_element(:id, 'assignment_group_name').send_keys('test group')
    driver.find_element(:id, 'add_group_form').submit
    wait_for_animations
    driver.find_element(:id, 'add_group_form').should_not be_displayed
    driver.find_element(:css, '#groups .assignment_group').should include_text('test group')
  end


  it "should edit group details" do
    course_with_teacher_logged_in
    assignment_group = @course.assignment_groups.create!(:name => "first test group")
    assignment = @course.assignments.create(:title => 'assignment with rubric', :assignment_group => assignment_group)
    get "/courses/#{@course.id}/assignments"

    #edit group grading rules
    driver.find_element(:css, '.edit_group_link img').click
    #set number of lowest scores to drop
    driver.find_element(:css, '.add_rule_link').click
    driver.find_element(:css, 'input.drop_count').send_keys('2')
    #set number of highest scores to drop
    driver.find_element(:css, '.add_rule_link').click
    option_value = find_option_value(
      :css,
      '.form_rules div:nth-child(2) select',
      I18n.t('options.drop_highest', 'Drop the Highest')
    )
    driver.find_element(:css, '.form_rules div:nth-child(2) select option[value="'+option_value+'"]').click
    driver.find_element(:css, '.form_rules div:nth-child(2) input').send_keys('3')
    #set assignment to never drop
    driver.find_element(:css, '.add_rule_link').click
    never_drop_css = '.form_rules div:nth-child(3) select'
    option_value = find_option_value(
      :css,
      never_drop_css,
      I18n.t('options.never_drop', 'Never Drop')
    )
    driver.find_element(:css, never_drop_css + ' option[value="'+option_value+'"]').click
    wait_for_animations
    assignment_css = '.form_rules div:nth-child(3) .never_drop_assignment select'
    keep_trying_until{ driver.find_element(:css, assignment_css).displayed? }
    option_value = find_option_value(:css, assignment_css, assignment.title)
    driver.find_element(:css, assignment_css+' option[value="'+option_value+'"]').click
    #delete second grading rule and save
    driver.find_element(:css, '.form_rules div:nth-child(2) a img').click
    driver.find_element(:css, '#add_group_form button[type="submit"]').click

    #verify grading rules
    driver.find_element(:css, '.more_info_link').click
    driver.find_element(:css, '.assignment_group .rule_details').should include_text('2')
    driver.find_element(:css, '.assignment_group .rule_details').should include_text('assignment with rubric')
  end

  it "should edit assignment group's grade weights" do
    course_with_teacher_logged_in
    @course.assignment_groups.create!(:name => "first group")
    @course.assignment_groups.create!(:name => "second group")
    get "/courses/#{@course.id}/assignments"

    driver.find_element(:id, 'class_weighting_policy').click
    #wanted to change number but can only use clear because of the auto insert of 0 after clearing
    # the input
    driver.find_element(:css, 'input.weight').clear
    #need to wait for the total to update
    wait_for_animations
    keep_trying_until{ driver.find_element(:id, 'group_weight_total').text.should == '50%' }
  end

  it "should create an assignment" do
    assignment_name = 'first assignment'
    course_with_teacher_logged_in
    @course.assignment_groups.create!(:name => "first group")
    @course.assignment_groups.create!(:name => "second group")
    get "/courses/#{@course.id}/assignments"

    #create assignment
    option_value = find_option_value(:css, '#right-side select.assignment_groups_select', 'second group')
    driver.find_element(:css, '#right-side select.assignment_groups_select > option[value="'+option_value+'"]').click
    driver.find_element(:css, '.add_assignment_link').click
    driver.find_element(:id, 'assignment_title').send_keys(assignment_name)
    driver.find_element(:css, '.ui-datepicker-trigger').click
    driver.find_element(:css, '#ui-datepicker-div .ui-datepicker-next').click
    driver.find_element(:css, '.ui-datepicker-calendar tr:first-child td:last-child a').click
    driver.find_element(:css, '#ui-datepicker-div .ui-datepicker-ok').click
    driver.find_element(:id, 'assignment_points_possible').send_keys('5')
    driver.
      find_element(:id, 'add_assignment_form').submit

    #make sure assignment was added to correct assignment group
    wait_for_animations
    first_group = driver.find_element(:css, '#groups .assignment_group:nth-child(2)')
    first_group.should include_text('second group')
    first_group.should include_text(assignment_name)

    #click on assignment link
    driver.find_element(:link, assignment_name).click
    driver.find_element(:css, 'h2.title').should include_text(assignment_name)
  end

  it "should edit an assignment" do
    course_with_teacher_logged_in
    assignment_name = 'first test assignment'
    due_date = Time.now.utc + 2.days
    group = @course.assignment_groups.create!(:name => "default")
    second_group = @course.assignment_groups.create!(:name => "second default")
    assignment = @course.assignments.create!(
      :name => assignment_name,
      :due_at => due_date,
      :assignment_group => group
      )

    get "/courses/#{@course.id}/assignments"
     
    driver.find_element(:link, assignment_name).click
    driver.find_element(:css, '.edit_full_assignment_link').click
    driver.find_element(:id, 'assignment_title').send_keys(' edit')
    driver.find_element(:css, '.more_options_link').click
    driver.find_element(:id, 'assignment_assignment_group_id').should be_displayed
    option_value = find_option_value(:css, '#assignment_assignment_group_id', second_group.name)
    driver.find_element(:css, '#assignment_assignment_group_id > option[value="'+option_value+'"]').click
    #not using select_option_text because there is a carriage return in the option text
    driver.find_element(:id, 'assignment_grading_type').click
    driver.find_element(:css, '#assignment_grading_type option[value="letter_grade"]').click

    #check grading levels dialog
    wait_for_animations
    keep_trying_until{ driver.find_element(:css, 'a.edit_letter_grades_link').should be_displayed }
    driver.find_element(:css, 'a.edit_letter_grades_link').click
    wait_for_animations
    driver.find_element(:id, 'ui-dialog-title-edit_letter_grades_form').should be_displayed
    driver.find_element(:css, '.ui-icon-closethick').click
    driver.find_element(:id, 'ui-dialog-title-edit_letter_grades_form').should_not be_displayed

    #check peer reviews option
    driver.find_element(:css, '#edit_assignment_form #assignment_peer_reviews').click
    driver.find_element(:css, '#edit_assignment_form #auto_peer_reviews').click
    driver.find_element(:css, '#edit_assignment_form #assignment_peer_review_count').send_keys('2')
    driver.find_element(:css, '#edit_assignment_form #assignment_peer_reviews_assign_at + img').click
    driver.find_element(:css, '#ui-datepicker-div .ui-datepicker-next').click
    driver.find_element(:css, '.ui-datepicker-calendar tr:first-child td:last-child a').click
    driver.find_element(:css, '#ui-datepicker-div .ui-datepicker-ok').click

    #save changes
    driver.find_element(:id, 'edit_assignment_form').submit
    wait_for_animations
    driver.find_element(:css, 'h2.title').should include_text(assignment_name + ' edit')
  end

  it "should add a new rubric to assignment" do
    course_with_teacher_logged_in
    assignment_name = 'first test assignment'
    due_date = Time.now.utc + 2.days
    @group = @course.assignment_groups.create!(:name => "default")
    @second_group = @course.assignment_groups.create!(:name => "second default")
    @assignment = @course.assignments.create(
      :name => assignment_name,
      :due_at => due_date,
      :assignment_group => @group
      )

    get "/courses/#{@course.id}/assignments/#{@assignment.id}"

    driver.find_element(:css, '.add_rubric_link').click
    driver.find_element(:css, '.rubric_title input[name="title"]').clear
    driver.find_element(:css, '.rubric_title input[name="title"]').send_keys('new rubric')
    driver.find_element(:id, 'edit_rubric_form').submit
    wait_for_animations
    driver.find_element(:css, '#rubrics .rubric .rubric_title .displaying .title').should include_text('new rubric')
  end

  context "turnitin" do
    before do
      course_with_teacher_logged_in
      account = Account.default
      account.turnitin_account_id = 'asdf'
      account.turnitin_shared_secret = 'asdf'
      account.save
      @course.account = account
      @course.save
    end

    def change_turnitin_settings
      driver.find_element(:css, '.submission_type_option').should be_displayed
      driver.find_element(:css, '.submission_type_option > option[value="online"]').click
      driver.find_element(:id, 'assignment_online_text_entry').click
      driver.find_element(:id, 'assignment_turnitin_settings').should_not be_displayed
      driver.find_element(:id, 'assignment_turnitin_enabled').click
      driver.find_element(:id, 'assignment_turnitin_settings').should be_displayed
      driver.find_element(:css, '.show_turnitin_settings').click
      wait_for_animations
      driver.find_element(:id, 'turnitin_settings_form').should be_displayed

      driver.find_element(:css, '#settings_originality_report_visibility > option[value="after_due_date"]').click # immediate -> after_due_date
      driver.find_element(:id, 'settings_student_paper_check').click # 1 -> 0
      driver.find_element(:id, 'settings_internet_check').click # 1 -> 0
      driver.find_element(:id, 'settings_journal_check').click # 1 -> 0
      driver.find_element(:id, 'settings_exclude_biblio').click # 1 -> 0
      driver.find_element(:id, 'settings_exclude_quoted').click # 1 -> 0
      driver.find_element(:id, 'settings_exclude_small_matches').click # 0 -> 1
      driver.find_element(:id, 'settings_exclude_fewer_than_count').click # 0 -> 1
      driver.find_element(:id, 'settings_exclude_value_count').send_keys("5") # '' -> 5
      driver.find_element(:id, 'turnitin_settings_form').submit
      wait_for_ajaximations
    end

    def expected_settings
      {
        'originality_report_visibility' => 'after_due_date',
        's_paper_check' => '0',
        'internet_check' => '0',
        'journal_check' => '0',
        'exclude_biblio' => '0',
        'exclude_quoted' => '0',
        'exclude_type' => '1',
        'exclude_value' => '5'
      }
    end

    it "should create turnitin settings" do
      expect {
        get "/courses/#{@course.id}/assignments/new"
  
        driver.find_element(:id, 'assignment_title').send_keys('test assignment')
        change_turnitin_settings
      }.to_not change{ Assignment.count } # although we "saved" the dialog, we haven't actually posted anything yet

      driver.find_element(:id, 'edit_assignment_form').submit
      wait_for_ajaximations

      assignment = Assignment.first(:order => "id desc")
      assignment.turnitin_settings.should eql(expected_settings)
    end

    it "should edit turnitin settings" do
      assignment = @course.assignments.create!(
        :name => 'test assignment',
        :due_at => (Time.now.utc + 2.days),
        :assignment_group => @course.assignment_groups.create!(:name => "default")
        )

      get "/courses/#{@course.id}/assignments/#{assignment.id}/edit"

      change_turnitin_settings

      assignment.reload
      assignment.turnitin_settings.should eql(expected_settings)
    end
  end
end
