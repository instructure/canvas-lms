#
# Copyright (C) 2011 Instructure, Inc.
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
#

require File.expand_path(File.dirname(__FILE__) + '/../api_spec_helper')

def set_up_groups
  @group1 = @course.assignment_groups.create!(:name => 'group1')
  @group1.update_attribute(:position, 10)
  @group1.update_attribute(:group_weight, 40)
  @group2 = @course.assignment_groups.create!(:name => 'group2')
  @group2.update_attribute(:position, 7)
  @group2.update_attribute(:group_weight, 60)
end

def set_up_four_assignments(assignment_opts = {})
  @a1 = @course.assignments.create!({:title => "test1", :assignment_group => @group1, :points_possible => 10, :description => 'Assignment 1'}.merge(assignment_opts))
  @a2 = @course.assignments.create!({:title => "test2", :assignment_group => @group1, :points_possible => 12, :description => 'Assignment 2'}.merge(assignment_opts))
  @a3 = @course.assignments.create!({:title => "test3", :assignment_group => @group2, :points_possible => 8, :description => 'Assignment 3'}.merge(assignment_opts))
  @a4 = @course.assignments.create!({:title => "test4", :assignment_group => @group2, :points_possible => 9, :description => 'Assignment 4'}.merge(assignment_opts))
end

def set_up_multiple_grading_periods
  @course.account.enable_feature!(:multiple_grading_periods)
  set_up_groups
  @group1_assignment_today = @course.assignments.create!(:assignment_group => @group1, :due_at => Time.now)
  @group1_assignment_future = @course.assignments.create!(:assignment_group => @group1, :due_at => 3.months.from_now)
  @group2_assignment_today = @course.assignments.create!(:assignment_group => @group2, :due_at => Time.now)
  gpg = @course.grading_period_groups.create!
  @gp_current = gpg.grading_periods.create!(workflow_state: "active", weight: 50, start_date: 1.month.ago, end_date: 1.month.from_now)
  @gp_future = gpg.grading_periods.create!(workflow_state: "active", weight: 50, start_date: 2.months.from_now, end_date: 4.months.from_now)
end

describe AssignmentGroupsController, type: :request do
  include Api
  include Api::V1::Assignment

  before :once do
    course_with_teacher(:active_all => true)
  end

  it "should sort the returned list of assignment groups" do
    # the API returns the assignments sorted by
    # assignment_groups.position
    group1 = @course.assignment_groups.create!(:name => 'group1')
    group1.update_attribute(:position, 10)
    group2 = @course.assignment_groups.create!(:name => 'group2')
    group2.update_attribute(:position, 7)
    group3 = @course.assignment_groups.create!(:name => 'group3')
    group3.update_attribute(:position, 12)

    json = api_call(:get,
          "/api/v1/courses/#{@course.id}/assignment_groups.json",
          { :controller => 'assignment_groups', :action => 'index',
            :format => 'json', :course_id => @course.id.to_s })

    expect(json).to eq [
      {
        'id' => group2.id,
        'name' => 'group2',
        'position' => 7,
        'rules' => {},
        'group_weight' => 0
      },
      {
        'id' => group1.id,
        'name' => 'group1',
        'position' => 10,
        'rules' => {},
        'group_weight' => 0
      },
      {
        'id' => group3.id,
        'name' => 'group3',
        'position' => 12,
        'rules' => {},
        'group_weight' => 0
      }
    ]
  end

  it "should include full assignment jsonification when specified" do
    set_up_groups
    set_up_four_assignments

    rubric_model(:user => @user, :context => @course, :points_possible => 12,
                                     :data => larger_rubric_data)

    @a3.create_rubric_association(:rubric => @rubric, :purpose => 'grading', :use_for_grading => true)

    @a4.submission_types = 'discussion_topic'
    @a4.save!
    [@a1, @a2, @a3, @a4].each(&:reload)

    @course.update_attribute(:group_weighting_scheme, 'percent')

    json = api_call(:get,
          "/api/v1/courses/#{@course.id}/assignment_groups.json?include[]=assignments",
          { :controller => 'assignment_groups', :action => 'index',
            :format => 'json', :course_id => @course.id.to_s,
            :include => ['assignments'] })

    expected = [
      {
        'group_weight' => 60,
        'id' => @group2.id,
        'name' => 'group2',
        'position' => 7,
        'rules' => {},
        'assignments' => [
          controller.assignment_json(@a3,@user,session),
          controller.assignment_json(@a4,@user,session, include_discussion_topic: true)
        ],
      },
      {
        'group_weight' => 40,
        'id' => @group1.id,
        'name' => 'group1',
        'position' => 10,
        'rules' => {},
        'assignments' => [
          controller.assignment_json(@a1,@user,session),
          controller.assignment_json(@a2,@user,session)
        ],
      }
    ]

    json.each do |group|
      group["assignments"].each do |assignment|
        expect(assignment).to have_key "description"
      end
    end

    compare_json(json, expected)
  end

  context "excluded descriptions" do
    it "excludes the descriptions of assignments if the excluded_descriptions param is passed" do
      set_up_groups
      set_up_four_assignments

      json = api_call(:get,
                      "/api/v1/courses/#{@course.id}/assignment_groups.json?include[]=assignments&exclude_descriptions=1",
                      { controller: 'assignment_groups', action: 'index',
                        format: 'json', course_id: @course.id.to_s,
                        include: ['assignments'],
                        exclude_descriptions: 1
      })

      json.each do |group|
        group["assignments"].each { |a| expect(a).to_not have_key "description" }
      end
    end
  end

  context "differentiated assignments" do
    it "should only return visible assignments when differentiated assignments is on" do
      set_up_groups
      set_up_four_assignments(only_visible_to_overrides: true)
      @user.enrollments.each(&:delete)
      @section = @course.course_sections.create!(name: "test section")
      student_in_section(@section, user: @user)
      # make a1 and a3 visible
      create_section_override_for_assignment(@a1, course_section: @section)
      @a3.grade_student(@user, {grade: 10})

      [@a1, @a2, @a3, @a4].each(&:reload)

      @course.enable_feature!(:differentiated_assignments)

      json = api_call(:get,
          "/api/v1/courses/#{@course.id}/assignment_groups.json?include[]=assignments",
          { :controller => 'assignment_groups', :action => 'index',
            :format => 'json', :course_id => @course.id.to_s,
            :include => ['assignments'] })

      json.each do |ag_json|
        expect(ag_json["assignments"].length).to eq 1
      end

      @course.disable_feature!(:differentiated_assignments)

      json = api_call(:get,
          "/api/v1/courses/#{@course.id}/assignment_groups.json?include[]=assignments",
          { :controller => 'assignment_groups', :action => 'index',
            :format => 'json', :course_id => @course.id.to_s,
            :include => ['assignments'] })

      json.each do |ag_json|
        expect(ag_json["assignments"].length).to eq 2
      end
    end

    it "should allow designers to see unpublished assignments" do
      set_up_groups
      set_up_four_assignments(only_visible_to_overrides: true)
      course_with_designer(course: @course)
      [@a1,@a3].each(&:unpublish)
      [:enable_feature!, :disable_feature!].each do |feature_toggle|
        @course.send(feature_toggle, :differentiated_assignments)
        json = api_call_as_user(@designer, :get,
            "/api/v1/courses/#{@course.id}/assignment_groups.json?include[]=assignments",
            { :controller => 'assignment_groups', :action => 'index',
              :format => 'json', :course_id => @course.id.to_s,
              :include => ['assignments'] })

        json.each do |ag_json|
          expect(ag_json["assignments"].length).to eq 2
        end
      end
    end

    it "should include assignment_visibility when requested" do
      @course.assignments.create!
      @course.enable_feature!(:differentiated_assignments)
      json = api_call(:get,
        "/api/v1/courses/#{@course.id}/assignment_groups.json",
        {
          :controller => 'assignment_groups', :action => 'index',
          :format => 'json', :course_id => @course.id.to_s
        },
        :include => ['assignments', 'assignment_visibility']
      )
      json.each do |ag|
        ag["assignments"].each do |a|
          expect(a.has_key?("assignment_visibility")).to eq true
        end
      end
    end
  end

  context "multiple grading periods" do
    before :once do
      set_up_multiple_grading_periods

      @api_settings = { :controller => 'assignment_groups',
                        :action => 'index',
                        :format => 'json',
                        :course_id => @course.id.to_s,
                        :grading_period_id => @gp_future.id.to_s,
                        :include => ['assignments'] }
      @api_path = "/api/v1/courses/#{@course.id}/assignment_groups?include[]=assignments&grading_period_id=#{@gp_future.id}"
    end

    it "should only return assignments within the grading period" do
      json = api_call(:get, @api_path, @api_settings)
      expect(json[1]['assignments'].length).to eq 1
    end

    it "should not return assignments outside the grading period" do
      json = api_call(:get, @api_path, @api_settings)
      expect(json[0]['assignments'].length).to eq 0
    end
  end

  it "should include module_ids when requested" do
    mods = 2.times.map { |i| @course.context_modules.create! name: "Mod#{i}" }
    g = @course.assignment_groups.create! name: 'assignments'
    a = @course.assignments.create! assignment_group: g, title: "blah"
    mods.each { |m| m.add_item type: "assignment", id: a.id }

    json = api_call(:get,
          "/api/v1/courses/#{@course.id}/assignment_groups.json?include[]=assignments&include[]=module_ids",
          { :controller => 'assignment_groups', :action => 'index',
            :format => 'json', :course_id => @course.id.to_s,
            :include => %w[assignments module_ids]})
    assignment_json = json.first["assignments"].first
    expect(assignment_json["module_ids"].sort).to eq mods.map(&:id).sort
  end

  it "should not include all dates " do
    group = @course.assignment_groups.build(:name => 'group1')
    group.position = 10
    group.group_weight = 40
    group.save!

    a1 = @course.assignments.create!(:title => "test1", :assignment_group => group, :points_possible => 10)
    a2 = @course.assignments.create!(:title => "test2", :assignment_group => group, :points_possible => 12)

    a1.assignment_overrides.create! do |override|
      override.set = @course.course_sections.first
      override.title = "All"
      override.due_at = 1.day.ago
      override.due_at_overridden = true
    end

    # catch updated timestamps
    a1.reload
    a2.reload

    json = api_call(:get,
          "/api/v1/courses/#{@course.id}/assignment_groups.json?include[]=assignments",
          { :controller => 'assignment_groups', :action => 'index',
            :format => 'json', :course_id => @course.id.to_s,
            :include => ['assignments'] })

    expected = [
      {
        'group_weight' => 40,
        'id' => group.id,
        'name' => 'group1',
        'position' => 10,
        'rules' => {},
        'assignments' => [
          controller.assignment_json(a1, @user,session),
          controller.assignment_json(a2, @user,session)
        ],
      }
    ]

    compare_json(json, expected)
  end

  it "should include all dates" do
    group = @course.assignment_groups.build(:name => 'group1')
    group.position = 10
    group.group_weight = 40
    group.save!

    a1 = @course.assignments.create!(:title => "test1", :assignment_group => group, :points_possible => 10)
    a2 = @course.assignments.create!(:title => "test2", :assignment_group => group, :points_possible => 12)

    a1.assignment_overrides.create! do |override|
      override.set = @course.course_sections.first
      override.title = "All"
      override.due_at = 1.day.ago
      override.due_at_overridden = true
    end
    a1.reload

    json = api_call(:get,
          "/api/v1/courses/#{@course.id}/assignment_groups.json?include[]=assignments&include[]=all_dates",
          { :controller => 'assignment_groups', :action => 'index',
            :format => 'json', :course_id => @course.id.to_s,
            :include => ['assignments', 'all_dates'] })

    expected = [
      {
        'group_weight' => 40,
        'id' => group.id,
        'name' => 'group1',
        'position' => 10,
        'rules' => {},
        'assignments' => [
          controller.assignment_json(a1, @user,session, :include_all_dates => true),
          controller.assignment_json(a2, @user,session, :include_all_dates => true)
        ],
      }
    ]

    compare_json(json, expected)
  end

  it "should exclude deleted assignments" do
    group1 = @course.assignment_groups.create!(:name => 'group1')
    group1.update_attribute(:position, 10)

    a1 = @course.assignments.create!(:title => "test1", :assignment_group => group1, :points_possible => 10)
    a2 = @course.assignments.create!(:title => "test2", :assignment_group => group1, :points_possible => 12)
    a2.reload
    a2.destroy

    json = api_call(:get,
          "/api/v1/courses/#{@course.id}/assignment_groups.json?include[]=assignments",
          { :controller => 'assignment_groups', :action => 'index',
            :format => 'json', :course_id => @course.id.to_s,
            :include => ['assignments'] })

    group = json.first
    expect(group).to be_present
    expect(group['assignments'].size).to eq 1
    expect(group['assignments'].first['name']).to eq 'test1'
  end

  it "should return weights that aren't being applied" do
    @course.update_attribute(:group_weighting_scheme, 'equal')

    group1 = @course.assignment_groups.create!(:name => 'group1', :group_weight => 50)
    group2 = @course.assignment_groups.create!(:name => 'group2', :group_weight => 50)

    json = api_call(:get, "/api/v1/courses/#{@course.id}/assignment_groups",
                    { :controller => 'assignment_groups', :action => 'index',
                      :format => 'json', :course_id => @course.to_param })

    json.each { |group| expect(group['group_weight']).to eq 50 }
  end

  it "should not explode on assignments with <objects> with percentile widths" do
    group = @course.assignment_groups.create!(:name => 'group')
    assignment = @course.assignments.create!(:title => "test", :assignment_group => group, :points_possible => 10)
    assignment.description = '<object width="100%" />'
    assignment.save!

    api_call(:get, "/api/v1/courses/#{@course.id}/assignment_groups.json?include[]=assignments",
             :controller => 'assignment_groups',
             :action => 'index',
             :format => 'json',
             :course_id => @course.id.to_s,
             :include => ['assignments'])
  end

  it "should not return unpublished assignments to students" do
    student_in_course(:active_all => true)
    @course.require_assignment_group
    assignment = @course.assignments.create! do |a|
      a.title = "test"
      a.assignment_group = @course.assignment_groups.first
      a.points_possible = 10
      a.workflow_state = "unpublished"
    end
    expect(assignment).to be_unpublished

    json = api_call(:get, "/api/v1/courses/#{@course.id}/assignment_groups.json?include[]=assignments",
                    :controller => 'assignment_groups',
                    :action => 'index',
                    :format => 'json',
                    :course_id => @course.id.to_s,
                    :include => ['assignments'])
    expect(json.first['assignments']).to be_empty
  end
end


describe AssignmentGroupsApiController, type: :request do
  include Api
  include Api::V1::Assignment

  context '#show' do

    before :once do
      course_with_teacher(:active_all => true)
      rules_in_db = "drop_lowest:1\ndrop_highest:1\nnever_drop:1\nnever_drop:2\n"
      @group = @course.assignment_groups.create!(:name => 'group', :rules => rules_in_db)
    end

    it 'should succeed' do
      api_call(:get, "/api/v1/courses/#{@course.id}/assignment_groups/#{@group.id}",
        :controller => 'assignment_groups_api',
        :action => 'show',
        :format => 'json',
        :course_id => @course.id.to_s,
        :assignment_group_id => @group.id.to_s)
    end

    it 'should fail if the assignment group does not exist' do
      not_exist = @group.id + 100
      raw_api_call(:get, "/api/v1/courses/#{@course.id}/assignment_groups/#{not_exist}",
        :controller => 'assignment_groups_api',
        :action => 'show',
        :format => 'json',
        :course_id => @course.id.to_s,
        :assignment_group_id => not_exist.to_s)
      assert_status(404)
    end

    it 'should include assignments' do
      @course.assignments.create!(:title => "test", :assignment_group => @group, :points_possible => 10)
      json = api_call(:get, "/api/v1/courses/#{@course.id}/assignment_groups/#{@group.id}?include[]=assignments",
        :controller => 'assignment_groups_api',
        :action => 'show',
        :format => 'json',
        :course_id => @course.id.to_s,
        :assignment_group_id => @group.id.to_s,
        :include => ['assignments'])

      expect(json['assignments']).not_to be_empty
    end

    it 'should only return assignments in the given grading period with MGP on' do
      set_up_multiple_grading_periods

      json = api_call(:get, "/api/v1/courses/#{@course.id}/assignment_groups/#{@group1.id}?include[]=assignments&grading_period_id=#{@gp_future.id}",
        :controller => 'assignment_groups_api',
        :action => 'show',
        :format => 'json',
        :course_id => @course.id.to_s,
        :assignment_group_id => @group1.id.to_s,
        :grading_period_id => @gp_future.id.to_s,
        :include => ['assignments'])

      expect(json['assignments'].length).to eq 1
    end

    it 'should not return an error when Multiple Grading Periods is turned on and no grading_period_id is passed in' do
      set_up_multiple_grading_periods

      json = api_call(:get, "/api/v1/courses/#{@course.id}/assignment_groups/#{@group1.id}?include[]=assignments",
        :controller => 'assignment_groups_api',
        :action => 'show',
        :format => 'json',
        :course_id => @course.id.to_s,
        :assignment_group_id => @group1.id.to_s,
        :include => ['assignments'])

      expect(response).to be_ok
    end

    it "should include assignment_visibility when requested and with DA on" do
      @course.enable_feature!(:differentiated_assignments)
      @course.assignments.create!(:title => "test", :assignment_group => @group, :points_possible => 10)
      json = api_call(:get, "/api/v1/courses/#{@course.id}/assignment_groups/#{@group.id}.json",
        {
          :controller => 'assignment_groups_api',
          :action => 'show',
          :format => 'json',
          :course_id => @course.id.to_s,
          :assignment_group_id => @group.id.to_s
        },
        :include => ['assignments', 'assignment_visibility']
      )
      json['assignments'].each do |a|
        expect(a.has_key?("assignment_visibility")).to eq true
      end
    end

    it "should not include assignment_visibility when requested as a student" do
      student_in_course(:active_all => true)
      @course.enable_feature!(:differentiated_assignments)
      @course.assignments.create!(:title => "test", :assignment_group => @group, :points_possible => 10)
      json = api_call(:get, "/api/v1/courses/#{@course.id}/assignment_groups/#{@group.id}.json",
        {
          :controller => 'assignment_groups_api',
          :action => 'show',
          :format => 'json',
          :course_id => @course.id.to_s,
          :assignment_group_id => @group.id.to_s
        },
        :include => ['assignments', 'assignment_visibility']
      )
      json['assignments'].each do |a|
        expect(a.has_key?("assignment_visibility")).to eq false
      end
    end

    it 'should return never_drop rules as strings with Accept header' do
      rules = {'never_drop' => ["1","2"], 'drop_lowest' => 1, 'drop_highest' => 1}
      json = api_call(:get, "/api/v1/courses/#{@course.id}/assignment_groups/#{@group.id}", {
        :controller => 'assignment_groups_api',
        :action => 'show',
        :format => 'json',
        :course_id => @course.id.to_s,
        :assignment_group_id => @group.id.to_s},
        {},
        { 'Accept' => 'application/json+canvas-string-ids' })

      expect(json['rules']).to eq rules
    end

    it 'should return never_drop rules as ints without Accept header' do
      rules = {'never_drop' => [1,2], 'drop_lowest' => 1, 'drop_highest' => 1}
      json = api_call(:get, "/api/v1/courses/#{@course.id}/assignment_groups/#{@group.id}", {
        :controller => 'assignment_groups_api',
        :action => 'show',
        :format => 'json',
        :course_id => @course.id.to_s,
        :assignment_group_id => @group.id.to_s}
        )

      expect(json['rules']).to eq rules
    end

  end
  context '#create' do
    before do
      course_with_teacher(:active_all => true)
    end

    it 'should create an assignment_group' do
      params = {'name' => 'Some group', 'position' => 1}
      expect {
        api_call(:post, "/api/v1/courses/#{@course.id}/assignment_groups", {
          :controller => 'assignment_groups_api',
          :action => 'create',
          :format => 'json',
          :course_id => @course.id.to_s},
          params)
      }.to change(AssignmentGroup, :count).by(1)
    end
  end

  context '#update' do
    before :once do
      course_with_teacher(:active_all => true)
      @assignment_group = @course.assignment_groups.create!(:name => 'Some group', :position => 1)
    end

    it 'should update an assignment group' do
      params = {'name' => 'A different name'}
      json = api_call(:put, "/api/v1/courses/#{@course.id}/assignment_groups/#{@assignment_group.id}", {
        :controller => 'assignment_groups_api',
        :action => 'update',
        :format => 'json',
        :course_id => @course.id.to_s,
        :assignment_group_id => @assignment_group.id.to_s},
        params)

      expect(json['name']).to eq 'A different name'
      @assignment_group.reload
      expect(@assignment_group.name).to eq 'A different name'
    end

    it 'should update rules properly' do
      rules = {'never_drop' => ["1","2"], 'drop_lowest' => 1, 'drop_highest' => 1}
      rules_in_db = "drop_lowest:1\ndrop_highest:1\nnever_drop:1\nnever_drop:2\n"
      params = {'rules' => rules}
      json = api_call(:put, "/api/v1/courses/#{@course.id}/assignment_groups/#{@assignment_group.id}", {
        :controller => 'assignment_groups_api',
        :action => 'update',
        :format => 'json',
        :course_id => @course.id.to_s,
        :assignment_group_id => @assignment_group.id.to_s},
        params,
        { 'Accept' => 'application/json+canvas-string-ids' })

      expect(json['rules']).to eq rules
      @assignment_group.reload
      expect(@assignment_group.rules).to eq rules_in_db
    end
  end

  context '#destroy' do
    before :once do
      course_with_teacher(:active_all => true)
      @assignment_group = @course.assignment_groups.create!(:name => 'Some group', :position => 1)
    end

    it 'should destroy an assignment group' do

      api_call(:delete, "/api/v1/courses/#{@course.id}/assignment_groups/#{@assignment_group.id}",
        :controller => 'assignment_groups_api',
        :action => 'destroy',
        :format => 'json',
        :course_id => @course.id.to_s,
        :assignment_group_id => @assignment_group.id.to_s)

      expect(@assignment_group.reload.workflow_state).to eq 'deleted'
    end

    it 'should destroy assignments' do
      a1 = @course.assignments.create!(:title => "test1", :assignment_group => @assignment_group, :points_possible => 10)
      a2 = @course.assignments.create!(:title => "test2", :assignment_group => @assignment_group, :points_possible => 12)

      api_call(:delete, "/api/v1/courses/#{@course.id}/assignment_groups/#{@assignment_group.id}",
        :controller => 'assignment_groups_api',
        :action => 'destroy',
        :format => 'json',
        :course_id => @course.id.to_s,
        :assignment_group_id => @assignment_group.id.to_s)

      expect(@assignment_group.reload.workflow_state).to eq 'deleted'
      expect(a1.reload.workflow_state).to eq 'deleted'
      expect(a2.reload.workflow_state).to eq 'deleted'
    end

    it 'should move assignments to a specified assignment group' do
      group2 = @course.assignment_groups.create!(:name => 'Another group', :position => 2)
      group3 = @course.assignment_groups.create!(:name => 'Yet Another group', :position => 3)

      a1 = @course.assignments.create!(:title => "test1", :assignment_group => @assignment_group, :points_possible => 10)
      a2 = @course.assignments.create!(:title => "test2", :assignment_group => @assignment_group, :points_possible => 12)
      a3 = @course.assignments.create!(:title => "test3", :assignment_group => @assignment_group, :points_possible => 8)
      a4 = @course.assignments.create!(:title => "test4", :assignment_group => @assignment_group, :points_possible => 9)

      api_call(:delete, "/api/v1/courses/#{@course.id}/assignment_groups/#{@assignment_group.id}", {
        :controller => 'assignment_groups_api',
        :action => 'destroy',
        :format => 'json',
        :course_id => @course.id.to_s,
        :assignment_group_id => @assignment_group.id.to_s},
        {:move_assignments_to => group3.id})

      group3.reload
      expect(group3.assignments.count).to eq 4
      expect(@assignment_group.reload.workflow_state).to eq 'deleted'
    end
  end

end
