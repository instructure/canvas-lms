require File.expand_path(File.dirname(__FILE__) + '/common')
require File.expand_path(File.dirname(__FILE__) + '/helpers/assignments_common')

describe "assignment groups" do
  include_examples "in-process server selenium tests"

  def get_assignment_groups
    ff('.assignment_group')
  end

  before (:each) do
    @domain_root_account = Account.default
    @domain_root_account.enable_feature!(:draft_state)
    course_with_teacher_logged_in
  end

  it "should create an assignment group" do
    get "/courses/#{@course.id}/assignments"

    wait_for_ajaximations
    f('#addGroup').click
    f('#ag_new_name').send_keys('manually created assignment group')
    fj('.create_group:visible').click
    wait_for_ajaximations
    expect(f('#ag-list')).to include_text('manually created assignment group')
  end

  it "should edit group details" do
    assignment_group = @course.assignment_groups.create!(:name => "first test group")
    assignment = @course.assignments.create(:title => 'assignment with rubric', :assignment_group => assignment_group)
    get "/courses/#{@course.id}/assignments"

    #edit group grading rules
    edit_assignment_group(assignment_group.id)
    #set number of lowest scores to drop
    replace_content(f("#ag_#{assignment_group.id}_drop_lowest"), '1')
    #set number of highest scores to drop
    replace_content(f("#ag_#{assignment_group.id}_drop_highest"), '1')
    #set assignment to never drop
    f('.add_never_drop').click
    #check to make sure our created assignment is auto selected to never be dropped
    expect(f('.never_drop_rule')).to include_text(assignment.title)
    fj('.create_group:visible').click
    wait_for_ajaximations
    #verify grading rules via index page
    f(".tooltip_link").click
    items = ffj(".ui-tooltip-content:visible span").map(&:text)
    expect(items.include?('Drop the lowest score')).to eq true
    expect(items.include?('Drop the highest score')).to eq true
    expect(items.include?('Never drop assignment with rubric')).to eq true
    #verify grading rules via the assignment group edit modal window
    edit_assignment_group(assignment_group.id)
    expect(get_value("#ag_#{assignment_group.id}_drop_lowest")).to include_text('1')
    expect(get_value("#ag_#{assignment_group.id}_drop_highest")).to include_text('1')
    expect(f('div.never_drop_rule span')).to include_text(assignment.title)
  end

  it "should edit assignment groups grade weights and round them to 2 decimal places" do
    ag1 = @course.assignment_groups.create!(:name => "first group")
    ag2 = @course.assignment_groups.create!(:name => "second group")
    get "/courses/#{@course.id}/assignments"
    #first we need to enable grade weighting
    f('#assignmentSettingsCog').click
    f('#weight-groups').click
    #then we replace the weight field from 0% to 25% of our first assignment group
    replace_content(f('.group_weight_value'), '33.32798546')
    #check the calculated total, it should round our 33.32798546 to 33.33
    fj(".ag-weights-tr").click
    expect(f("#percent_total")).to include_text("33.33%")
    #save it by clicking the save button
    f('#update-assignment-settings').click
    wait_for_ajaximations
    #open and edit our 2nd assignment group and change its weight from 0 to 66.6289654 then save
    f("#assignment_group_#{ag2.id} .al-trigger").click
    f("#assignment_group_#{ag2.id} .edit_group").click
    replace_content(f("#ag_#{ag2.id}_group_weight"), "66.6289654")
    # click away from the input box to activate rounding and check to see if it rounded
    f("#ag_#{ag2.id}_name").send_keys("some text")
    wait_for_ajaximations
    expect(f("#ag_#{ag2.id}_group_weight")).to have_value('66.63')
    fj('.create_group:visible').click
    #check the index UI to see that both assignment group weights were values were saved and rounded
    wait_for_ajaximations
    expect(f("#assignment_group_#{ag1.id}")).to include_text("33.33% of Total")
    expect(f("#assignment_group_#{ag2.id}")).to include_text("66.63% of Total")
  end

  it "should add multiple assignment groups and not allow the last one to be deleted" do
    #create 4 assignment groups and pop them into a list
    aglist = []
    4.times do |i|
      aglist << @course.assignment_groups.create!(:name => "group_#{i}")
    end

    get "/courses/#{@course.id}/assignments"

    #grab the amount of assignment groups we have and iterate through the last 3 in our list and delete them
    assignment_groups_count = (get_assignment_groups.count - 1)

    assignment_groups_count.downto(1) do |i|
      delete_assignment_group(aglist[i].id)
    end

    # check to make sure our last assignment group is there
    expect(f("#assignment_group_#{aglist[0].id}")).to include_text("group_0")
    delete_assignment_group(aglist[0].id, :no_accept => true)
    # check for the javascript "You must have at least one assignment group" alert and accept it
    expect(alert_present?).to eq true
    accept_alert
    # make sure it really didn't delete our last assignment group
    refresh_page
    expect(f("#assignment_group_#{aglist[0].id}")).to include_text("group_0")
  end

  #This feels like it would be better suited here than in QUnit
  it "should not remove new assignments when editing a group" do
    @assignment_group = @course.assignment_groups.create!(:name => "Test Group")
    @course.assignments.create(:name => "test", :assignment_group => @assignment_group)
    get "/courses/#{@course.id}/assignments"
    wait_for_ajaximations
    ag = @course.assignment_groups.first

    f("#assignment_group_#{ag.id} .add_assignment").click
    wait_for_animations

    replace_content(f("#ag_#{ag.id}_assignment_name"), "Disappear")
    fj('.create_assignment:visible').click
    wait_for_ajaximations

    expect(fj("#assignment_group_#{ag.id} .assignment:eq(1) .ig-title").text).to match "Disappear"

    edit_assignment_group(ag.id)

    replace_content(f("#ag_#{ag.id}_name"), "Modified Group")
    fj('.create_group:visible').click
    wait_for_ajaximations

    expect(fj("#assignment_group_#{ag.id} .assignment:eq(1) .ig-title").text).to match "Disappear"
  end

  #Because of the way this feature was made, i recommend we keep this one
  it "should move assignments to another assignment group" do
    @assignment_group = @course.assignment_groups.create!(:name => "Test Group")
    @course.assignments.create(:name => "test", :assignment_group => @assignment_group)
    before_count = @assignment_group.assignments.count
    @ag2 = @course.assignment_groups.create!(:name => "2nd Group")
    @assignment = @course.assignments.create(:name => "Test assignment", :assignment_group => @ag2)
    get "/courses/#{@course.id}/assignments"
    wait_for_ajaximations

    delete_assignment_group(@ag2.id, :no_accept => true)

    fj('.assignment_group_move:visible').click

    click_option('.group_select:visible', @assignment_group.id.to_s, :value)

    fj('.delete_group:visible').click
    wait_for_ajaximations

    # two id selectors to make sure it moved
    expect(fj("#assignment_group_#{@assignment_group.id} #assignment_#{@assignment.id}")).to_not be_nil

    @assignment.reload
    expect(@assignment.assignment_group).to eq @assignment_group
  end

  it "should reorder assignment groups with drag and drop" do
    @assignment_group = @course.assignment_groups.create!(:name => "Test Group")
    @course.assignments.create(:name => "test", :assignment_group => @assignment_group)
    ags = [@assignment_group]
    4.times do |i|
      ags << @course.assignment_groups.create!(:name => "group_#{i}")
    end
    expect(ags.collect(&:position)).to eq [1,2,3,4,5]

    get "/courses/#{@course.id}/assignments"
    wait_for_ajaximations
    drag_with_js("#assignment_group_#{ags[1].id} .sortable-handle", 0, 100)
    wait_for_ajaximations

    ags.each {|ag| ag.reload}
    expect(ags.collect(&:position)).to eq [1,3,2,4,5]
  end

end
