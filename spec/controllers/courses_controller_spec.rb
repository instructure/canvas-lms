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

describe CoursesController do
  describe "GET 'index'" do
    it "should force login" do
      course_with_student(:active_all => true)
      get 'index'
      response.should be_redirect
    end
    
    it "should assign variables" do
      course_with_student_logged_in(:active_all => true)
      get 'index'
      response.should be_success
      assigns[:current_enrollments].should_not be_nil
      assigns[:current_enrollments].should_not be_empty
      assigns[:current_enrollments][0].should eql(@enrollment)
      assigns[:past_enrollments].should_not be_nil
    end
  end
  
  describe "GET 'settings'" do
    it "should require authorization" do
      course_with_teacher(:active_all => true)
      get 'settings', :course_id => @course.id
      assert_unauthorized
    end
    
    it "should should not allow students" do
      course_with_student_logged_in(:active_all => true)
      get 'settings', :course_id => @course.id
      assert_unauthorized
    end

    it "should render properly" do
      course_with_teacher_logged_in(:active_all => true)
      get 'settings', :course_id => @course.id
      response.should be_success
      response.should render_template("settings")
    end

    it "should give a helpful error message for students that can't access yet" do
      course_with_student_logged_in(:active_all => true)
      @course.workflow_state = 'claimed'
      @course.save!
      get 'settings', :course_id => @course.id
      response.status.should == '401 Unauthorized'
      assigns[:unauthorized_reason].should == :unpublished
      assigns[:unauthorized_message].should_not be_nil

      @course.workflow_state = 'available'
      @course.save!
      @enrollment.start_at = 2.days.from_now
      @enrollment.end_at = 4.days.from_now
      @enrollment.save!
      get 'settings', :course_id => @course.id
      response.status.should == '401 Unauthorized'
      assigns[:unauthorized_reason].should == :unpublished
      assigns[:unauthorized_message].should_not be_nil
    end
  end
  
  describe "GET 'enrollment_invitation'" do
    it "should successfully reject invitation for logged-in user" do
      course_with_student_logged_in(:active_course => true)
      post 'enrollment_invitation', :course_id => @course.id, :reject => '1', :invitation => @enrollment.uuid
      response.should be_redirect
      response.should redirect_to(dashboard_url)
      assigns[:pending_enrollment].should eql(@enrollment)
      assigns[:pending_enrollment].should be_rejected
    end
    
    it "should successfully reject invitation for not-logged-in user" do
      course_with_student(:active_course => true, :active_user => true)
      post 'enrollment_invitation', :course_id => @course.id, :reject => '1', :invitation => @enrollment.uuid
      response.should be_redirect
      response.should redirect_to(root_url)
      assigns[:pending_enrollment].should eql(@enrollment)
      assigns[:pending_enrollment].should be_rejected
    end

    it "should successfully reject temporary invitation" do
      user_with_pseudonym(:active_all => 1)
      user_session(@user, @pseudonym)
      user = User.create! { |u| u.workflow_state = 'creation_pending' }
      user.communication_channels.create!(:path => @cc.path)
      course(:active_all => 1)
      @enrollment = @course.enroll_student(user)
      post 'enrollment_invitation', :course_id => @course.id, :reject => '1', :invitation => @enrollment.uuid
      response.should be_redirect
      response.should redirect_to(root_url)
      assigns[:pending_enrollment].should eql(@enrollment)
      assigns[:pending_enrollment].should be_rejected
    end

    it "should not reject invitation for bad parameters" do
      course_with_student(:active_course => true, :active_user => true)
      post 'enrollment_invitation', :course_id => @course.id, :reject => '1', :invitation => @enrollment.uuid + 'a'
      response.should be_redirect
      response.should redirect_to(course_url(@course.id))
      assigns[:pending_enrollment].should be_nil
    end
    
    it "should accept invitation for logged-in user" do
      course_with_student_logged_in(:active_course => true, :active_user => true)
      post 'enrollment_invitation', :course_id => @course.id, :accept => '1', :invitation => @enrollment.uuid
      response.should be_redirect
      response.should redirect_to(course_url(@course.id))
      assigns[:pending_enrollment].should eql(@enrollment)
      assigns[:pending_enrollment].should be_active
    end
    
    it "should ask user to login for registered not-logged-in user" do
      user_with_pseudonym(:active_course => true, :active_user => true)
      course(:active_all => true)
      @enrollment = @course.enroll_user(@user)
      post 'enrollment_invitation', :course_id => @course.id, :accept => '1', :invitation => @enrollment.uuid
      response.should be_redirect
      response.should redirect_to(login_url)
    end
    
    it "should defer to registration_confirmation for pre-registered not-logged-in user" do
      user_with_pseudonym
      course(:active_course => true, :active_user => true)
      @enrollment = @course.enroll_user(@user)
      post 'enrollment_invitation', :course_id => @course.id, :accept => '1', :invitation => @enrollment.uuid
      response.should be_redirect
      response.should redirect_to(registration_confirmation_url(@pseudonym.communication_channel.confirmation_code, :enrollment => @enrollment.uuid))
    end

    it "should defer to registration_confirmation if logged-in user does not match enrollment user" do
      user_with_pseudonym
      @u2 = @user
      course_with_student_logged_in(:active_course => true, :active_user => true)
      @e2 = @course.enroll_user(@u2)
      post 'enrollment_invitation', :course_id => @course.id, :accept => '1', :invitation => @e2.uuid
      response.should redirect_to(registration_confirmation_url(:nonce => @pseudonym.communication_channel.confirmation_code, :enrollment => @e2.uuid))
    end

    it "should ask user to login if logged-in user does not match enrollment user, and enrollment user doesn't have an e-mail" do
      user
      @user.register!
      @u2 = @user
      course_with_student_logged_in(:active_course => true, :active_user => true)
      @e2 = @course.enroll_user(@u2)
      post 'enrollment_invitation', :course_id => @course.id, :accept => '1', :invitation => @e2.uuid
      response.should redirect_to(login_url(:re_login => 1))
    end
  end
  
  describe "GET 'show'" do
    it "should require authorization" do
      course_with_teacher(:active_all => true)
      get 'show', :id => @course.id
      assert_unauthorized
    end
    
    it "should assign variables" do
      course_with_student_logged_in(:active_all => true)
      get 'show', :id => @course.id
      response.should be_success
      assigns[:context].should eql(@course)
      # assigns[:message_types].should_not be_nil
    end

    it "should give a helpful error message for students that can't access yet" do
      course_with_student_logged_in(:active_all => true)
      @course.workflow_state = 'claimed'
      @course.save!
      get 'show', :id => @course.id
      response.status.should == '401 Unauthorized'
      assigns[:unauthorized_reason].should == :unpublished
      assigns[:unauthorized_message].should_not be_nil

      @course.workflow_state = 'available'
      @course.save!
      @enrollment.start_at = 2.days.from_now
      @enrollment.end_at = 4.days.from_now
      @enrollment.save!
      get 'show', :id => @course.id
      response.status.should == '401 Unauthorized'
      assigns[:unauthorized_reason].should == :unpublished
      assigns[:unauthorized_message].should_not be_nil
    end

    it "should allow student view student to view unpublished courses" do
      course_with_teacher_logged_in(:active_user => true)
      @course.should_not be_available
      @fake_student = @course.student_view_student
      session[:become_user_id] = @fake_student.id

      get 'show', :id => @course.id
      response.should be_success
    end

    it "should not allow student view students to view other courses" do
      course_with_teacher_logged_in(:active_user => true)
      @c1 = @course

      course(:active_course => true)
      @c2 = @course

      @fake1 = @c1.student_view_student
      session[:become_user_id] = @fake1.id

      get 'show', :id => @c2.id
      assert_unauthorized
    end
    
    context "show feedback for the current course only on course front page" do
      before(:each) do
        course_with_student_logged_in(:active_all => true)
        @course1 = @course
        course_with_teacher(:course => @course1)
        
        course_with_student(:active_all => true, :user => @student)
        @course2 = @course
        course_with_teacher(:course => @course2, :user => @teacher)
        
        @a1 = @course1.assignments.new(:title => "some assignment course 1")
        @a1.workflow_state = "published"
        @a1.save
        @s1 = @a1.submit_homework(@student)
        @c1 = @s1.add_comment(:author => @teacher, :comment => "some comment1")
        
        # this shouldn't show up in any course 1 list
        @a2 = @course2.assignments.new(:title => "some assignment course 2")
        @a2.workflow_state = "published"
        @a2.save
        @s2 = @a2.submit_homework(@student)
        @c2 = @s2.add_comment(:author => @teacher, :comment => "some comment2")
      end
      
      it "should work for module view" do 
        @course1.default_view = "modules"
        @course1.save
        get 'show', :id => @course1.id
        assigns(:recent_feedback).count.should == 1
        assigns(:recent_feedback).first.assignment_id.should == @a1.id
      end
      
      it "should work for assignments view" do 
        @course1.default_view = "assignments"
        @course1.save
        get 'show', :id => @course1.id
        assigns(:recent_feedback).count.should == 1
        assigns(:recent_feedback).first.assignment_id.should == @a1.id
      end
      
      it "should work for wiki view" do 
        @course1.default_view = "wiki"
        @course1.save
        get 'show', :id => @course1.id
        assigns(:recent_feedback).count.should == 1
        assigns(:recent_feedback).first.assignment_id.should == @a1.id
      end
      
      it "should work for syllabus view" do 
        @course1.default_view = "syllabus"
        @course1.save
        get 'show', :id => @course1.id
        assigns(:recent_feedback).count.should == 1
        assigns(:recent_feedback).first.assignment_id.should == @a1.id
      end
      
      it "should work for feed view" do 
        @course1.default_view = "feed"
        @course1.save
        get 'show', :id => @course1.id
        assigns(:recent_feedback).count.should == 1
        assigns(:recent_feedback).first.assignment_id.should == @a1.id
      end
      
      it "should only show recent feedback if user is student in specified course" do
        course_with_teacher(:active_all => true, :user => @student)
        @course3 = @course
        get 'show', :id => @course3.id
        assigns(:show_recent_feedback).should be_false
      end
    end

    context "invitations" do
      it "should allow an invited user to see the course" do
        course_with_student(:active_course => 1)
        @enrollment.should be_invited
        get 'show', :id => @course.id, :invitation => @enrollment.uuid
        response.should be_success
        assigns[:pending_enrollment].should == @enrollment
      end

      it "should still show unauthorized if unpublished, regardless of if previews are allowed" do
        # unpublished course with invited student in default account (disallows previews)
        course_with_student
        @course.workflow_state = 'claimed'
        @course.save!

        get 'show', :id => @course.id, :invitation => @enrollment.uuid
        response.status.should == '401 Unauthorized'
        assigns[:unauthorized_message].should_not be_nil

        # unpublished course with invited student in account that allows previews
        @account = Account.create!
        course_with_student(:account => @account)
        @course.workflow_state = 'claimed'
        @course.save!

        get 'show', :id => @course.id, :invitation => @enrollment.uuid
        response.status.should == '401 Unauthorized'
        assigns[:unauthorized_message].should_not be_nil
      end

      it "should not show unauthorized for invited teachers when unpublished" do
        # unpublished course with invited teacher
        course_with_teacher
        @course.workflow_state = 'claimed'
        @course.save!

        get 'show', :id => @course.id, :invitation => @enrollment.uuid
        response.should be_success
      end

      it "should re-invite an enrollment that has previously been rejected" do
        course_with_student(:active_course => 1)
        @enrollment.should be_invited
        @enrollment.reject!
        get 'show', :id => @course.id, :invitation => @enrollment.uuid
        response.should be_success
        @enrollment.reload
        @enrollment.should be_invited
      end

      it "should auto-accept if previews are not allowed" do
        # Currently, previews are only allowed for the default account
        @account = Account.create!
        course_with_student_logged_in(:active_course => 1, :account => @account)
        get 'show', :id => @course.id, :invitation => @enrollment.uuid
        response.should be_success
        response.should render_template('show')
        assigns[:pending_enrollment].should be_nil
        assigns[:context_enrollment].should == @enrollment
        @enrollment.reload
        @enrollment.should be_active
      end

      it "should ignore invitations that have been accepted (not logged in)" do
        course_with_student(:active_course => 1, :active_enrollment => 1)
        get 'show', :id => @course.id, :invitation => @enrollment.uuid
        response.status.should == '401 Unauthorized'
      end

      it "should ignore invitations that have been accepted (logged in)" do
        course_with_student_logged_in(:active_course => 1, :active_enrollment => 1)
        get 'show', :id => @course.id, :invitation => @enrollment.uuid
        response.should be_success
        assigns[:pending_enrollment].should be_nil
      end

      it "should use the invitation enrollment, rather than the current enrollment" do
        course_with_student_logged_in(:active_course => 1, :active_user => 1)
        @student1 = @student
        @enrollment1 = @enrollment
        student_in_course
        @enrollment.should be_invited

        get 'show', :id => @course.id, :invitation => @enrollment.uuid
        response.should be_success
        assigns[:pending_enrollment].should == @enrollment
        assigns[:current_user].should == @student1
        session[:enrollment_uuid].should == @enrollment.uuid
        @enrollment.reload
        @enrollment.should be_invited

        get 'show', :id => @course.id # invitation should be in the session now
        response.should be_success
        assigns[:pending_enrollment].should == @enrollment
        assigns[:current_user].should == @student1
        session[:enrollment_uuid].should == @enrollment.uuid
        @enrollment.reload
        @enrollment.should be_invited
      end

      it "should auto-redirect to registration page when it's a self-enrollment" do
        course_with_student(:active_course => 1)
        @user = User.new
        @user.communication_channels.build(:path => "jt@instructure.com")
        @user.workflow_state = 'creation_pending'
        @user.save!
        @enrollment = @course.enroll_student(@user)
        @enrollment.update_attribute(:self_enrolled, true)
        @enrollment.should be_invited

        get 'show', :id => @course.id, :invitation => @enrollment.uuid
        response.should redirect_to(registration_confirmation_url(@user.email_channel.confirmation_code, :enrollment => @enrollment.uuid))
      end

      it "should not use the session enrollment if it's for the wrong course" do
        course_with_student(:active_course => 1)
        @enrollment1 = @enrollment
        @course1 = @course
        course(:active_course => 1)
        student_in_course(:user => @user)
        @enrollment2 = @enrollment
        @course2 = @course
        user_session(@user)

        get 'show', :id => @course1.id
        response.should be_success
        assigns[:pending_enrollment].should == @enrollment1
        session[:enrollment_uuid].should == @enrollment1.uuid

        controller.instance_variable_set(:@pending_enrollment, nil)
        get 'show', :id => @course2.id
        response.should be_success
        assigns[:pending_enrollment].should == @enrollment2
        session[:enrollment_uuid].should == @enrollment2.uuid
      end

      it "should find temporary enrollments that match the logged in user" do
        course(:active_course => 1)
        @temporary = User.create! { |u| u.workflow_state = 'creation_pending' }
        @temporary.communication_channels.create!(:path => 'user@example.com')
        @enrollment = @course.enroll_student(@temporary)
        @user = user_with_pseudonym(:active_all => 1, :username => 'user@example.com')
        @enrollment.should be_invited
        user_session(@user)

        get 'show', :id => @course.id
        response.should be_success
        assigns[:pending_enrollment].should == @enrollment
      end
    end

    it "should redirect html to settings page when user can :read_as_admin, but not :read" do
      # an account user on the site admin will always have :read_as_admin
      # permission to any course, but will not have :read permission unless
      # they've been granted the :read_course_content role override, which
      # defaults to false for everyone except those with the AccountAdmin role
      course(:active_all => true)
      user(:active_all => true)
      Account.site_admin.add_user(@user, 'LimitedAccess')
      user_session(@user)

      get 'show', :id => @course.id
      response.status.should == '302 Found'
      response.location.should match(%r{/courses/#{@course.id}/settings})
    end

    it "should not redirect xhr to settings page when user can :read_as_admin, but not :read" do
      course(:active_all => true)
      user(:active_all => true)
      Account.site_admin.add_user(@user, 'LimitedAccess')
      user_session(@user)

      xhr :get, 'show', :id => @course.id
      response.status.should == '200 OK'
    end

    it "should redirect to the xlisted course" do
      course_with_student_logged_in(:active_all => true)
      @course1 = @course
      @course2 = course(:active_all => true)
      @course1.default_section.crosslist_to_course(@course2, :run_jobs_immediately => true)

      get 'show', :id => @course1.id
      response.should be_redirect
      response.location.should match(%r{/courses/#{@course2.id}})
    end
  end
  
  describe "POST 'unenroll'" do
    it "should require authorization" do
      course_with_teacher(:active_all => true)
      post 'unenroll_user', :course_id => @course.id, :id => @enrollment.id
      assert_unauthorized
    end
    
    it "should not allow students to unenroll" do
      course_with_student_logged_in(:active_all => true)
      post 'unenroll_user', :course_id => @course.id, :id => @enrollment.id
      assert_unauthorized
    end
    
    it "should unenroll users" do
      course_with_teacher_logged_in(:active_all => true)
      student_in_course
      post 'unenroll_user', :course_id => @course.id, :id => @enrollment.id
      @course.reload
      response.should be_success
      @course.enrollments.map{|e| e.user}.should_not be_include(@student)
    end

    it "should not allow teachers to unenroll themselves" do
      course_with_teacher_logged_in(:active_all => true)
      post 'unenroll_user', :course_id => @course.id, :id => @enrollment.id
      assert_unauthorized
    end

    it "should allow admins to unenroll themselves" do
      course_with_teacher_logged_in(:active_all => true)
      @course.account.add_user(@teacher)
      post 'unenroll_user', :course_id => @course.id, :id => @enrollment.id
      @course.reload
      response.should be_success
      @course.enrollments.map{|e| e.user}.should_not be_include(@teacher)
    end
  end
  
  describe "POST 'enroll_users'" do
    before :each do
      account = Account.default
      account.settings = { :open_registration => true }
      account.save!
    end

    it "should require authorization" do
      course_with_teacher(:active_all => true)
      post 'enroll_users', :course_id => @course.id, :user_list => "sam@yahoo.com"
      assert_unauthorized
    end
    
    it "should not allow students to enroll people" do
      course_with_student_logged_in(:active_all => true)
      post 'enroll_users', :course_id => @course.id, :user_list => "\"Sam\" <sam@yahoo.com>, \"Fred\" <fred@yahoo.com>"
      assert_unauthorized
    end
    
    it "should enroll people" do
      course_with_teacher_logged_in(:active_all => true)
      post 'enroll_users', :course_id => @course.id, :user_list => "\"Sam\" <sam@yahoo.com>, \"Fred\" <fred@yahoo.com>"
      response.should be_success
      @course.reload
      @course.students.map{|s| s.name}.should be_include("Sam")
      @course.students.map{|s| s.name}.should be_include("Fred")
    end

    it "should allow TAs to enroll Observers (by default)" do
      course_with_teacher(:active_all => true)
      @user = user
      @course.enroll_ta(user).accept!
      user_session(@user)
      post 'enroll_users', :course_id => @course.id, :user_list => "\"Sam\" <sam@yahoo.com>, \"Fred\" <fred@yahoo.com>", :enrollment_type => 'ObserverEnrollment'
      response.should be_success
      @course.reload
      @course.students.should be_empty
      @course.observers.map{|s| s.name}.should be_include("Sam")
      @course.observers.map{|s| s.name}.should be_include("Fred")
    end
    
  end
  
  describe "PUT 'update'" do
    it "should require authorization" do
      course_with_teacher(:active_all => true)
      put 'update', :id => @course.id, :course => {:name => "new course name"}
      assert_unauthorized
    end
    
    it "should not let students update the course details" do
      course_with_student_logged_in(:active_all => true)
      put 'update', :id => @course.id, :course => {:name => "new course name"}
      assert_unauthorized
    end
    
    it "should update course details" do
      course_with_teacher_logged_in(:active_all => true)
      put 'update', :id => @course.id, :course => {:name => "new course name"}
      assigns[:course].should_not be_nil
      assigns[:course].should eql(@course)
    end
    
    it "should allow sending events" do
      course_with_teacher_logged_in(:active_all => true)
      put 'update', :id => @course.id, :course => {:event => "complete"}
      assigns[:course].should_not be_nil
      assigns[:course].state.should eql(:completed)
    end
  end

  describe "POST unconclude" do
    it "should unconclude the course" do
      course_with_teacher_logged_in(:active_all => true)
      delete 'destroy', :id => @course.id, :event => 'conclude'
      response.should be_redirect
      @course.reload.should be_completed
      @course.conclude_at.should <= Time.now

      post 'unconclude', :course_id => @course.id
      response.should be_redirect
      @course.reload.should be_available
      @course.conclude_at.should be_nil
    end
  end

  describe "GET 'self_enrollment'" do
    before do
      Account.default.update_attribute(:settings, :self_enrollment => 'any', :open_registration => true)
    end

    it "should enroll the currently logged in user" do
      course(:active_all => true)
      @course.update_attribute(:self_enrollment, true)
      user
      user_session(@user, @pseudonym)

      get 'self_enrollment', :course_id => @course.id, :self_enrollment => @course.self_enrollment_code.dup
      response.should redirect_to(course_url(@course))
      flash[:notice].should_not be_empty
      @user.enrollments.length.should == 1
      @enrollment = @user.enrollments.first
      @enrollment.course.should == @course
      @enrollment.workflow_state.should == 'active'
      @enrollment.should be_self_enrolled
    end

    it "should enroll the currently logged in user using the long code" do
      course(:active_all => true)
      @course.update_attribute(:self_enrollment, true)
      user
      user_session(@user, @pseudonym)

      get 'self_enrollment', :course_id => @course.id, :self_enrollment => @course.long_self_enrollment_code
      response.should redirect_to(course_url(@course))
      flash[:notice].should_not be_empty
      @user.enrollments.length.should == 1
      @enrollment = @user.enrollments.first
      @enrollment.course.should == @course
      @enrollment.workflow_state.should == 'active'
      @enrollment.should be_self_enrolled
    end

    it "should create a compatible pseudonym" do
      @account2 = Account.create!
      course(:active_all => true, :account => @account2)
      @course.update_attribute(:self_enrollment, true)
      user_with_pseudonym(:active_all => 1, :username => 'jt@instructure.com')
      user_session(@user, @pseudonym)
      @new_pseudonym = Pseudonym.new(:account => @account2, :unique_id => 'jt@instructure.com', :user => @user)
      User.any_instance.stubs(:find_or_initialize_pseudonym_for_account).with(@account2).once.returns(@new_pseudonym)

      get 'self_enrollment', :course_id => @course.id, :self_enrollment => @course.self_enrollment_code.dup
      response.should redirect_to(course_url(@course))
      flash[:notice].should_not be_empty
      @user.enrollments.length.should == 1
      @enrollment = @user.enrollments.first
      @enrollment.course.should == @course
      @enrollment.workflow_state.should == 'active'
      @enrollment.should be_self_enrolled
      @user.reload.pseudonyms.length.should == 2
    end

    it "should not enroll for incorrect code" do
      course(:active_all => true)
      @course.update_attribute(:self_enrollment, true)
      user
      user_session(@user)

      get 'self_enrollment', :course_id => @course.id, :self_enrollment => 'abc'
      response.should redirect_to(course_url(@course))
      @user.enrollments.length.should == 0
    end

    it "should not enroll if self_enrollment is disabled" do
      course(:active_all => true)
      user
      user_session(@user)

      get 'self_enrollment', :course_id => @course.id, :self_enrollment => @course.long_self_enrollment_code.dup
      response.should redirect_to(course_url(@course))
      @user.enrollments.length.should == 0
    end

    it "should redirect to login without open registration" do
      Account.default.update_attribute(:settings, :open_registration => false)
      course(:active_all => true)
      @course.update_attribute(:self_enrollment, true)

      get 'self_enrollment', :course_id => @course.id, :self_enrollment => @course.self_enrollment_code.dup
      response.should redirect_to(login_url)
    end

    it "should render for non-logged-in user" do
      course(:active_all => true)
      @course.update_attribute(:self_enrollment, true)

      get 'self_enrollment', :course_id => @course.id, :self_enrollment => @course.self_enrollment_code.dup
      response.should be_success
      response.should render_template('open_enrollment')
    end

    it "should create a creation_pending user" do
      course(:active_all => true)
      @course.update_attribute(:self_enrollment, true)

      post 'self_enrollment', :course_id => @course.id, :self_enrollment => @course.self_enrollment_code.dup, :email => 'bracken@instructure.com'
      response.should be_success
      response.should render_template('open_enrollment_confirmed')
      @course.student_enrollments.length.should == 1
      @enrollment = @course.student_enrollments.first
      @enrollment.should be_self_enrolled
      @enrollment.should be_invited
      @enrollment.user.should be_creation_pending
      @enrollment.user.email_channel.path.should == 'bracken@instructure.com'
      @enrollment.user.email_channel.should be_unconfirmed
      @enrollment.user.pseudonyms.should be_empty
    end
  end

  describe "GET 'self_unenrollment'" do
    it "should unenroll" do
      course_with_student_logged_in(:active_all => true)
      @enrollment.update_attribute(:self_enrolled, true)

      get 'self_unenrollment', :course_id => @course.id, :self_unenrollment => @enrollment.uuid
      response.should redirect_to(course_url(@course))
      @enrollment.reload
      @enrollment.should be_completed
    end

    it "should not unenroll for incorrect code" do
      course_with_student_logged_in(:active_all => true)
      @enrollment.update_attribute(:self_enrolled, true)

      get 'self_unenrollment', :course_id => @course.id, :self_unenrollment => 'abc'
      response.should redirect_to(course_url(@course))
      @enrollment.reload
      @enrollment.should be_active
    end

    it "should not unenroll a non-self-enrollment" do
      course_with_student_logged_in(:active_all => true)

      get 'self_unenrollment', :course_id => @course.id, :self_unenrollment => @enrollment.uuid
      response.should redirect_to(course_url(@course))
      @enrollment.reload
      @enrollment.should be_active
    end
  end

  describe "GET 'sis_publish_status'" do
    it 'should check for authorization' do
      course_with_student_logged_in :active_all => true
      get 'sis_publish_status', :course_id => @course.id
      response.status.should =~ /401 Unauthorized/
    end

    it 'should not try and publish grades' do
      Course.any_instance.expects(:publish_final_grades).times(0)
      course_with_teacher_logged_in :active_all => true
      get 'sis_publish_status', :course_id => @course.id
      response.should be_success
      json_parse(response.body).should == {"sis_publish_overall_status" => "unpublished", "sis_publish_statuses" => {}}
    end

    it 'should return reasonable json for a few enrollments' do
      course_with_teacher_logged_in :active_all => true
      students = [
          student_in_course({:course => @course, :active_all => true}),
          student_in_course({:course => @course, :active_all => true}),
          student_in_course({:course => @course, :active_all => true})
        ]
      students[0].tap do |enrollment|
        enrollment.grade_publishing_status = "published"
        enrollment.save!
      end
      students[1].tap do |enrollment|
        enrollment.grade_publishing_status = "error"
        enrollment.grade_publishing_message = "cause of this reason"
        enrollment.save!
      end
      students[2].tap do |enrollment|
        enrollment.grade_publishing_status = "published"
        enrollment.save!
      end
      get 'sis_publish_status', :course_id => @course.id
      response.should be_success
      response_body = json_parse(response.body)
      response_body["sis_publish_statuses"]["Published"].sort!{|x,y|x["id"] <=> y["id"]}
      response_body.should == {
          "sis_publish_overall_status" => "error",
          "sis_publish_statuses" => {
              "Error: cause of this reason" => [
                  {"name"=>"User", "sortable_name"=>"User", "url"=>course_user_url(@course, students[1].user), "id"=>students[1].user.id}
                ],
              "Published" => [
                  {"name"=>"User", "sortable_name"=>"User", "url"=>course_user_url(@course, students[0].user), "id"=>students[0].user.id},
                  {"name"=>"User", "sortable_name"=>"User", "url"=>course_user_url(@course, students[2].user), "id"=>students[2].user.id}
                ].sort_by{|x|x["id"]}
            }
        }
    end
  end

  describe "POST 'publish_to_sis'" do
    it "should publish grades and return results" do
      course_with_teacher_logged_in :active_all => true
      @teacher = @user
      students = [
          student_in_course({:course => @course, :active_all => true}),
          student_in_course({:course => @course, :active_all => true}),
          student_in_course({:course => @course, :active_all => true})
        ]
      students[0].tap do |enrollment|
        enrollment.grade_publishing_status = "published"
        enrollment.save!
      end
      students[1].tap do |enrollment|
        enrollment.grade_publishing_status = "error"
        enrollment.grade_publishing_message = "cause of this reason"
        enrollment.save!
      end
      students[2].tap do |enrollment|
        enrollment.grade_publishing_status = "published"
        enrollment.save!
      end

      server, server_thread, post_lines = start_test_http_server
      @plugin = Canvas::Plugin.find!('grade_export')
      @ps = PluginSetting.new(:name => @plugin.id, :settings => @plugin.default_settings)
      @ps.posted_settings = @plugin.default_settings.merge({
          :format_type => "instructure_csv",
          :wait_for_success => "no",
          :publish_endpoint => "http://localhost:#{server.addr[1]}/endpoint"
        })
      @ps.save!

      @course.assignment_groups.create(:name => "Assignments")
      @course.grading_standard_enabled = true
      @course.save!
      a1 = @course.assignments.create!(:title => "A1", :points_possible => 10)
      a2 = @course.assignments.create!(:title => "A2", :points_possible => 10)
      a1.grade_student(students[0].user, { :grade => "9", :grader => @teacher })
      a2.grade_student(students[0].user, { :grade => "10", :grader => @teacher })
      a1.grade_student(students[1].user, { :grade => "6", :grader => @teacher })
      a2.grade_student(students[1].user, { :grade => "7", :grader => @teacher })

      post "publish_to_sis", :course_id => @course.id

      server_thread.join

      response.should be_success
      response_body = json_parse(response.body)
      response_body["sis_publish_statuses"]["Published"].sort!{|x,y|x["id"] <=> y["id"]}
      response_body.should == {
          "sis_publish_overall_status" => "published",
          "sis_publish_statuses" => {
              "Published" => [
                  {"name"=>"User", "sortable_name"=>"User", "url"=>course_user_url(@course, students[0].user), "id"=>students[0].user.id},
                  {"name"=>"User", "sortable_name"=>"User", "url"=>course_user_url(@course, students[1].user), "id"=>students[1].user.id},
                  {"name"=>"User", "sortable_name"=>"User", "url"=>course_user_url(@course, students[2].user), "id"=>students[2].user.id}
                ].sort_by{|x|x["id"]}
            }
        }
    end
  end

  describe "GET 'public_feed.atom'" do
    before(:each) do
      course_with_student(:active_all => true)
      assignment_model(:course => @course)
    end

    it "should require authorization" do
      get 'public_feed', :format => 'atom', :feed_code => @enrollment.feed_code + 'x'
      assigns[:problem].should match /The verification code does not match/
    end

    it "should include absolute path for rel='self' link" do
      get 'public_feed', :format => 'atom', :feed_code => @enrollment.feed_code
      feed = Atom::Feed.load_feed(response.body) rescue nil
      feed.should_not be_nil
      feed.links.first.rel.should match(/self/)
      feed.links.first.href.should match(/http:\/\//)
    end

    it "should include an author for each entry" do
      get 'public_feed', :format => 'atom', :feed_code => @enrollment.feed_code
      feed = Atom::Feed.load_feed(response.body) rescue nil
      feed.should_not be_nil
      feed.entries.should_not be_empty
      feed.entries.all?{|e| e.authors.present?}.should be_true
    end
  end

  describe "POST 'reset_content'" do
    it "should allow teachers to reset" do
      course_with_teacher_logged_in(:active_all => true)
      post 'reset_content', :course_id => @course.id
      response.should be_redirect
      @course.reload.should be_deleted
    end

    it "should not allow TAs to reset" do
      course_with_ta(:active_all => true)
      user_session(@user)
      post 'reset_content', :course_id => @course.id
      response.status.to_i.should == 401
      @course.reload.should be_available
    end
  end
end
