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
    @course.assignment_groups.create!({:name => "first group"})
    @group = @course.assignment_groups.create!({:name => "some group"})
    @course.assignment_groups.create!({:name => "last group"})


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
              'assignment_group_id' => @group.id,
              'grading_type' => 'points', 'set_custom_field_values' => { 'test_custom' => { 'value' => '1' } } } })

    assignment = Assignment.first
    json.should == {
      'id' => assignment.id,
      'assignment_group_id' => @group.id,
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

  it "should allow creating an assignment with overrides via the API" do
    course_with_teacher(:active_all => true)
    student_in_course(:course => @course, :active_enrollment => true)

    @adhoc_due_at = 5.days.from_now
    @section_due_at = 7.days.from_now

    @user = @teacher
    api_call(:post, "/api/v1/courses/#{@course.id}/assignments.json",
      { :controller => 'assignments_api', :action => 'create', :format => 'json', :course_id => @course.id.to_s },
      { :assignment => {
          'name' => 'some assignment',
          'assignment_overrides' => {
            '0' => { 'student_ids' => [@student.id], 'title' => 'adhoc override', 'due_at' => @adhoc_due_at.iso8601 },
            '1' => { 'course_section_id' => @course.default_section.id, 'due_at' => @section_due_at.iso8601 }}}})

    @assignment = Assignment.first
    @assignment.assignment_overrides.count.should == 2

    @adhoc_override = @assignment.assignment_overrides.find_by_set_type('ADHOC')
    @adhoc_override.should_not be_nil
    @adhoc_override.set.should == [@student]
    @adhoc_override.due_at_overridden.should be_true
    @adhoc_override.due_at.to_i.should == @adhoc_due_at.to_i

    @section_override = @assignment.assignment_overrides.find_by_set_type('CourseSection')
    @section_override.should_not be_nil
    @section_override.set.should == @course.default_section
    @section_override.due_at_overridden.should be_true
    @section_override.due_at.to_i.should == @section_due_at.to_i
  end

  it "should allow updating an assignment via the API" do
    course_with_teacher(:active_all => true)
    @start_group = @course.assignment_groups.create!({:name => "start group"})
    @group = @course.assignment_groups.create!({:name => "new group"})
    @assignment = @course.assignments.create!(:title => "some assignment", :points_possible => 12)
    @assignment.assignment_group = @start_group
    @assignment.save!

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
              'assignment_group_id' => @group.id,
              'set_custom_field_values' => { 'test_custom' => { 'value' => '1' } } } })

    json.should == {
      'id' => @assignment.id,
      'assignment_group_id' => @group.id,
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

  it "should allow updating an assignment with overrides via the API" do
    course_with_teacher(:active_all => true)
    student_in_course(:course => @course, :active_enrollment => true)
    @assignment = @course.assignments.create!

    @adhoc_due_at = 5.days.from_now
    @section_due_at = 7.days.from_now

    @user = @teacher
    api_call(:put, "/api/v1/courses/#{@course.id}/assignments/#{@assignment.id}.json",
      { :controller => 'assignments_api', :action => 'update', :format => 'json', :course_id => @course.id.to_s, :id => @assignment.id.to_s },
      { :assignment => {
          'name' => 'some assignment',
          'assignment_overrides' => {
            '0' => { 'student_ids' => [@student.id], 'title' => 'adhoc override', 'due_at' => @adhoc_due_at.iso8601 },
            '1' => { 'course_section_id' => @course.default_section.id, 'due_at' => @section_due_at.iso8601 }}}})

    @assignment = Assignment.first
    @assignment.assignment_overrides.count.should == 2

    @adhoc_override = @assignment.assignment_overrides.find_by_set_type('ADHOC')
    @adhoc_override.should_not be_nil
    @adhoc_override.set.should == [@student]
    @adhoc_override.due_at_overridden.should be_true
    @adhoc_override.due_at.to_i.should == @adhoc_due_at.to_i

    @section_override = @assignment.assignment_overrides.find_by_set_type('CourseSection')
    @section_override.should_not be_nil
    @section_override.set.should == @course.default_section
    @section_override.due_at_overridden.should be_true
    @section_override.due_at.to_i.should == @section_due_at.to_i
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
      'author' => {},
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
      'locked' => false,
      'root_topic_id' => @topic.root_topic_id,
      'podcast_url' => nil,
      'podcast_has_student_posts' => nil,
      'read_state' => 'unread',
      'unread_count' => 0,
      'url' => "http://www.example.com/courses/#{@course.id}/discussion_topics/#{@topic.id}",
      'html_url' => "http://www.example.com/courses/#{@course.id}/discussion_topics/#{@topic.id}",
      'attachments' => [],
      'permissions' => {'delete' => true, 'attach' => true, 'update' => true},
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
    @assignment2.any_instantiation.expects(:locked_for?).returns({:asset_string => '', :unlock_at => 1.minute.from_now})

    json = api_call(:get,
          "/api/v1/courses/#{@course.id}/assignments.json",
          { :controller => 'assignments_api', :action => 'index',
            :format => 'json', :course_id => @course.id.to_s })
    json.size.should == 2
    json.find { |e| e['name'] == "Test Assignment" }['description'].should == "public stuff"
    json.find { |e| e['name'] == "Locked Assignment" }['description'].should be_nil
  end

  it "should delete an assignment" do
    course_with_student(:active_all => true)
    @a = @course.assignments.create! :title => "Test Assignment", :description => "public stuff"
    json = api_call(:delete,
          "/api/v1/courses/#{@course.id}/assignments/#{@a.id}",
          { :controller => 'assignments', :action => 'destroy',
            :format => 'json', :course_id => @course.id.to_s, :id => @a.to_param }, {}, {}, :expected_status => 401)
    @a.reload.should_not be_deleted

    # now as a teacher
    teacher_in_course(:course => @course, :active_all => true)
    json = api_call(:delete,
          "/api/v1/courses/#{@course.id}/assignments/#{@a.id}",
          { :controller => 'assignments', :action => 'destroy',
            :format => 'json', :course_id => @course.id.to_s, :id => @a.to_param })
    @a.reload.should be_deleted
  end

  it "should api translate assignment descriptions" do
    course_with_teacher(:active_all => true)
    should_translate_user_content(@course) do |content|
      assignment = @course.assignments.create!(:description => content)
      json = api_call(:get, "/api/v1/courses/#{@course.id}/assignments/#{assignment.id}",
                      :controller => 'assignments_api', :action => 'show', :format => 'json',
                      :course_id => @course.id.to_s, :id => assignment.id.to_s)
      json['description']
    end
  end

  it "should fulfill module progression requirements" do
    course_with_student(:active_all => true)
    @assignment = @course.assignments.create! :title => "Test Assignment", :description => "public stuff"

    mod = @course.context_modules.create!(:name => "some module")
    tag = mod.add_item(:id => @assignment.id, :type => 'assignment')
    mod.completion_requirements = { tag.id => {:type => 'must_view'} }
    mod.save!

    # index should not affect anything
    api_call(:get,
             "/api/v1/courses/#{@course.id}/assignments.json",
             { :controller => 'assignments_api', :action => 'index',
               :format => 'json', :course_id => @course.id.to_s })
    mod.evaluate_for(@user).should be_unlocked

    # show should count as a view
    json = api_call(:get,
             "/api/v1/courses/#{@course.id}/assignments/#{@assignment.id}.json",
             { :controller => "assignments_api", :action => "show",
               :format => "json", :course_id => @course.id.to_s,
               :id => @assignment.id.to_s })
    json['description'].should_not be_nil
    mod.evaluate_for(@user).should be_completed
  end

  it "should not fulfill requirements when description isn't returned" do
    course_with_student(:active_all => true)
    @assignment = @course.assignments.create! :title => "Locked Assignment", :description => "locked!"
    @assignment.any_instantiation.expects(:locked_for?).returns({:asset_string => '', :unlock_at => 1.hour.from_now}).at_least(1)

    mod = @course.context_modules.create!(:name => "some module")
    tag = mod.add_item(:id => @assignment.id, :type => 'assignment')
    mod.completion_requirements = { tag.id => {:type => 'must_view'} }
    mod.save!

    json = api_call(:get,
             "/api/v1/courses/#{@course.id}/assignments/#{@assignment.id}.json",
             { :controller => "assignments_api", :action => "show",
               :format => "json", :course_id => @course.id.to_s,
               :id => @assignment.id.to_s })
    json['description'].should be_nil
    mod.evaluate_for(@user).should be_unlocked
  end
end
