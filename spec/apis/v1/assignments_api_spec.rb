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

describe AssignmentsApiController, :type => :integration do
  context "index" do

    it "should sort the returned list of assignments" do
      # the API returns the assignments sorted by
      # [assignment_groups.position, assignments.position]
      course_with_teacher(:active_all => true)
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
      course_with_teacher(:active_all => true)
      @group = @course.assignment_groups.create!({:name => "some group"})
      @assignment = @course.assignments.create!(:title => "some assignment", :assignment_group => @group, :points_possible => 12)
      @assignment.update_attribute(:submission_types, "online_upload,online_text_entry,online_url,media_recording")

      @rubric = rubric_model(:user => @user, :context => @course,
                                       :data => larger_rubric_data, :points_possible => 12,
                            :free_form_criterion_comments => true)

      @assignment.create_rubric_association(:rubric => @rubric, :purpose => 'grading', :use_for_grading => true)

      json = api_call(:get,
            "/api/v1/courses/#{@course.id}/assignments.json",
            { :controller => 'assignments_api', :action => 'index',
              :format => 'json', :course_id => @course.id.to_s })

      json.should == [
        {
          'id' => @assignment.id,
          'assignment_group_id' => @assignment.assignment_group_id,
          'name' => 'some assignment',
          'course_id' => @course.id,
          'description' => nil,
          'position' => 1,
          'points_possible' => 12,
          'grading_type' => 'points',
          'muted' => false,
          'use_rubric_for_grading' => true,
          'free_form_criterion_comments' => true,
          'needs_grading_count' => 0,
          'due_at' => nil,
          'submission_types' => [
            "online_upload",
            "online_text_entry",
            "online_url",
            "media_recording"
          ],
          'html_url' => course_assignment_url(@course, @assignment),
          'rubric_settings' => {
            'points_possible' => 12,
            'free_form_criterion_comments' => true,
          },
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
          "group_category_id" => nil
        },
      ]
    end

    it "should exclude deleted assignments in the list return" do
      course_with_teacher(:active_all => true)
      @context = @course
      @assignment = factory_with_protected_attributes(@course.assignments, {:title => 'assignment1', :submission_types => 'discussion_topic', :discussion_topic => discussion_topic_model})
      @assignment.reload
      @assignment.destroy

      json = api_call(:get,
            "/api/v1/courses/#{@course.id}/assignments.json",
            { :controller => 'assignments_api', :action => 'index',
              :format => 'json', :course_id => @course.id.to_s })

      json.size.should == 0
    end
  end

  it "should allow creating an assignment via the API" do
    course_with_teacher(:active_all => true)
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
              'due_at' => '2011-01-01',
              'description' => 'assignment description',
              'grading_type' => 'points', 'set_custom_field_values' => { 'test_custom' => { 'value' => '1' } } } })

    assignment = Assignment.first
    json.should == {
      'id' => assignment.id,
      'assignment_group_id' => assignment.assignment_group_id,
      'name' => 'some assignment',
      'course_id' => @course.id,
      'description' => 'assignment description',
      'muted' => false,
      'position' => 1,
      'points_possible' => 12,
      'grading_type' => 'points',
      'needs_grading_count' => 0,
      'due_at' => '2011-01-01T23:59:00Z',
      'submission_types' => [
        'none',
      ],
      'group_category_id' => nil,
      'html_url' => course_assignment_url(@course, assignment),
    }

    Assignment.count.should == 1
    a = Assignment.first
    a.get_custom_field_value('test_custom').true?.should == true
  end

  it "should allow updating an assignment via the API" do
    course_with_teacher(:active_all => true)
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
      'assignment_group_id' => @assignment.assignment_group_id,
      'name' => 'some assignment again',
      'course_id' => @course.id,
      'description' => nil,
      'muted' => false,
      'position' => 1,
      'points_possible' => 15,
      'grading_type' => 'points',
      'needs_grading_count' => 0,
      'due_at' => nil,
      'submission_types' => [
        'none',
      ],
      'group_category_id' => nil,
      'html_url' => course_assignment_url(@course, @assignment),
    }

    Assignment.count.should == 1
    a = Assignment.first
    a.get_custom_field_value('test_custom').true?.should == true
  end

  it "should not allow updating an assignment via the API if it is locked" do
    course_with_teacher(:active_all => true)
    @group = @course.assignment_groups.create!({:name => "some group"})
    PluginSetting.stubs(:settings_for_plugin).returns({"title" => "yes"}) #enable plugin
    @assignment = @course.assignments.create!(:title => "some assignment", :freeze_on_copy => true)
    @assignment.copied = true
    @assignment.save!

    raw_api_call(:put,
          "/api/v1/courses/#{@course.id}/assignments/#{@assignment.id}.json",
          { :controller => 'assignments_api', :action => 'update',
            :format => 'json', :course_id => @course.id.to_s, :id => @assignment.id.to_s },
          { :assignment => { 'name' => 'new name'}})

    response.code.should eql '400'
    json = JSON.parse(response.body)

    json.should == {
      'message' => 'You cannot edit a frozen assignment.'
    }

    a = @course.assignments.first
    a.title.should == "some assignment"
  end

  it "should return the discussion topic url" do
    course_with_teacher(:active_all => true)
    @context = @course
    @assignment = factory_with_protected_attributes(@course.assignments, {:title => 'assignment1', :submission_types => 'discussion_topic', :discussion_topic => discussion_topic_model})

    json = api_call(:get,
          "/api/v1/courses/#{@course.id}/assignments/#{@assignment.id}.json",
          { :controller => 'assignments_api', :action => 'show',
            :format => 'json', :course_id => @course.id.to_s,
            :id => @assignment.id.to_s, })
    json['discussion_topic'].should == {
      'id' => @topic.id,
      'title' => 'assignment1',
      'message' => nil,
      'posted_at' => @topic.posted_at.as_json,
      'last_reply_at' => @topic.last_reply_at.as_json,
      'require_initial_post' => nil,
      'discussion_subentry_count' => 0,
      'assignment_id' => @assignment.id,
      'delayed_post_at' => nil,
      'user_name' => @topic.user_name,
      'topic_children' => [],
      'root_topic_id' => @topic.root_topic_id,
      'podcast_url' => nil,
      'read_state' => 'unread',
      'unread_count' => 0,
      'url' => "http://www.example.com/courses/#{@course.id}/discussion_topics/#{@topic.id}",
      'html_url' => "http://www.example.com/courses/#{@course.id}/discussion_topics/#{@topic.id}",
      'attachments' => [],
      'permissions' => { 'attach' => true },
      'discussion_type' => 'side_comment',
    }
  end

  it "should return the mute status of the assignment" do
    course_with_teacher(:active_all => true)
    @context = @course
    @assignment = @course.assignments.create! :title => "Test Assignment"
    
    json = api_call(:get,
      "/api/v1/courses/#{@course.id}/assignments/#{@assignment.id}.json",
      { :controller => "assignments_api", :action => "show",
        :format => "json", :course_id => @course.id.to_s,
        :id => @assignment.id.to_s })
    json["muted"].should eql false
  end

  it "should not return the assignment description if locked for user" do
    course_with_student(:active_all => true)
    @assignment1 = @course.assignments.create! :title => "Test Assignment", :description => "public stuff"
    @assignment2 = @course.assignments.create! :title => "Locked Assignment", :description => "secret stuff"
    @assignment2.any_instantiation.expects(:locked_for?).returns(true)

    json = api_call(:get,
          "/api/v1/courses/#{@course.id}/assignments.json",
          { :controller => 'assignments_api', :action => 'index',
            :format => 'json', :course_id => @course.id.to_s })
    json.size.should == 2
    json.find { |e| e['name'] == "Test Assignment" }['description'].should == "public stuff"
    json.find { |e| e['name'] == "Locked Assignment" }['description'].should be_nil
  end
end
