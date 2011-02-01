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

describe AssignmentsApiController, :type => :controller do
  it "should sort the returned list of assignments" do
    # the API returns the assignments sorted by
    # [assignment_groups.position, assignments.position]
    course_with_teacher_logged_in(:active_all => true)
    group1 = @course.assignment_groups.create!(:name => 'group1')
    group1.update_attribute(:position, 10)
    group2 = @course.assignment_groups.create!(:name => 'group2')
    group2.update_attribute(:position, 7)
    group3 = @course.assignment_groups.create!(:name => 'group3')
    group3.update_attribute(:position, 12)

    @course.assignments.create!(:title => 'assignment1', :assignment_group => group2).update_attribute(:position, 2)
    @course.assignments.create!(:title => 'assignment2', :assignment_group => group2).update_attribute(:position, 1)
    @course.assignments.create!(:title => 'assignment3', :assignment_group => group1).update_attribute(:position, 1)
    @course.assignments.create!(:title => 'assignment4', :assignment_group => group3).update_attribute(:position, 3)
    @course.assignments.create!(:title => 'assignment5', :assignment_group => group1).update_attribute(:position, 2)
    @course.assignments.create!(:title => 'assignment6', :assignment_group => group2).update_attribute(:position, 3)
    @course.assignments.create!(:title => 'assignment7', :assignment_group => group3).update_attribute(:position, 2)
    @course.assignments.create!(:title => 'assignment8', :assignment_group => group3).update_attribute(:position, 1)

    json = api_call(:get,
          "/api/v1/courses/#{@course.id}/assignments.json",
          { :controller => 'assignments_api', :action => 'index',
            :format => 'json', :course_id => @course.id.to_s })

    order = json.map { |a| a['name'] }
    order.should == %w(assignment2 assignment1 assignment6 assignment3 assignment5 assignment8 assignment7 assignment4)
  end

  it "should return the assignments list with API-formatted Rubric data" do
    # the API changes the structure of the data quite a bit, to hide
    # implementation details and ease API use.
    course_with_teacher_logged_in(:active_all => true)
    @group = @course.assignment_groups.create!({:name => "some group"})
    @assignment = @course.assignments.create!(:title => "some assignment", :assignment_group => @group, :points_possible => 12)
    @assignment.update_attribute(:submission_types, "online_upload,online_text_entry,online_url,media_recording")

    @rubric = rubric_model(:user => @user, :context => @course,
                                     :data => larger_rubric_data,
                          :free_form_criterion_comments => true)

    @assignment.create_rubric_association(:rubric => @rubric, :purpose => 'grading', :use_for_grading => true)

    json = api_call(:get,
          "/api/v1/courses/#{@course.id}/assignments.json",
          { :controller => 'assignments_api', :action => 'index',
            :format => 'json', :course_id => @course.id.to_s })

    json.should == [
      {
        'id' => @assignment.id,
        'name' => 'some assignment',
        'position' => 1,
        'points_possible' => 12,
        'grading_type' => 'points',
        'use_rubric_for_grading' => true,
        'free_form_criterion_comments' => true,
        'submission_types' => [
          "online_upload",
          "online_text_entry",
          "online_url",
          "media_recording"
        ],
        'rubric' => [
          {'id' => 'crit1', 'points' => 10, 'description' => 'Crit1',
            'ratings' => [
              {'id' => 'rat1', 'points' => 10, 'description' => 'A'},
              {'id' => 'rat2', 'points' => 7, 'description' => 'B'},
              {'id' => 'rat3', 'points' => 0, 'description' => 'F'},
            ],
          },
          {'id' => 'crit2', 'points' => 2, 'description' => 'Crit2',
            'ratings' => [
              {'id' => 'rat1', 'points' => 2, 'description' => 'Pass'},
              {'id' => 'rat2', 'points' => 0, 'description' => 'Fail'},
            ],
          },
        ],
      },
    ]
  end

  it "should allow creating an assignment via the API" do
    course_with_teacher_logged_in(:active_all => true)
    @group = @course.assignment_groups.create!({:name => "some group"})

    # make sure we can assign a custom field during creation
    CustomField.create!(:name => 'test_custom',
                        :field_type => 'boolean',
                        :default_value => false,
                        :target_type => 'assignments')

    json = api_call(:post,
          "/api/v1/courses/#{@course.id}/assignments.json",
          { :controller => 'assignments_api', :action => 'create',
            :format => 'json', :course_id => @course.id.to_s },
          { :assignment => { 'name' => 'some assignment',
              'position' => '1', 'points_possible' => '12',
              'grading_type' => 'points', 'set_custom_field_values' => { 'test_custom' => { 'value' => '1' } } } })

    json.should == {
      'id' => Assignment.first.id,
      'name' => 'some assignment',
      'position' => 1,
      'points_possible' => 12,
      'grading_type' => 'points',
      'submission_types' => [
        'none',
      ],
    }

    Assignment.count.should == 1
    a = Assignment.first
    a.get_custom_field_value('test_custom').true?.should == true
  end

  it "should allow updating an assignment via the API" do
    course_with_teacher_logged_in(:active_all => true)
    @group = @course.assignment_groups.create!({:name => "some group"})
    @assignment = @course.assignments.create!(:title => "some assignment", :points_possible => 12)

    # make sure we can assign a custom field during update
    CustomField.create!(:name => 'test_custom',
                        :field_type => 'boolean',
                        :default_value => false,
                        :target_type => 'assignments')

    json = api_call(:put,
          "/api/v1/courses/#{@course.id}/assignments/#{@assignment.id}.json",
          { :controller => 'assignments_api', :action => 'update',
            :format => 'json', :course_id => @course.id.to_s, :id => @assignment.id.to_s },
          { :assignment => { 'name' => 'some assignment again',
              'points_possible' => '15',
              'set_custom_field_values' => { 'test_custom' => { 'value' => '1' } } } })

    json.should == {
      'id' => @assignment.id,
      'name' => 'some assignment again',
      'position' => 1,
      'points_possible' => 15,
      'grading_type' => 'points',
      'submission_types' => [
        'none',
      ],
    }

    Assignment.count.should == 1
    a = Assignment.first
    a.get_custom_field_value('test_custom').true?.should == true
  end

  it "should return the discussion topic url" do
    course_with_teacher_logged_in(:active_all => true)
    @context = @course
    @assignment = factory_with_protected_attributes(@course.assignments, {:title => 'assignment1', :submission_types => 'discussion_topic', :discussion_topic => discussion_topic_model})

    json = api_call(:get,
          "/api/v1/courses/#{@course.id}/assignments/#{@assignment.id}.json",
          { :controller => 'assignments_api', :action => 'show',
            :format => 'json', :course_id => @course.id.to_s,
            :id => @assignment.id.to_s, })
    json['discussion_topic']['id'].should == @topic.id
    json['discussion_topic']['url'].should == "http://test.host/courses/#{@course.id}/discussion_topics/#{@topic.id}"
  end
end
