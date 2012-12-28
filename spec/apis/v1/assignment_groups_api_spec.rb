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

describe AssignmentGroupsController, :type => :integration do
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
        'group_weight' => nil
      },
      {
        'id' => group1.id,
        'name' => 'group1',
        'position' => 10,
        'rules' => {},
        'group_weight' => nil
      },
      {
        'id' => group3.id,
        'name' => 'group3',
        'position' => 12,
        'rules' => {},
        'group_weight' => nil
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
    a4.reload

    @course.update_attribute(:group_weighting_scheme, 'percent')

    json = api_call(:get,
          "/api/v1/courses/#{@course.id}/assignment_groups.json?include[]=assignments",
          { :controller => 'assignment_groups', :action => 'index',
            :format => 'json', :course_id => @course.id.to_s,
            :include => ['assignments'] })

    json.should == [
      {
        'id' => group2.id,
        'name' => 'group2',
        'position' => 7,
        'rules' => {},
        'group_weight' => 60,
        'assignments' => [
          {
            'id' => a3.id,
            'assignment_group_id' => group2.id,
            'course_id' => @course.id,
            'due_at' => nil,
            'muted' => false,
            'name' => 'test3',
            'description' => nil,
            'position' => 1,
            'points_possible' => 12,
            'needs_grading_count' => 0,
            "submission_types" => [
              "none",
            ],
            'grading_type' => 'points',
            'use_rubric_for_grading' => true,
            'free_form_criterion_comments' => false,
            'html_url' => course_assignment_url(@course, a3),
            'rubric_settings' => {
              'points_possible' => 12,
              'free_form_criterion_comments' => false,
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
            'group_category_id' => nil
          },
          {
            'id' => a4.id,
            'assignment_group_id' => group2.id,
            'course_id' => @course.id,
            'due_at' => nil,
            'muted' => false,
            'name' => 'test4',
            'description' => nil,
            'position' => 2,
            'points_possible' => 9,
            'needs_grading_count' => 0,
            'submission_types' => ["discussion_topic"],
            'discussion_topic' => {
              "assignment_id" => a4.id,
              "delayed_post_at" => nil,
              "id" => a4.discussion_topic.id,
              "last_reply_at" => a4.discussion_topic.last_reply_at.iso8601,
              "podcast_has_student_posts" => nil,
              "posted_at" => a4.discussion_topic.posted_at.iso8601,
              "root_topic_id" => nil,
              "title" => "test4",
              "user_name" => nil,
              "discussion_subentry_count" => 0,
              "permissions" => {"attach" => true, "update" => true, "delete" => true},
              "message" => nil,
              "discussion_type" => "side_comment",
              "require_initial_post" => nil,
              "podcast_url" => nil,
              "read_state" => "unread",
              "unread_count" => 0,
              "topic_children" => [],
              "attachments" => [],
              "locked" => false,
              "author" => {},
              "html_url" => course_discussion_topic_url(@course, a4.discussion_topic),
              "url" => course_discussion_topic_url(@course, a4.discussion_topic)
            },
            'grading_type' => 'points',
            'group_category_id' => nil,
            'html_url' => course_assignment_url(@course, a4),
          },
        ],
      },
      {
        'id' => group1.id,
        'name' => 'group1',
        'position' => 10,
        'rules' => {},
        'group_weight' => 40,
        'assignments' => [
          {
            'id' => a1.id,
            'assignment_group_id' => group1.id,
            'course_id' => @course.id,
            'due_at' => nil,
            'muted' => false,
            'name' => 'test1',
            'description' => nil,
            'position' => 1,
            'points_possible' => 10,
            'needs_grading_count' => 0,
            "submission_types" => [
              "none",
            ],
            'grading_type' => 'points',
            'group_category_id' => nil,
            'html_url' => course_assignment_url(@course, a1),
          },
          {
            'id' => a2.id,
            'assignment_group_id' => group1.id,
            'course_id' => @course.id,
            'due_at' => nil,
            'muted' => false,
            'name' => 'test2',
            'description' => nil,
            'position' => 2,
            'points_possible' => 12,
            'needs_grading_count' => 0,
            "submission_types" => [
              "none",
            ],
            'grading_type' => 'points',
            'group_category_id' => nil,
            'html_url' => course_assignment_url(@course, a2),
          },
        ],
      },
    ]
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

  it "should not return weights that aren't being applied" do
    course_with_teacher(:active_all => true)
    @course.update_attribute(:group_weighting_scheme, 'equal')

    group1 = @course.assignment_groups.create!(:name => 'group1', :group_weight => 50)
    group2 = @course.assignment_groups.create!(:name => 'group2', :group_weight => 50)

    json = api_call(:get, "/api/v1/courses/#{@course.id}/assignment_groups",
                    { :controller => 'assignment_groups', :action => 'index',
                      :format => 'json', :course_id => @course.to_param })

    json.each { |group| group['group_weight'].should be_nil }
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
end
