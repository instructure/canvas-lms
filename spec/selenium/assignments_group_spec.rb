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
    @course.enable_feature!(:draft_state)
    @course.require_assignment_group
    @assignment_group = @course.assignment_groups.first
    @course.assignments.create(:name => "test", :assignment_group => @assignment_group)
  end

  it "should create a new assignment group" do
    get "/courses/#{@course.id}/assignments"
    wait_for_ajaximations

    f("#addGroup").click
    wait_for_ajaximations

    replace_content(f("#ag_new_name"), "Second AG")
    fj('.create_group:visible').click
    wait_for_ajaximations

    expect(ff('.assignment_group .ig-header h2').map(&:text)).to include("Second AG")
  end

  #Per selenium guidelines, we should not test buttons navigating to a page
  # We could test that the page loads with the correct info from the params elsewhere
  it "should remember entered settings when 'more options' is pressed" do
    ag2 = @course.assignment_groups.create!(:name => "blah")

    get "/courses/#{@course.id}/assignments"
    wait_for_ajaximations

    f("#assignment_group_#{ag2.id} .add_assignment").click
    wait_for_ajaximations

    replace_content(f("#ag_#{ag2.id}_assignment_name"), "Do this")
    replace_content(f("#ag_#{ag2.id}_assignment_points"), "13")
    expect_new_page_load { fj('.more_options:visible').click }

    expect(get_value("#assignment_name")).to eq "Do this"
    expect(get_value("#assignment_points_possible")).to eq "13"
    expect(get_value("#assignment_group_id")).to eq ag2.id.to_s
  end

  it "should edit group details" do
    assignment_group = @course.assignment_groups.create!(:name => "first test group")
    4.times do
      @course.assignments.create(:title => 'other assignment', :assignment_group => assignment_group)
    end
    assignment = @course.assignments.create(:title => 'assignment with rubric', :assignment_group => assignment_group)

    get "/courses/#{@course.id}/assignments"

    #edit group grading rules
    f("#ag_#{assignment_group.id}_manage_link").click
    fj(".edit_group:visible:first").click
    #set number of lowest scores to drop
    f("#ag_#{assignment_group.id}_drop_lowest").send_keys('1')
    #set number of highest scores to drop
    f("#ag_#{assignment_group.id}_drop_highest").send_keys('2')
    #set assignment to never drop

    fj('.add_never_drop:visible').click
    keep_trying_until { fj('.never_drop_rule select').present? }

    click_option('.never_drop_rule select', assignment.title)
    keep_trying_until do
      fj('.create_group:visible').click
      wait_for_ajaximations

      #verify grading rules
      assignment_group.reload
      expect(assignment_group.rules_hash["drop_lowest"]).to eq 1
      expect(assignment_group.rules_hash["drop_highest"]).to eq 2
      expect(assignment_group.rules_hash["never_drop"]).to eq [assignment.id]
    end
  end

  it "should edit assignment groups grade weights" do
    @course.update_attribute(:group_weighting_scheme, 'percent')
    ag1 = @course.assignment_groups.create!(:name => "first group")
    ag2 = @course.assignment_groups.create!(:name => "second group")

    get "/courses/#{@course.id}/assignments"

    f("#ag_#{ag1.id}_manage_link").click
    fj(".edit_group:visible:first").click
    #wanted to change number but can only use clear because of the auto insert of 0 after clearing
    # the input
    fj('input[name="group_weight"]:visible').send_keys('50')
    #need to wait for the total to update
    fj('.create_group:visible').click
    wait_for_ajaximations

    keep_trying_until { expect(f("#assignment_group_#{ag1.id} .ag-header-controls").text).to include('50% of Total') }
  end

  #This feels like it would be better suited here than in QUnit
  it "should not remove new assignments when editing a group" do
    get "/courses/#{@course.id}/assignments"
    wait_for_ajaximations
    ag = @course.assignment_groups.first

    f("#assignment_group_#{ag.id} .add_assignment").click
    wait_for_animations

    replace_content(f("#ag_#{ag.id}_assignment_name"), "Disappear")
    fj('.create_assignment:visible').click
    wait_for_ajaximations

    expect(fj("#assignment_group_#{ag.id} .assignment:eq(1) .ig-title").text).to match "Disappear"

    f("#assignment_group_#{ag.id} .al-trigger").click
    f("#assignment_group_#{ag.id} .edit_group").click
    wait_for_ajaximations

    replace_content(f("#ag_#{ag.id}_name"), "Modified Group")
    fj('.create_group:visible').click
    wait_for_ajaximations

    expect(fj("#assignment_group_#{ag.id} .assignment:eq(1) .ig-title").text).to match "Disappear"
  end

  #Because of the way this feature was made, i recommend we keep this one
  it "should move assignments to another assignment group" do
    before_count = @assignment_group.assignments.count
    @ag2 = @course.assignment_groups.create!(:name => "2nd Group")
    @assignment = @course.assignments.create(:name => "Test assignment", :assignment_group => @ag2)
    get "/courses/#{@course.id}/assignments"
    wait_for_ajaximations

    f("#assignment_group_#{@ag2.id} .al-trigger").click
    f("#assignment_group_#{@ag2.id} .delete_group").click
    wait_for_ajaximations

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
