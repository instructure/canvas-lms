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

require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe AssignmentGroupsController do
  def course_assignment
    @assignment = @course.assignments.create(:title => "some assignment")
  end
  def course_group
    @group = @course.assignment_groups.create(:name => "some group")
  end
  def group_assignment
    @assignment = @group.assignments.create(:name => "some group assignment")
  end

  before :once do
    course_with_teacher(active_all: true)
    student_in_course(active_all: true)
  end

  describe "GET 'index'" do
    it "should require authorization" do
      get 'index', :course_id => @course.id
      assert_unauthorized
    end

    it "should assign variables" do
      user_session(@student)
      get 'index', :course_id => @course.id, :format => :json
      assigns[:groups].should_not be_nil
    end

    it "should retrieve course groups if they exist" do
      user_session(@student)
      course_group
      @group = course_group

      get 'index', :course_id => @course.id, :format => :json

      assigns[:groups].should_not be_nil
      assigns[:groups].should_not be_empty
      assigns[:groups][1].should eql(@group)
    end
  end

  describe "POST 'reorder'" do
    it "should require authorization" do
      post 'reorder', :course_id => @course.id
      assert_unauthorized
    end

    it "should not allowe students to reorder" do
      user_session(@student)
      post 'reorder', :course_id => @course.id
      assert_unauthorized
    end

    it "should reorder assignment groups" do
      user_session(@teacher)
      groups = 3.times.map { course_group }
      groups.map(&:position).should == [1, 2, 3]
      g1, g2, _ = groups
      post 'reorder', :course_id => @course.id, :order => "#{g2.id},#{g1.id}"
      response.should be_success
      groups.each &:reload
      groups.map(&:position).should == [2, 1, 3]
    end

  end

  describe "GET 'show'" do
    before(:once) { course_group }

    it "should require authorization" do
      get 'show', :course_id => @course.id, :id => @group.id
      assert_unauthorized
    end

    it "should assign variables" do
      user_session(@student)
      get 'show', :course_id => @course.id, :id => @group.id, :format => :json
      # response.should be_success
      assigns[:assignment_group].should_not be_nil
      assigns[:assignment_group].should eql(@group)
    end
  end

  describe "POST 'create'" do
    it "should require authorization" do
      post 'create', :course_id => @course.id
      assert_unauthorized
    end

    it "should not allow students to create" do
      user_session(@student)
      post 'create', :course_id => @course.id
      assert_unauthorized
    end

    it "should create a new group" do
      user_session(@teacher)
      post 'create', :course_id => @course.id, :assignment_group => {:name => "some test group"}
      response.should be_redirect
      assigns[:assignment_group].should_not be_nil
      assigns[:assignment_group].name.should eql("some test group")
      assigns[:assignment_group].position.should eql(1)
    end

  end

  describe "PUT 'update'" do
    before(:once) { course_group }

    it "should require authorization" do
      put 'update', :course_id => @course.id, :id => @group.id
      assert_unauthorized
    end

    it "should not allow students to update" do
      user_session(@student)
      put 'update', :course_id => @course.id, :id => @group.id
      assert_unauthorized
    end

    it "should update group" do
      user_session(@teacher)
      put 'update', :course_id => @course.id, :id => @group.id, :assignment_group => {:name => "new group name"}
      assigns[:assignment_group].should_not be_nil
      assigns[:assignment_group].should eql(@group)
      assigns[:assignment_group].name.should eql("new group name")
    end
  end

  describe "DELETE 'destroy'" do
    before(:once) { course_group }

    it "should require authorization" do
      delete 'destroy', :course_id => @course.id, :id => @group.id
      assert_unauthorized
    end

    it "should not allow students to delete" do
      user_session(@student)
      delete 'destroy', :course_id => @course.id, :id => @group.id
      assert_unauthorized
    end

    it "should delete group" do
      user_session(@teacher)
      delete 'destroy', :course_id => @course.id, :id => @group.id
      assigns[:assignment_group].should_not be_nil
      assigns[:assignment_group].should eql(@group)
      assigns[:assignment_group].should_not be_frozen
      assigns[:assignment_group].should be_deleted
    end

    it "should delete assignments in the group" do
      user_session(@teacher)
      @group1 = @course.assignment_groups.create!(:name => "group 1")
      @assignment1 = @course.assignments.create!(:title => "assignment 1", :assignment_group => @group1)
      delete 'destroy', :course_id => @course.id, :id => @group1.id
      assigns[:assignment_group].should eql(@group1)
      assigns[:assignment_group].should be_deleted
      @group1.reload.assignments.length.should eql(1)
      @group1.reload.assignments[0].should eql(@assignment1)
      @group1.assignments.active.length.should eql(0)
    end

    it "should move assignments to a different group if specified" do
      user_session(@teacher)
      @group1 = @course.assignment_groups.create!(:name => "group 1")
      @assignment1 = @course.assignments.create!(:title => "assignment 1", :assignment_group => @group1)
      @group2 = @course.assignment_groups.create!(:name => "group 2")
      @assignment2 = @course.assignments.create!(:title => "assignment 2", :assignment_group => @group2)
      @assignment1.position.should eql(1)
      @assignment1.assignment_group_id.should eql(@group1.id)
      @assignment2.position.should eql(1)
      @assignment2.assignment_group_id.should eql(@group2.id)

      delete 'destroy', :course_id => @course.id, :id => @group2.id, :move_assignments_to => @group1.id

      assigns[:assignment_group].should eql(@group2)
      assigns[:assignment_group].should be_deleted
      @group2.reload.assignments.length.should eql(0)
      @group1.reload.assignments.length.should eql(2)
      @group1.assignments.active.length.should eql(2)
      @assignment1.reload.position.should eql(1)
      @assignment1.assignment_group_id.should eql(@group1.id)
      @assignment2.reload.position.should eql(2)
      @assignment2.assignment_group_id.should eql(@group1.id)
    end

    it "does not allow users to delete assignment groups with frozen assignments" do
      PluginSetting.stubs(:settings_for_plugin).returns(title: 'yes')
      user_session(@teacher)
      group = @course.assignment_groups.create!(name: "group 1")
      assignment = @course.assignments.create!(title: "assignment",
                                               assignment_group: group,
                                               freeze_on_copy: true)
      assignment.position.should == 1
      assignment.copied = true
      assignment.save!
      delete 'destroy', format: :json, course_id: @course.id, id: group.id
      response.should_not be_success
    end

    it "should return JSON if requested" do
      user_session(@teacher)
      delete 'destroy', :format => "json", :course_id => @course.id, :id => @group.id
      response.should be_success
    end
  end
end
