require File.expand_path(File.dirname(__FILE__) + '/common')

describe "assignment groups" do
  it_should_behave_like "in-process server selenium tests"

  def get_assignment_groups
    ff('#groups .assignment_group')
  end

  before (:each) do
    course_with_teacher_logged_in
  end

  it "should create an assignment group" do
    get "/courses/#{@course.id}/assignments"

    wait_for_ajaximations
    f('#right-side .add_group_link').click
    f('#assignment_group_name').send_keys('test group')
    submit_form('#add_group_form')
    wait_for_ajaximations
    f('#add_group_form').should_not be_displayed
    f('#groups .assignment_group').should include_text('test group')
  end


  it "should edit group details" do
    assignment_group = @course.assignment_groups.create!(:name => "first test group")
    assignment = @course.assignments.create(:title => 'assignment with rubric', :assignment_group => assignment_group)
    get "/courses/#{@course.id}/assignments"

    #edit group grading rules
    driver.execute_script %{$('.edit_group_link:first').addClass('focus');}
    f('.edit_group_link').click
    #set number of lowest scores to drop
    f('.add_rule_link').click
    f('input.drop_count').send_keys('2')
    #set number of highest scores to drop
    f('.add_rule_link').click
    click_option('.form_rules div:nth-child(2) select', 'Drop the Highest')
    f('.form_rules div:nth-child(2) input').send_keys('3')
    #set assignment to never drop
    f('.add_rule_link').click
    never_drop_css = '.form_rules div:nth-child(3) select'
    click_option(never_drop_css, 'Never Drop')
    wait_for_ajaximations
    assignment_css = '.form_rules div:nth-child(3) .never_drop_assignment select'
    keep_trying_until { f(assignment_css).displayed? }
    click_option(assignment_css, assignment.title)
    #delete second grading rule and save
    f('.form_rules div:nth-child(2) a').click
    submit_form('#add_group_form')

    #verify grading rules
    f('.more_info_link').click
    f('.assignment_group .rule_details').should include_text('2')
    f('.assignment_group .rule_details').should include_text('assignment with rubric')
  end

  it "should edit assignment groups grade weights" do
    @course.assignment_groups.create!(:name => "first group")
    @course.assignment_groups.create!(:name => "second group")
    get "/courses/#{@course.id}/assignments"

    f('#class_weighting_policy').click
    #wanted to change number but can only use clear because of the auto insert of 0 after clearing
    # the input
    f('input.weight').clear
    #need to wait for the total to update
    wait_for_ajaximations
    keep_trying_until { fj('#group_weight_total').text.should == '50%' }
  end

  it "should reorder assignment groups with drag and drop" do
    ags = []
    4.times do |i|
      ags << @course.assignment_groups.create!(:name => "group_#{i}")
    end
    ags.collect(&:position).should == [1,2,3,4]

    get "/courses/#{@course.id}/assignments"

    driver.execute_script %{$('.group_move_icon').addClass('focus');}
    second_group = fj("#group_#{ags[1].id} .group_move_icon")
    third_group = fj("#group_#{ags[2].id} .group_move_icon")
    driver.action.drag_and_drop(third_group, second_group).perform
    wait_for_ajaximations

    ags.each {|ag| ag.reload}
    ags.collect(&:position).should == [1,3,2,4]
  end

  it "should round assignment groups percentages to 2 decimal places" do
    pending("bug 7387 - Assignment group weight should be rounded to 2 decimal places. Not 10") do
      3.times do |i|
        @course.assignment_groups.create!(:name => "group_#{i}")
      end
      get "/courses/#{@course.id}/assignments"

      f('#class_weighting_policy').click
      wait_for_ajaximations
      group_weights = ff('.assignment_group .more_info_brief')
      group_weights.each_with_index do |gw, i|
        gw.text.should == "33.33%"
      end
      f('#group_weight_total').text.should == "99.99%"
    end
  end

  it "should not allow all assignment groups to be deleted" do
    pending("bug 7480 - User should not be permitted to delete all assignment groups") do
      get "/courses/#{@course.id}/assignments"
      assignment_groups = get_assignment_groups
      assignment_groups.count.should == 1
      assignment_groups[0].find_element(:css, '.delete_group_link').should_not be_displayed
      refresh_page #refresh page to make sure the trashcan doesn't come back
      get_assignment_groups[0].find_element(:css, '.delete_group_link').should_not be_displayed
    end
  end

  it "should add multiple assignment groups and not allow the last one to be deleted" do
    pending("bug 7480 - User should not be permitted to delete all assignment groups") do
      4.times do |i|
        @course.assignment_groups.create!(:name => "group_#{i}")
      end
      get "/courses/#{@course.id}/assignments"

      assignment_groups = get_assignment_groups
      assignment_groups_count = (assignment_groups.count - 1)

      assignment_groups_count.downto(1) do |i|
        assignment_groups[i].find_element(:css, '.delete_group_link').click
        driver.switch_to.alert.accept
        wait_for_ajaximations
        driver.switch_to.default_content
      end
      assignment_groups[0].find_element(:css, '.delete_group_link').should_not be_displayed
      refresh_page ##refresh page to make sure the trashcan doesn't come back
      get_assignment_groups[0].find_element(:css, '.delete_group_link').should_not be_displayed
    end
  end

  context "draft state" do
    before do
      Account.default.settings[:enable_draft] = true
      Account.default.save!
      @domain_root_account = Account.default

      course_with_teacher_logged_in(:active_all => true)
      @assignment_group = @course.assignment_groups.create!(:name => "Test Group")

      get "/courses/#{@course.id}/assignments"
      wait_for_ajaximations
    end

    context "assignment settings modal" do
      def set_to(apply)
        @course.apply_assignment_group_weights=apply
        @course.save
        @course.reload
      end

      def reset_flag_to_true
        #reset the course's flag and the page
        set_to(true)
        get "/courses/#{@course.id}/assignments"
        wait_for_ajaximations

        #now start the test
        f('#assignmentSettingsCog').click
        wait_for_ajaximations
      end

      before do
        set_to(false)
        f('#assignmentSettingsCog').click
        wait_for_ajaximations
      end

      it "should check the box on open" do
        reset_flag_to_true
        is_checked('#apply_assignment_group_weights')
      end

      it "should change a course's apply_assignment_group_weights flag" do
        flag_before = @course.apply_group_weights?

        f('#apply_assignment_group_weights').click
        f('#update-assignment-settings').click
        wait_for_ajaximations

        @course.reload
        flag_after = @course.apply_group_weights?
        flag_after.should_not == flag_before
      end

      it "should hide the weights table" do
        reset_flag_to_true
        f('#apply_assignment_group_weights').click
        f('#assignment_groups_weights').should_not be_displayed
      end

      it "should show the weights table" do
        f('#apply_assignment_group_weights').click
        f('#assignment_groups_weights').should be_displayed
      end

      it "should save an assignment group's weight" do
        f('#apply_assignment_group_weights').click
        val_before = @assignment_group.group_weight
        replace_content(f('.group_weight_value'), '10')
        f('#update-assignment-settings').click
        wait_for_ajaximations
        @assignment_group.reload
        val_after = @assignment_group.group_weight
        val_after.should_not == val_before
      end
    end

    it "should create a new assignment group" do
      count = @course.assignment_groups.count
      f('#content #addGroup').click
      wait_for_ajaximations

      replace_content(f('#ag_new_name'), "Assignment Group 1")
      fj('.create_group:visible').click
      wait_for_ajaximations

      @course.assignment_groups.count.should > count
      new_ag = @course.assignment_groups.order(:id).last
      f("#assignment_group_#{new_ag.id} .ig-header").text.should match "Assignment Group 1"
    end

    it "should edit an existing assignment group" do
      ag = @course.assignment_groups.first
      f("#assignment_group_#{ag.id} .al-trigger").click
      f("#assignment_group_#{ag.id} .edit_group").click
      wait_for_ajaximations

      replace_content(f("#ag_#{ag.id}_name"), "Modified Group")
      fj('.create_group:visible').click
      wait_for_ajaximations

      ag.reload.name.should == "Modified Group"
      f("#assignment_group_#{ag.id} .ig-header").text.should match "Modified Group"
    end

    it "should not remove new assignments when editing a group" do
      ag = @course.assignment_groups.first

      f("#assignment_group_#{ag.id} .add_assignment").click
      wait_for_ajaximations

      replace_content(f("#ag_#{ag.id}_assignment_name"), "Disappear")
      fj('.create_assignment:visible').click
      wait_for_ajaximations

      f("#assignment_group_#{ag.id} .ig-title").text.should match "Disappear"

      f("#assignment_group_#{ag.id} .al-trigger").click
      f("#assignment_group_#{ag.id} .edit_group").click
      wait_for_ajaximations

      replace_content(f("#ag_#{ag.id}_name"), "Modified Group")
      fj('.create_group:visible').click
      wait_for_ajaximations

      f("#assignment_group_#{ag.id} .ig-title").text.should match "Disappear"
    end

    it "should save drop rules" do
      ag = @course.assignment_groups.first
      f("#assignment_group_#{ag.id} .al-trigger").click
      f("#assignment_group_#{ag.id} .edit_group").click
      wait_for_ajaximations

      replace_content(f("#ag_#{ag.id}_drop_lowest"), "1")
      replace_content(f("#ag_#{ag.id}_drop_highest"), "1")
      fj('.create_group:visible').click
      wait_for_ajaximations

      ag.reload
      ag.rules_hash[:drop_lowest].should == 1
      ag.rules_hash[:drop_highest].should == 1
      f("#assignment_group_#{ag.id} .ig-header").text.should match "2 Rules"
    end

    it "should not save drop rules when non are given" do
      ag = @course.assignment_groups.first
      f("#assignment_group_#{ag.id} .al-trigger").click
      f("#assignment_group_#{ag.id} .edit_group").click
      wait_for_ajaximations

      replace_content(f("#ag_#{ag.id}_name"), "Modified Group")
      fj('.create_group:visible').click
      wait_for_ajaximations

      ag.reload.rules_hash.should be_blank
      f("#assignment_group_#{ag.id} .ig-header").text.should_not match "Rule"
    end

    it "should delete an assignment group with assignments" do
      @ag2 = @course.assignment_groups.create!(:name => "2nd Group")
      @course.assignments.create(:name => "Test assignment", :assignment_group => @ag2)
      refresh_page
      wait_for_ajaximations

      f("#assignment_group_#{@ag2.id} .al-trigger").click
      f("#assignment_group_#{@ag2.id} .delete_group").click
      wait_for_ajaximations

      fj('.delete_group:visible').click
      wait_for_ajaximations

      @ag2.reload
      @ag2.workflow_state.should == 'deleted'
    end

    it "should delete an assignment group without assignments" do
      @ag2 = @course.assignment_groups.create!(:name => "2nd Group")
      refresh_page
      wait_for_ajaximations

      f("#assignment_group_#{@ag2.id} .al-trigger").click
      f("#assignment_group_#{@ag2.id} .delete_group").click

      driver.switch_to.alert.should_not be nil
      driver.switch_to.alert.accept
      wait_for_ajaximations

      @ag2.reload
      @ag2.workflow_state.should == 'deleted'
    end

    it "should not delete the last assignment group" do

      f("#assignment_group_#{@assignment_group.id} .al-trigger").click
      f("#assignment_group_#{@assignment_group.id} .delete_group").click

      driver.switch_to.alert.should_not be nil
      driver.switch_to.alert.accept

      @assignment_group.reload
      @assignment_group.should_not be nil
    end

    it "should move assignments to another assignment group" do
      before_count = @assignment_group.assignments.count
      @ag2 = @course.assignment_groups.create!(:name => "2nd Group")
      @assignment = @course.assignments.create(:name => "Test assignment", :assignment_group => @ag2)
      refresh_page
      wait_for_ajaximations

      f("#assignment_group_#{@ag2.id} .al-trigger").click
      f("#assignment_group_#{@ag2.id} .delete_group").click
      wait_for_ajaximations

      fj('.assignment_group_move:visible').click
      click_option('.group_select:visible', @assignment_group.id.to_s, :value)

      fj('.delete_group:visible').click
      wait_for_ajaximations

      # two id selectors to make sure it moved
      fj("#assignment_group_#{@assignment_group.id} #assignment_#{@assignment.id}").should_not be_nil

      @assignment.reload
      @assignment.assignment_group.should == @assignment_group
    end

    it "should persist collapsed assignment groups" do
      selector = "#assignment_group_#{@assignment_group.id} .element_toggler"
      f(selector).click
      wait_for_ajaximations
      refresh_page
      wait_for_ajaximations
      f(selector).should have_attribute('aria-expanded', 'false')
    end

    it "should update delete dialog properly" do
      @ag2 = @course.assignment_groups.create!(:name => "2nd Group")
      @course.assignments.create(:name => "Test assignment", :assignment_group => @ag2)
      refresh_page
      wait_for_ajaximations

      # open the delete dialog the first time
      f("#assignment_group_#{@ag2.id} .al-trigger").click
      f("#assignment_group_#{@ag2.id} .delete_group").click
      wait_for_ajaximations

      # check assignment count and move to options
      fj('.assignment_count:visible').text.should == "1"
      ffj('.group_select:visible option').count.should == 2 # default + ag1
      fj('.cancel_button:visible').click

      # now create a new assignment
      f("#assignment_group_#{@ag2.id} .add_assignment").click
      wait_for_ajaximations

      replace_content(f("#ag_#{@ag2.id}_assignment_name"), "Do this")
      replace_content(f("#ag_#{@ag2.id}_assignment_points"), "13")
      fj('.create_assignment:visible').click
      wait_for_ajaximations

      # and a new group
      f('#content #addGroup').click
      wait_for_ajaximations

      replace_content(f('#ag_new_name'), "Assignment Group 1")
      fj('.create_group:visible').click
      wait_for_ajaximations

      # and then open the delete dialog again and see if options are updated
      keep_trying_until do
        f("#assignment_group_#{@ag2.id} .al-trigger").click
        f("#assignment_group_#{@ag2.id} .delete_group").click
        wait_for_ajaximations
        fj('.assignment_count:visible').present?
      end

      fj('.assignment_count:visible').text.should == "2"
      ffj('.group_select:visible option').count.should == 3 # default + ag1 + ag3
      fj('.cancel_button:visible').click
    end

    it "should reorder assignment groups with drag and drop" do
      ags = [@assignment_group]
      4.times do |i|
        ags << @course.assignment_groups.create!(:name => "group_#{i}")
      end
      ags.collect(&:position).should == [1,2,3,4,5]

      refresh_page
      wait_for_ajaximations
      drag_with_js("#assignment_group_#{ags[1].id} .sortable-handle", 0, 100)
      wait_for_ajaximations

      ags.each {|ag| ag.reload}
      ags.collect(&:position).should == [1,3,2,4,5]
    end

    it "should correctly display rules tooltip" do
      @assignment_group.rules_hash = {
        'drop_lowest' => '1',
        'drop_highest' => '1'
      }
      @assignment_group.save!

      refresh_page
      wait_for_ajaximations

      anchor = fj("#assignment_group_#{@assignment_group.id} .ag-header-controls .tooltip_link")
      anchor.text.should == "2 Rules"
      anchor.should have_attribute('title', "Drop the lowest score and Drop the highest score")
    end

    context "modules" do
      before do
        @module = @course.context_modules.create!(:name => "module 1")
        @assignment = @course.assignments.create!(:name => 'assignment 1', :assignment_group => @assignment_group)
        @module.add_item :type => 'assignment', :id => @assignment.id
      end

      it "should show a single module's name" do
        refresh_page
        wait_for_ajaximations
        f("#assignment_group_#{@assignment_group.id} .ig-row .ig-details .modules").text.should == "#{@module.name} Module"
      end

      it "should correctly display multiple modules" do
        @a2 = @course.assignments.create!(:name => 'assignment 2', :assignment_group => @assignment_group)
        @m2 = @course.context_modules.create!(:name => "module 2")
        @module.add_item :type => 'assignment', :id => @a2.id
        @m2.add_item :type => 'assignment', :id => @a2.id
        refresh_page
        wait_for_ajaximations
        anchor = fj("[data-item-id=#{@a2.id}] .modules .tooltip_link")
        anchor.text.should == "Multiple Modules"
        anchor.should have_attribute('title', "#{@module.name},#{@m2.name}")
      end
    end
  end
end
