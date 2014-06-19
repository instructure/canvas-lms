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

describe AssignmentGroupsController, type: :request do
  include Api
  include Api::V1::Assignment

  it "should sort the returned list of assignment groups" do
    # the API returns the assignments sorted by
    # assignment_groups.position
    course_with_teacher(:active_all => true)
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

    json.should == [
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
    course_with_teacher(:active_all => true)
    group1 = @course.assignment_groups.create!(:name => 'group1')
    group1.update_attribute(:position, 10)
    group1.update_attribute(:group_weight, 40)
    group2 = @course.assignment_groups.create!(:name => 'group2')
    group2.update_attribute(:position, 7)
    group2.update_attribute(:group_weight, 60)

    a1 = @course.assignments.create!(:title => "test1", :assignment_group => group1, :points_possible => 10)
    a2 = @course.assignments.create!(:title => "test2", :assignment_group => group1, :points_possible => 12)
    a3 = @course.assignments.create!(:title => "test3", :assignment_group => group2, :points_possible => 8)
    a4 = @course.assignments.create!(:title => "test4", :assignment_group => group2, :points_possible => 9)

    rubric_model(:user => @user, :context => @course, :points_possible => 12,
                                     :data => larger_rubric_data)

    a3.create_rubric_association(:rubric => @rubric, :purpose => 'grading', :use_for_grading => true)

    a4.submission_types = 'discussion_topic'
    a4.save!
    a1.reload
    a2.reload
    a3.reload
    a4.reload

    @course.update_attribute(:group_weighting_scheme, 'percent')

    json = api_call(:get,
          "/api/v1/courses/#{@course.id}/assignment_groups.json?include[]=assignments",
          { :controller => 'assignment_groups', :action => 'index',
            :format => 'json', :course_id => @course.id.to_s,
            :include => ['assignments'] })

    expected = [
      {
        'group_weight' => 60,
        'id' => group2.id,
        'name' => 'group2',
        'position' => 7,
        'rules' => {},
        'assignments' => [
          controller.assignment_json(a3,@user,session),
          controller.assignment_json(a4,@user,session, include_discussion_topic: true)
        ],
      },
      {
        'group_weight' => 40,
        'id' => group1.id,
        'name' => 'group1',
        'position' => 10,
        'rules' => {},
        'assignments' => [
          controller.assignment_json(a1,@user,session),
          controller.assignment_json(a2,@user,session)
        ],
      }
    ]

    compare_json(json, expected)
  end

  it "should include module_ids when requested" do
    course_with_teacher active_all: true
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
    assignment_json["module_ids"].sort.should == mods.map(&:id).sort
  end

  it "should not include all dates " do
    course_with_teacher(:active_all => true)
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
    course_with_teacher(:active_all => true)
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
    course_with_teacher(:active_all => true)
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
    group.should be_present
    group['assignments'].size.should == 1
    group['assignments'].first['name'].should == 'test1'
  end

  it "should return weights that aren't being applied" do
    course_with_teacher(:active_all => true)
    @course.update_attribute(:group_weighting_scheme, 'equal')

    group1 = @course.assignment_groups.create!(:name => 'group1', :group_weight => 50)
    group2 = @course.assignment_groups.create!(:name => 'group2', :group_weight => 50)

    json = api_call(:get, "/api/v1/courses/#{@course.id}/assignment_groups",
                    { :controller => 'assignment_groups', :action => 'index',
                      :format => 'json', :course_id => @course.to_param })

    json.each { |group| group['group_weight'].should == 50 }
  end

  it "should not explode on assignments with <objects> with percentile widths" do
    course_with_teacher(:active_all => true)
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
    course_with_student(:active_all => true)
    @course.root_account.enable_feature!(:draft_state)
    @course.require_assignment_group
    assignment = @course.assignments.create! do |a|
      a.title = "test"
      a.assignment_group = @course.assignment_groups.first
      a.points_possible = 10
      a.workflow_state = "unpublished"
    end
    assignment.should be_unpublished

    json = api_call(:get, "/api/v1/courses/#{@course.id}/assignment_groups.json?include[]=assignments",
                    :controller => 'assignment_groups',
                    :action => 'index',
                    :format => 'json',
                    :course_id => @course.id.to_s,
                    :include => ['assignments'])
    json.first['assignments'].should be_empty
  end
end


describe AssignmentGroupsApiController, type: :request do
  include Api
  include Api::V1::Assignment

  context '#show' do

    before do
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

      json['assignments'].should_not be_empty
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

      json['rules'].should == rules
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

      json['rules'].should == rules
    end

  end
  context '#create' do
    before do
      course_with_teacher(:active_all => true)
    end

    it 'should create an assignment_group' do
      params = {'name' => 'Some group', 'position' => 1}
      lambda {
        api_call(:post, "/api/v1/courses/#{@course.id}/assignment_groups", {
          :controller => 'assignment_groups_api',
          :action => 'create',
          :format => 'json',
          :course_id => @course.id.to_s},
          params)
      }.should change(AssignmentGroup, :count).by(1)
    end
  end

  context '#update' do
    before do
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

      json['name'].should == 'A different name'
      @assignment_group.reload
      @assignment_group.name.should == 'A different name'
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

      json['rules'].should == rules
      @assignment_group.reload
      @assignment_group.rules.should == rules_in_db
    end
  end

  context '#destroy' do
    before do
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

      @assignment_group.reload.workflow_state.should == 'deleted'
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

      @assignment_group.reload.workflow_state.should == 'deleted'
      a1.reload.workflow_state.should == 'deleted'
      a2.reload.workflow_state.should == 'deleted'
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
      group3.assignments.count.should == 4
      @assignment_group.reload.workflow_state.should == 'deleted'
    end
  end

end
