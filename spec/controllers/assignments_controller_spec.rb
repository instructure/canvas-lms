#
# Copyright (C) 2012 Instructure, Inc.
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

require File.expand_path(File.dirname(__FILE__) + '/../sharding_spec_helper')

describe AssignmentsController do
  def course_assignment(course = nil)
    course ||= @course
    @group = course.assignment_groups.create(:name => "some group")
    @assignment = course.assignments.create(:title => "some assignment", :assignment_group => @group)
    @assignment.assignment_group.should eql(@group)
    @group.assignments.should be_include(@assignment)
    @assignment
  end

  describe "GET 'index'" do
    it "should throw 404 error without a valid context id" do
      rescue_action_in_public! if CANVAS_RAILS2
      #controller.use_rails_error_handling!
      get 'index'
      assert_status(404)
    end

    it "should return unauthorized without a valid session" do
      course_with_student(:active_all => true)
      get 'index', :course_id => @course.id
      assert_status(401)
    end

    it "should redirect 'disabled', if disabled by the teacher" do
      course_with_student_logged_in(:active_all => true)
      @course.update_attribute(:tab_configuration, [{'id'=>3,'hidden'=>true}])
      get 'index', :course_id => @course.id
      response.should be_redirect
      flash[:notice].should match(/That page has been disabled/)
    end
    
    it "should assign variables" do
      course_with_student_logged_in(:active_all => true)
      
      get 'index', :course_id => @course.id
      assigns[:assignments].should_not be_nil
      assigns[:assignment_groups].should_not be_nil
    end
    
    it "should retrieve course assignments if they exist" do
      course_with_student_logged_in(:active_all => true)
      course_assignment

      get 'index', :course_id => @course.id
      assigns[:assignment_groups].should_not be_nil
      assigns[:assignment_groups].should_not be_empty
      assigns[:assignments].should_not be_nil
      assigns[:assignments].should_not be_empty
      assigns[:assignments][0].should eql(@assignment)
    end
    
    it "should create a default group if none exist" do
      course_with_student_logged_in(:active_all => true)
      
      get 'index', :course_id => @course.id
      
      assigns[:assignment_groups][0].name.should eql("Assignments")
    end

    context "draft state" do
      before do
        course_with_student(:active_all => true)
        @course.root_account.enable_feature!(:draft_state)
      end

      it "should create a default group if none exist" do
        course_with_student_logged_in(:active_all => true)

        get 'index', :course_id => @course.id

        @course.reload.assignment_groups.count.should == 1
      end

      it "should separate manage_assignments and manage_grades permissions" do
        course_with_teacher_logged_in active_all: true
        @course.account.role_overrides.create! enrollment_type: 'TeacherEnrollment', permission: 'manage_assignments', enabled: false
        get 'index', course_id: @course.id
        assigns[:js_env][:PERMISSIONS][:manage_grades].should be_true
        assigns[:js_env][:PERMISSIONS][:manage_assignments].should be_false
        assigns[:js_env][:PERMISSIONS][:manage].should be_false
      end
    end

    context "sharding" do
      specs_require_sharding

      it "should show assignments for all shards" do
        course_with_student_logged_in(:active_all => true)
        @assignment1 = course_assignment

        @shard2.activate do
          account = Account.create!
          course2 = account.courses.create!
          course2.offer!
          @assignment2 = course_assignment(course2)
          course2.enroll_student(@user).accept!
        end

        get 'index'
        assigns[:assignments].length.should == 2
        assigns[:assignments].should be_include(@assignment1)
        assigns[:assignments].should be_include(@assignment2)
      end
    end
  end
  
  describe "GET 'show'" do
    it "should return 404 on non-existant assignment" do
      rescue_action_in_public! if CANVAS_RAILS2
      #controller.use_rails_error_handling!
      course_with_student_logged_in(:active_all => true)

      get 'show', :course_id => @course.id, :id => 5
      assert_status(404)
    end

    it "should return unauthorized if not enrolled" do
      course_with_student(:active_all => true)
      course_assignment

      get 'show', :course_id => @course.id, :id => @assignment.id
      assert_unauthorized
    end

    it "should assign variables" do
      course_with_student_logged_in(:active_all => true)
      a = @course.assignments.create(:title => "some assignment")

      get 'show', :course_id => @course.id, :id => a.id
      @course.reload.assignment_groups.should_not be_empty
      assigns[:unlocked].should_not be_nil
    end

    it "should assign submission variable if current user and submitted" do
      course_with_student_logged_in(:active_all => true)
      course_assignment
      @assignment.submit_homework(@user, :submission_type => 'online_url', :url => 'http://www.google.com')
      get 'show', :course_id => @course.id, :id => @assignment.id
      response.should be_success
      assigns[:current_user_submission].should_not be_nil
    end

    it "should redirect to discussion if assignment is linked to discussion" do
      course_with_student_logged_in(:active_all => true)
      course_assignment
      @assignment.submission_types = 'discussion_topic'
      @assignment.save!

      get 'show', :course_id => @course.id, :id => @assignment.id
      response.should be_redirect
    end

    it "should not redirect to discussion for observer if assignment is linked to discussion but read_forum is false" do
      course_with_observer_logged_in(:active_all => true)
      course_assignment
      @assignment.submission_types = 'discussion_topic'
      @assignment.save!

      RoleOverride.create!(:context => @course.account, :permission => 'read_forum',
                           :enrollment_type => "ObserverEnrollment", :enabled => false)

      get 'show', :course_id => @course.id, :id => @assignment.id
      response.should_not be_redirect
      response.should be_success
    end

    it "should not show locked external tool assignments" do
      course_with_student_logged_in(:active_all => true)

      course_assignment
      @assignment.lock_at = Time.now - 1.week
      @assignment.unlock_at = Time.now + 1.week
      @assignment.submission_types = 'external_tool'
      @assignment.save
      # This is usually a ContentExternalTool, but it only needs to
      # be true here because we aren't redirecting to it.
      Assignment.any_instance.stubs(:external_tool_tag).returns(true)

      get 'show', :course_id => @course.id, :id => @assignment.id

      assigns[:locked].should be_true
      # make sure that the show.html.erb template is rendered, because
      # in normal cases we redirect to the assignment's external_tool_tag.
      response.should render_template('assignments/show')
    end

    it "should require login for external tools in a public course" do
      course_with_student(:active_all => true)
      @course.update_attribute(:is_public, true)
      @course.context_external_tools.create!(:shared_secret => 'test_secret', :consumer_key => 'test_key', :name => 'test tool', :domain => 'example.com')
      course_assignment
      @assignment.submission_types = 'external_tool'
      @assignment.build_external_tool_tag(:url => "http://example.com/test")
      @assignment.save!

      get 'show', :course_id => @course.id, :id => @assignment.id
      assert_require_login
    end

    it 'should not error out when google docs is not configured' do
      GoogleDocs::Connection.stubs(:config).returns nil
      course_with_student_logged_in(:active_all => true)
      a = @course.assignments.create(:title => "some assignment")
      get 'show', :course_id => @course.id, :id => a.id
      GoogleDocs::Connection.unstub(:config)
    end
  end

  describe "GET 'syllabus'" do
    it "should require authorization" do
      course_with_student
      rescue_action_in_public! if CANVAS_RAILS2
      #controller.use_rails_error_handling!
      get 'syllabus', :course_id => @course.id
      assert_unauthorized
    end
    
    it "should redirect 'disabled', if disabled by the teacher" do
      course_with_student_logged_in(:active_all => true)
      @course.update_attribute(:tab_configuration, [{'id'=>1,'hidden'=>true}])
      get 'syllabus', :course_id => @course.id
      response.should be_redirect
      flash[:notice].should match(/That page has been disabled/)
    end

    it "should assign variables" do
      course_with_student_logged_in(:active_all => true)
      get 'syllabus', :course_id => @course.id
      assigns[:assignment_groups].should_not be_nil
      assigns[:events].should_not be_nil
      assigns[:undated_events].should_not be_nil
      assigns[:dates].should_not be_nil
    end
  end

  describe "GET 'new'" do
    it "should require authorization" do
      rescue_action_in_public! if CANVAS_RAILS2
      #controller.use_rails_error_handling!
      course_with_student(:active_all => true)
      get 'new', :course_id => @course.id
      assert_unauthorized
    end

    it "should default to unpublished for draft state" do
      course_with_student(:active_all => true)
      @course.root_account.enable_feature!(:draft_state)
      @course.require_assignment_group

      get 'new', :course_id => @course.id

      assigns[:assignment].workflow_state.should == 'unpublished'
    end
  end
  
  describe "POST 'create'" do
    it "should require authorization" do
      rescue_action_in_public! if CANVAS_RAILS2
      #controller.use_rails_error_handling!
      course_with_student(:active_all => true)
      post 'create', :course_id => @course.id
      assert_unauthorized
    end
    
    it "should create assignment" do
      course_with_student_logged_in(:active_all => true)
      post 'create', :course_id => @course.id, :assignment => {:title => "some assignment"}
      assigns[:assignment].should_not be_nil
      assigns[:assignment].title.should eql("some assignment")
      assigns[:assignment].context_id.should eql(@course.id)
    end

    it "should create assignment when no groups exist yet" do
      course_with_student_logged_in(:active_all => true)
      post 'create', :course_id => @course.id, :assignment => {:title => "some assignment", :assignment_group_id => ''}
      assigns[:assignment].should_not be_nil
      assigns[:assignment].title.should eql("some assignment")
      assigns[:assignment].context_id.should eql(@course.id)
    end

    it "should set updating_user on created assignment" do
      course_with_teacher_logged_in(:active_all => true)
      post 'create', :course_id => @course.id, :assignment => {:title => "some assignment", :submission_types => "discussion_topic"}
      a = assigns[:assignment]
      a.should_not be_nil
      a.discussion_topic.should_not be_nil
      a.discussion_topic.user_id.should eql(@teacher.id)
    end

    it "should default to published if draft state is disabled" do
      Account.default.disable_feature!(:draft_state)
      course(:active_all => true)
      post 'create', :course_id => @course.id, :assignment => {:title => "some assignment"}
      assigns[:assignment].should be_published
    end

    it "should default to unpublished if draft state is enabled" do
      Account.default.enable_feature!(:draft_state)
      course(:active_all => true)
      post 'create', :course_id => @course.id, :assignment => {:title => "some assignment"}
      assigns[:assignment].should be_unpublished
    end
  end
  
  describe "GET 'edit'" do
    it "should require authorization" do
      rescue_action_in_public! if CANVAS_RAILS2
      #controller.use_rails_error_handling!
      course_with_student(:active_all => true)
      course_assignment
      get 'edit', :course_id => @course.id, :id => @assignment.id
      assert_unauthorized
    end
    
    it "should find assignment" do
      course_with_student_logged_in(:active_all => true)
      course_assignment
      get 'edit', :course_id => @course.id, :id => @assignment.id
      assigns[:assignment].should eql(@assignment)
    end

    it "bootstraps the correct assignment info to js_env" do
      course_with_teacher_logged_in(:active_all => true)
      course_assignment
      get 'edit', :course_id => @course.id, :id => @assignment.id
      assigns[:js_env][:ASSIGNMENT]['id'].should == @assignment.id
      assigns[:js_env][:ASSIGNMENT_OVERRIDES].should == []
    end

  end

  describe "PUT 'update'" do
    it "should require authorization" do
      rescue_action_in_public! if CANVAS_RAILS2
      #controller.use_rails_error_handling!
      course_with_student(:active_all => true)
      course_assignment
      put 'update', :course_id => @course.id, :id => @assignment.id
      assert_unauthorized
    end

    it "should update attributes" do
      course_with_teacher_logged_in(:active_all => true)
      course_assignment
      put 'update', :course_id => @course.id, :id => @assignment.id, :assignment => {:title => "test title"}
      assigns[:assignment].should eql(@assignment)
      assigns[:assignment].title.should eql("test title")
    end
  end

  describe "DELETE 'destroy'" do
    it "should require authorization" do
      course_with_student(:active_all => true)
      course_assignment
      delete 'destroy', :course_id => @course.id, :id => @assignment.id
      assert_unauthorized
    end

    it "should delete assignments if authorized" do
      course_with_teacher_logged_in(:active_all => true)
      course_assignment
      delete 'destroy', :course_id => @course.id, :id => @assignment.id
      assigns[:assignment].should_not be_nil
      assigns[:assignment].should_not be_frozen
      assigns[:assignment].should be_deleted
    end
  end
end
