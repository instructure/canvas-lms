#
# Copyright (C) 2012 - present Instructure, Inc.
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

require_relative '../common'
require_relative '../helpers/assignments_common'

describe "assignment group that can't manage assignments" do
  include_context "in-process server selenium tests"
  include AssignmentsCommon

  it "does not display the manage cog menu" do
    @domain_root_account = Account.default
    course_factory
    account_admin_user_with_role_changes(:role_changes => {:manage_course => true,
                                                           :manage_assignments => false})
    user_session(@user)
    @course.require_assignment_group
    @assignment_group = @course.assignment_groups.first
    @course.assignments.create(name: "test", assignment_group: @assignment_group)
    get "/courses/#{@course.id}/assignments"

    wait_for_ajaximations

    expect(f("#content")).not_to contain_css("#assignmentSettingsCog")
  end
end

describe "assignment groups" do
  include_context "in-process server selenium tests"
  include AssignmentsCommon

  def get_assignment_groups
    ff('.assignment_group')
  end

  before(:each) do
    @domain_root_account = Account.default
    course_with_teacher_logged_in
    @course.require_assignment_group
    @assignment_group = @course.assignment_groups.first
    @course.assignments.create(name: "test", assignment_group: @assignment_group)
  end

  it "should create a new assignment group", priority: "1", test_id: 120673 do
    get "/courses/#{@course.id}/assignments"
    wait_for_ajaximations

    f("#addGroup").click
    wait_for_ajaximations

    replace_content(f("#ag_new_name"), "Second AG")
    fj('.create_group:visible').click
    wait_for_ajaximations

    expect(ff('.assignment_group .ig-header h2').map(&:text)).to include("Second AG")
  end

  it "should default to proper group when using group's inline add assignment button", priority: "2", test_id: 209998 do
    @course.require_assignment_group
    ag = @course.assignment_groups.create!(name: "Pamplemousse")

    get "/courses/#{@course.id}/assignments"
    wait_for_ajaximations

    f("#assignment_group_#{ag.id} .add_assignment").click

    wait_for_ajaximations
    fj('.more_options:visible').click
    wait_for_ajaximations

    expect(get_value("#assignment_group_id")).to eq ag.id.to_s
  end

  # Per selenium guidelines, we should not test buttons navigating to a page
  # We could test that the page loads with the correct info from the params elsewhere
  it "should remember entered settings when 'more options' is pressed", priority: "2", test_id: 209999 do
    ag2 = @course.assignment_groups.create!(name: "blah")

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

  it "should edit group details", priority: "1", test_id: 120672 do
    assignment_group = @course.assignment_groups.create!(name: "first test group")
    4.times do
      @course.assignments.create(title: 'other assignment', assignment_group: assignment_group)
    end
    assignment = @course.assignments.create(title: 'assignment with rubric', assignment_group: assignment_group)

    get "/courses/#{@course.id}/assignments"
    wait_for_ajaximations

    # edit group grading rules
    f("#ag_#{assignment_group.id}_manage_link").click
    fj(".edit_group:visible:first").click
    # change the name
    f("#ag_#{assignment_group.id}_name").clear
    f("#ag_#{assignment_group.id}_name").send_keys('name change')
    # set number of lowest scores to drop
    f("#ag_#{assignment_group.id}_drop_lowest").clear
    f("#ag_#{assignment_group.id}_drop_lowest").send_keys('1')
    # set number of highest scores to drop
    f("#ag_#{assignment_group.id}_drop_highest").clear
    f("#ag_#{assignment_group.id}_drop_highest").send_keys('2')
    # set assignment to never drop
    fj('.add_never_drop:visible').click
    expect(f('.never_drop_rule select')).to be
    click_option('.never_drop_rule select', assignment.title)
    # save it
    fj('.create_group:visible').click
    wait_for_ajaximations
    assignment_group.reload
    # verify grading rules
    expect(assignment_group.name).to match 'name change'
    expect(assignment_group.rules_hash["drop_lowest"]).to eq 1
    expect(assignment_group.rules_hash["drop_highest"]).to eq 2
    expect(assignment_group.rules_hash["never_drop"]).to eq [assignment.id]
  end

  it "should edit assignment groups grade weights", priority: "1", test_id: 120675 do
    @course.update_attribute(:group_weighting_scheme, 'percent')
    ag1 = @course.assignment_groups.create!(name: "first group")

    get "/courses/#{@course.id}/assignments"

    f("#ag_#{ag1.id}_manage_link").click
    fj(".edit_group:visible:first").click
    # wanted to change number but can only use clear because of the auto insert of 0 after clearing
    # the input
    fj('input[name="group_weight"]:visible').send_keys('50')
    # need to wait for the total to update
    fj('.create_group:visible').click

    expect(f("#assignment_group_#{ag1.id} .ag-header-controls")).to include_text('50% of Total')
  end

  it "should round group weights to 2 decimal places", priority: "2", test_id: 120676 do
    @course.update_attribute(:group_weighting_scheme, 'percent')
    ag1 = @course.assignment_groups.create!(name: "first group")

    get "/courses/#{@course.id}/assignments"

    f("#ag_#{ag1.id}_manage_link").click
    fj(".edit_group:visible:first").click

    fj('input[name="group_weight"]:visible').send_keys('10.1111')

    fj('.create_group:visible').click

    expect(f("#assignment_group_#{ag1.id} .ag-header-controls")).to include_text('10.11% of Total')
  end

  # This feels like it would be better suited here than in QUnit
  it "should not remove new assignments when editing a group", priority: "1", test_id: 210000 do
    get "/courses/#{@course.id}/assignments"
    wait_for_ajaximations
    ag = @course.assignment_groups.first

    f("#assignment_group_#{ag.id} .add_assignment").click
    wait_for_animations

    replace_content(f("#ag_#{ag.id}_assignment_name"), "Disappear")
    fj('.create_assignment:visible').click
    wait_for_ajaximations
    refresh_page
    expect(fj("#assignment_group_#{ag.id} .assignment:eq(1) .ig-title").text).to match "Disappear"

    f("#assignment_group_#{ag.id} .al-trigger").click
    f("#assignment_group_#{ag.id} .edit_group").click
    wait_for_ajaximations

    replace_content(f("#ag_#{ag.id}_name"), "Modified Group")
    fj('.create_group:visible').click
    wait_for_ajaximations

    expect(fj("#assignment_group_#{ag.id} .assignment:eq(1) .ig-title").text).to match "Disappear"
  end

  # Because of the way this feature was made, i recommend we keep this one
  it "should move assignments to another assignment group", priority: "2", test_id: 210001 do
    before_count = @assignment_group.assignments.count
    @ag2 = @course.assignment_groups.create!(name: "2nd Group")
    @assignment = @course.assignments.create(name: "Test assignment", assignment_group: @ag2)
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
    expect(fj("#assignment_group_#{@assignment_group.id} #assignment_#{@assignment.id}")).not_to be_nil

    @assignment.reload
    expect(@assignment.assignment_group).to eq @assignment_group
  end

  it "should reorder assignment groups with drag and drop", priority: "2", test_id: 210010 do
    ags = [@assignment_group]
    4.times do |i|
      ags << @course.assignment_groups.create!(name: "group_#{i}")
    end
    expect(ags.collect(&:position)).to eq [1,2,3,4,5]

    get "/courses/#{@course.id}/assignments"
    wait_for_ajaximations
    drag_with_js("#assignment_group_#{ags[1].id} .sortable-handle", 0, 100)
    wait_for_ajaximations

    ags.each(&:reload)
    expect(ags.collect(&:position)).to eq [1,3,2,4,5]
  end

  context 'quick-adding an assignment to a group' do
    let(:assignment_group) { @course.assignment_groups.first }
    let(:assignment_name) { "Do this" }
    let(:assignment_points) { "13" }
    let(:time) {Time.zone.local(2018,2,7,4,15)}
    let(:current_time) {format_time_for_view(time, :medium)}

    before :each do
      @course.require_assignment_group

      Timecop.freeze(time) do
        # Navigate to assignments index page.
        get "/courses/#{@course.id}/assignments"
        wait_for_ajaximations

        # Finds and click the Add Assignment button on an assignment group.
        f("#assignment_group_#{assignment_group.id} .add_assignment").click
        wait_for_ajaximations

        # Enter in values for Name, Due, and Points, then clicks save.
        replace_content(f("#ag_#{assignment_group.id}_assignment_name"), assignment_name)
        replace_content(f("#ag_#{assignment_group.id}_assignment_due_at"), current_time)
        replace_content(f("#ag_#{assignment_group.id}_assignment_points"), assignment_points)
        fj('.create_assignment:visible').click
        wait_for_ajaximations
      end
    end

    it 'persists the correct values of the assignment', priority: '1', test_id: 210083 do
      assignment = assignment_group.reload.assignments.last
      expect(assignment.name).to eq "Do this"
      expect(assignment.due_at).to eq time.change({ sec: 0 })
    end

    it 'reflects the new assignment in the Assignments Index page', priority: '1', test_id: 210083 do
      assignment = assignment_group.reload.assignments.last
      expect(ff("#assignment_group_#{assignment_group.id} .ig-title").last.text).to match assignment_name.to_s
      expect(ff("#assignment_group_#{assignment_group.id} .assignment-date-due").last.text).to match current_time
      expect(f("#assignment_#{assignment.id} .non-screenreader").text).to match "#{assignment_points} pts"
    end

    it 'reflects the new assignment in the Assignment Show page', priority: '1', test_id: 210083 do
      assignment = assignment_group.reload.assignments.last
      # Navigates to Assignment Show page.
      get "/courses/#{@course.id}/assignments/#{assignment.id}"
      wait_for_ajaximations

      expect(f(".title").text).to match assignment_name.to_s
      expect(f(".points_possible").text).to match assignment_points.to_s
      expect(f(".assignment_dates").text).to match current_time.to_s
    end
  end

  it "should allow quick-adding two assignments to a group (dealing with form re-render)", priority: "2", test_id: 210084 do
    @course.require_assignment_group
    ag = @course.assignment_groups.first

    get "/courses/#{@course.id}/assignments"
    wait_for_ajaximations

    f("#assignment_group_#{ag.id} .add_assignment").click
    wait_for_ajaximations

    replace_content(f("#ag_#{ag.id}_assignment_name"), "Do this")
    replace_content(f("#ag_#{ag.id}_assignment_points"), "13")
    fj('.create_assignment:visible').click
    wait_for_ajaximations

    f("#assignment_group_#{ag.id} .add_assignment").click
    expect(f("#ag_#{ag.id}_assignment_name")).to be_displayed
  end

  it "should correctly add group weights", priority: "2", test_id: 237014 do
    @course.update_attribute(:group_weighting_scheme, 'percent')
    ag1 = @course.assignment_groups.create!(name: 'Group 1')
    ag2 = @course.assignment_groups.create!(name: 'Group 2')

    get "/courses/#{@course.id}/assignments"

    # setting weight for group 1
    f("#ag_#{ag1.id}_manage_link").click
    fj(".edit_group:visible:first").click

    fj('input[name="group_weight"]:visible').send_keys('50')

    fj('.create_group:visible').click
    wait_for_ajaximations

    # setting weight for group 2
    f("#ag_#{ag2.id}_manage_link").click
    fj(".edit_group:visible:first").click

    fj('input[name="group_weight"]:visible').send_keys('40')

    fj('.create_group:visible').click
    wait_for_ajaximations

    # validations
    expect(f("#assignment_group_#{ag1.id} .ag-header-controls")).to include_text('50% of Total')
    expect(f("#assignment_group_#{ag2.id} .ag-header-controls")).to include_text('40% of Total')

    f("#course_assignment_settings_link").click
    f("#assignmentSettingsCog").click
    wait_for_ajaximations
    # assignment settings Total should == 90%
    expect(f("#percent_total").text).to match '90%'
  end

  context "frozen assignment group" do
    before do
      stub_freezer_plugin
      default_group = @course.assignment_groups.create!(name: "default")
      @frozen_assign = frozen_assignment(default_group)
    end

    it "should not allow assignment group to be deleted by teacher if assignment group id frozen", priority: "2", test_id: 210085 do
      get "/courses/#{@course.id}/assignments"
      expect(f("#content")).not_to contain_css("#group_#{@frozen_assign.assignment_group_id} .delete_group_link")
      expect(f("#content")).not_to contain_css("#assignment_#{@frozen_assign.id} .delete_assignment_link")
    end

    it "should not be locked for admin", priority: "2", test_id: 210086 do
      @course.assignment_groups.create!(name: "other")
      course_with_admin_logged_in(course: @course, name: "admin user")
      orig_title = @frozen_assign.title

      run_assignment_edit(@frozen_assign) do
        # title isn't locked, should allow editing
        f('#assignment_name').send_keys('edit')

        expect(f('#assignment_group_id')).not_to be_disabled
        expect(f('#assignment_peer_reviews')).not_to be_disabled
        expect(f('#assignment_description')).not_to be_disabled
        click_option('#assignment_group_id', "other")
      end

      expect(f('h1.title')).to include_text(orig_title + 'edit')
      expect(@frozen_assign.reload.assignment_group.name).to eq "other"
    end
  end

  it "Should be able to delete assignments when deleting assignment Groups", priority: "2", test_id: 56007 do
    group0 = @course.assignment_groups.create!(name: "Guybrush Group")
    assignment = @course.assignments.create!(title: "Fine Leather Jacket", assignment_group: group0,)
    get "/courses/#{@course.id}/assignments"
    expect(f('#ag-list')).to include_text(assignment.name)

    f("#ag_#{group0.id}_manage_link").click

    f("#assignment_group_#{group0.id} .delete_group").click
    wait_for_ajaximations
    fj('.delete_group:visible').click
    wait_for_ajaximations
    expect(f('#ag-list')).not_to include_text(assignment.name)
  end
end
