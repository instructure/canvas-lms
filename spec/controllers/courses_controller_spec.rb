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
      assigns[:future_enrollments].should_not be_nil
    end

    it "should not duplicate enrollments in variables" do
      course_with_student_logged_in(:active_all => true)
      course
      @course.start_at = Time.now + 2.weeks
      @course.restrict_enrollments_to_course_dates = true
      @course.save!
      @course.offer!
      @course.enroll_student(@user)
      get 'index'
      response.should be_success
      assigns[:future_enrollments].each do |e|
        assigns[:current_enrollments].should_not include e
      end
    end

    it "should include unpublished courses in future enrollments for admins" do
      user
      future_course  = Course.create!(:name => 'future course', :start_at => Time.now + 2.weeks,
                                      :restrict_enrollments_to_course_dates => true)
      current_course = Course.create!(:name => 'current course', :start_at => Time.now - 2.weeks)

      current_unpublished_course  = Course.create!(:name => 'current course 2', :start_at => Time.now - 2.weeks)
      future_unpublished_course  = Course.create!(:name => 'future course 2', :start_at => Time.now + 2.weeks)
      future_unrestricted_course = Course.create!(:name => 'future course 3', :start_at => Time.now + 2.weeks)

      current_enrollment = StudentEnrollment.create!(:course => current_course, :user => @user)
      future_enrollment  = StudentEnrollment.create!(:course => future_course, :user => @user)
      current_unpublished_enrollment = TeacherEnrollment.create!(:course => current_unpublished_course, :user => @user)
      future_unpublished_enrollment = TeacherEnrollment.create!(:course => future_unpublished_course, :user => @user)
      future_unrestricted_enrollment = StudentEnrollment.create!(:course => future_unrestricted_course, :user => @user)

      [future_course, current_course, future_unrestricted_course].each { |course| course.offer }
      [current_enrollment, future_enrollment, current_unpublished_enrollment, future_unpublished_enrollment, future_unrestricted_enrollment].each { |e| e.accept }

      user_session(@user)
      get 'index'
      response.should be_success
      assigns[:future_enrollments].count.should == 3
      assigns[:future_enrollments].should include(future_enrollment)
      assigns[:future_enrollments].should include(current_unpublished_enrollment)
      assigns[:future_enrollments].should include(future_unpublished_enrollment)
    end

    it "should not include unpublished courses in future enrollments for students" do
      user
      future_course  = Course.create!(:name => 'future course', :start_at => Time.now + 2.weeks,
                                      :restrict_enrollments_to_course_dates => true)
      current_course = Course.create!(:name => 'current course', :start_at => Time.now - 2.weeks)

      current_unpublished_course  = Course.create!(:name => 'current course 2', :start_at => Time.now - 2.weeks)
      future_unpublished_course  = Course.create!(:name => 'future course 2', :start_at => Time.now + 2.weeks)
      future_unrestricted_published_course = Course.create!(:name => 'future course 3', :start_at => Time.now + 2.weeks)
      future_unrestricted_unpublished_course = Course.create!(:name => 'future course 4', :start_at => Time.now + 2.weeks)

      current_enrollment = StudentEnrollment.create!(:course => current_course, :user => @user)
      future_enrollment  = StudentEnrollment.create!(:course => future_course, :user => @user)
      current_unpublished_enrollment = StudentEnrollment.create!(:course => current_unpublished_course, :user => @user)
      future_unpublished_enrollment = StudentEnrollment.create!(:course => future_unpublished_course, :user => @user)

      future_unrestricted_published_enrollment = StudentEnrollment.create!(:course => future_unrestricted_published_course, :user => @user)
      future_unrestricted_unpublished_enrollment = StudentEnrollment.create!(:course => future_unrestricted_unpublished_course, :user => @user)

      [future_course, current_course, future_unrestricted_published_course].each { |course| course.offer }
      [current_enrollment, future_enrollment, current_unpublished_enrollment,
       future_unpublished_enrollment, future_unrestricted_published_enrollment].each { |e| e.accept }

      user_session(@user)
      get 'index'
      response.should be_success
      assigns[:current_enrollments].count.should == 2
      assigns[:current_enrollments].should include(current_enrollment)
      assigns[:current_enrollments].should include(future_unrestricted_published_enrollment)
      assigns[:future_enrollments].count.should == 1
      assigns[:future_enrollments].should include(future_enrollment)

    end
  end

  describe "GET 'statistics'" do
    it 'does not break using new student_ids method from course' do
      course_with_teacher_logged_in(:active_all => true)
      get 'statistics', :format => 'json', :course_id => @course.id
      response.should be_success
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
      assert_status(401)
      assigns[:unauthorized_reason].should == :unpublished
      assigns[:unauthorized_message].should_not be_nil

      @course.workflow_state = 'available'
      @course.save!
      @enrollment.start_at = 2.days.from_now
      @enrollment.end_at = 4.days.from_now
      @enrollment.save!
      get 'settings', :course_id => @course.id
      assert_status(401)
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
      post 'enrollment_invitation', :course_id => @course.id, :reject => '1', :invitation => "#{@enrollment.uuid}https://canvas.instructure.com/courses/#{@course.id}?invitation=#{@enrollment.uuid}"
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
      response.should redirect_to(login_url(:force_login => 1))
    end

    it "should accept an enrollment for a restricted by dates course" do
      course_with_student_logged_in(:active_all => true)

      @course.update_attributes(:restrict_enrollments_to_course_dates => true,
                                :start_at => Time.now + 2.weeks)
      @enrollment.update_attributes(:workflow_state => 'invited')

      post 'enrollment_invitation', :course_id => @course.id, :accept => '1',
        :invitation => @enrollment.uuid

      response.should redirect_to(courses_url)
      @enrollment.reload.workflow_state.should == 'active'
    end
  end

  describe "GET 'show'" do
    it "should require authorization" do
      course_with_teacher(:active_all => true)
      get 'show', :id => @course.id
      assert_unauthorized
    end

    it "should not find deleted courses" do
      course_with_teacher_logged_in(:active_all => true)
      @course.destroy
      assert_page_not_found do
        get 'show', :id => @course.id
      end
    end

    it "should assign variables" do
      course_with_student_logged_in(:active_all => true)
      get 'show', :id => @course.id
      response.should be_success
      assigns[:context].should eql(@course)
      assigns[:stream_items].should eql([])
    end

    it "should give a helpful error message for students that can't access yet" do
      course_with_student_logged_in(:active_all => true)
      @course.workflow_state = 'claimed'
      @course.save!
      get 'show', :id => @course.id
      assert_status(401)
      assigns[:unauthorized_reason].should == :unpublished
      assigns[:unauthorized_message].should_not be_nil

      @course.workflow_state = 'available'
      @course.save!
      @enrollment.start_at = 2.days.from_now
      @enrollment.end_at = 4.days.from_now
      @enrollment.save!
      get 'show', :id => @course.id
      assert_status(401)
      assigns[:unauthorized_reason].should == :unpublished
      assigns[:unauthorized_message].should_not be_nil
    end

    it "should allow student view student to view unpublished courses" do
      course_with_teacher_logged_in(:active_user => true, :active_enrollment => true)
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

    it "should show unauthorized/authorized to a student for a future course depending on restrict_student_future_view setting" do
      course_with_student_logged_in(:active_course => 1)
      a = @course.root_account
      a.settings[:restrict_student_future_view] = true
      a.save!

      @course.start_at = Time.now + 2.weeks
      @course.restrict_enrollments_to_course_dates = true
      @course.save!

      get 'show', :id => @course.id
      assert_status(401)
      assigns[:unauthorized_message].should_not be_nil

      a.settings[:restrict_student_future_view] = false
      a.save!

      controller.instance_variable_set(:@context_all_permissions, nil)

      get 'show', :id => @course.id
      response.should be_success
      assigns[:context].should eql(@course)
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
        @course1.save!
        get 'show', :id => @course1.id
        assigns(:recent_feedback).count.should == 1
        assigns(:recent_feedback).first.assignment_id.should == @a1.id
      end

      it "should disable management and set env urls on assignment homepage" do
        @course1.default_view = "assignments"
        @course1.save!
        @course1.account.enable_feature!(:draft_state)
        get 'show', :id => @course1.id
        controller.js_env[:URLS][:new_assignment_url].should_not be_nil
        controller.js_env[:PERMISSIONS][:manage].should be_false
      end

      it "should not show unpublished assignments to students" do
        @course1.default_view = "assignments"
        @course1.save!
        @course1.account.enable_feature!(:draft_state)
        @a1.unpublish
        get 'show', :id => @course1.id
        assigns(:assignments).map(&:id).include?(@a1.id).should be_false
      end

      it "should work for wiki view" do
        @course1.default_view = "wiki"
        @course1.save
        get 'show', :id => @course1.id
        assigns(:recent_feedback).count.should == 1
        assigns(:recent_feedback).first.assignment_id.should == @a1.id
      end

      it "should work for wiki view with draft state enabled" do
        @course1.account.allow_feature!(:draft_state)
        @course1.enable_feature!(:draft_state)
        @course1.default_view = "wiki"
        @course1.save!
        @course1.wiki.wiki_pages.create!(:title => 'blah').set_as_front_page!
        get 'show', :id => @course1.id
        controller.js_env[:WIKI_RIGHTS].should eql({:read => true})
        controller.js_env[:PAGE_RIGHTS].should eql({:read => true})
        controller.js_env[:COURSE_TITLE].should eql @course1.name
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
      before do
        Account.default.settings[:allow_invitation_previews] = true
        Account.default.save!
      end

      it "should allow an invited user to see the course" do
        course_with_student(:active_course => 1)
        @enrollment.should be_invited
        get 'show', :id => @course.id, :invitation => @enrollment.uuid
        response.should be_success
        assigns[:pending_enrollment].should == @enrollment
      end

      it "should still show unauthorized if unpublished, regardless of if previews are allowed" do
        # unpublished course with invited student in default account (allows previews)
        course_with_student
        @course.workflow_state = 'claimed'
        @course.save!

        get 'show', :id => @course.id, :invitation => @enrollment.uuid
        assert_status(401)
        assigns[:unauthorized_message].should_not be_nil

        # unpublished course with invited student in account that disallows previews
        @account = Account.create!
        course_with_student(:account => @account)
        @course.workflow_state = 'claimed'
        @course.save!

        get 'show', :id => @course.id, :invitation => @enrollment.uuid
        assert_status(401)
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
        assigns[:context_enrollment].should == @enrollment
        @enrollment.reload
        @enrollment.should be_active
      end

      it "should ignore invitations that have been accepted (not logged in)" do
        course_with_student(:active_course => 1, :active_enrollment => 1)
        get 'show', :id => @course.id, :invitation => @enrollment.uuid
        assert_status(401)
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
        cc = @user.communication_channels.build(:path => "jt@instructure.com")
        cc.user = @user
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
      response.should be_redirect
      response.location.should match(%r{/courses/#{@course.id}/settings})
    end

    it "should not redirect xhr to settings page when user can :read_as_admin, but not :read" do
      course(:active_all => true)
      user(:active_all => true)
      Account.site_admin.add_user(@user, 'LimitedAccess')
      user_session(@user)

      xhr :get, 'show', :id => @course.id
      response.should be_success
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

  describe "POST 'unenroll_user'" do
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

    it "should not enroll people in hard-concluded courses" do
      course_with_teacher_logged_in(:active_all => true)
      @course.complete
      post 'enroll_users', :course_id => @course.id, :user_list => "\"Sam\" <sam@yahoo.com>, \"Fred\" <fred@yahoo.com>"
      response.should_not be_success
      @course.reload
      @course.students.map{|s| s.name}.should_not be_include("Sam")
      @course.students.map{|s| s.name}.should_not be_include("Fred")
    end

    it "should not enroll people in soft-concluded courses" do
      course_with_teacher_logged_in(:active_all => true)
      @course.conclude_at = 1.day.ago
      @course.restrict_enrollments_to_course_dates = true
      @course.save!
      post 'enroll_users', :course_id => @course.id, :user_list => "\"Sam\" <sam@yahoo.com>, \"Fred\" <fred@yahoo.com>"
      response.should_not be_success
      @course.reload
      @course.students.map{|s| s.name}.should_not be_include("Sam")
      @course.students.map{|s| s.name}.should_not be_include("Fred")
    end

    it "should record initial_enrollment_type on new users" do
      course_with_teacher_logged_in(:active_all => true)
      post 'enroll_users', :course_id => @course.id, :user_list => "\"Sam\" <sam@yahoo.com>", :enrollment_type => 'ObserverEnrollment'
      response.should be_success
      @course.reload
      @course.observers.count.should == 1
      @course.observers.first.initial_enrollment_type.should == 'observer'
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

    it "will use json for limit_privileges_to_course_section param" do
      course_with_teacher_logged_in(:active_all => true)
      post 'enroll_users', :course_id => @course.id,
        :user_list => "\"Sam\" <sam@yahoo.com>",
        :enrollment_type => 'TeacherEnrollment',
        :limit_privileges_to_course_section => true
      response.should be_success
      run_jobs
      enrollment = @course.reload.teachers.select { |t| t.name == 'Sam' }.
        first.enrollments.first
      enrollment.limit_privileges_to_course_section.should == true
    end
  end

  describe "POST create" do
    before do
      @account = Account.default
      custom_account_role 'lamer', :account => @account
      @account.role_overrides.create! :permission => 'manage_courses', :enabled => true,
                                      :enrollment_type => 'lamer'
      user
      @account.add_user @user, 'lamer'
      user_session @user
    end

    it "should log create course event" do
      course = @account.courses.build({
        :name => "Course Name",
        :lock_all_announcements => true
      })
      changes = course.changes
      changes.delete("settings")
      changes["lock_all_announcements"] = [ nil, true ]

      Auditors::Course.expects(:record_created).with(anything, anything, changes, anything)

      post 'create', { :account_id => @account.id, :course =>
          { :name => course.name, :lock_all_announcements => true } }
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

    it "should log published event on update" do
      Auditors::Course.expects(:record_published).once
      course_with_teacher_logged_in(:active_all => true)
      put 'update', :id => @course.id, :offer => true
    end

    it "should lock active course announcements" do
      course_with_teacher_logged_in(:active_all => true)
      active_announcement  = @course.announcements.create!(:title => 'active', :message => 'test')
      delayed_announcement = @course.announcements.create!(:title => 'delayed', :message => 'test')
      deleted_announcement = @course.announcements.create!(:title => 'deleted', :message => 'test')

      delayed_announcement.workflow_state  = 'post_delayed'
      delayed_announcement.delayed_post_at = Time.now + 3.weeks
      delayed_announcement.save!

      deleted_announcement.destroy

      put 'update', :id => @course.id, :course => { :lock_all_announcements => 1 }
      assigns[:course].lock_all_announcements.should be_true

      active_announcement.reload.should be_locked
      delayed_announcement.reload.should be_post_delayed
      deleted_announcement.reload.should be_deleted
    end

    it "should log update course event" do
      course_with_teacher_logged_in( :active_all => true )
      @course.lock_all_announcements = true
      @course.save!

      changes = {
        "name" => [ @course.name, "new course name" ],
        "lock_all_announcements" => [ true, false ]
      }

      Auditors::Course.expects(:record_updated).with(anything, anything, changes, source: :manual)

      put 'update', :id => @course.id, :course => {
        :name => changes["name"].last,
        :lock_all_announcements => false
      }
    end

    it "should update its lock_all_announcements setting" do
      course_with_teacher_logged_in(:active_all => true)
      @course.lock_all_announcements = true
      @course.save!
      put 'update', :id => @course.id, :course => { :lock_all_announcements => 0 }
      assigns[:course].lock_all_announcements.should be_false
    end

    it "should let sub-account admins move courses to other accounts within their sub-account" do
      subaccount = account_model(:parent_account => Account.default)
      sub_subaccount1 = account_model(:parent_account => subaccount)
      sub_subaccount2 = account_model(:parent_account => subaccount)
      course(:account => sub_subaccount1)

      @user = account_admin_user(:account => subaccount, :active_user => true)
      user_session(@user)

      put 'update', :id => @course.id, :course => { :account_id => sub_subaccount2.id }

      @course.reload
      @course.account_id.should == sub_subaccount2.id
    end

    it "should not let sub-account admins move courses to other accounts outside their sub-account" do
      subaccount1 = account_model(:parent_account => Account.default)
      subaccount2 = account_model(:parent_account => Account.default)
      course(:account => subaccount1)

      @user = account_admin_user(:account => subaccount1, :active_user => true)
      user_session(@user)

      put 'update', :id => @course.id, :course => { :account_id => subaccount2.id }

      @course.reload
      @course.account_id.should == subaccount1.id
    end

    it "should let site admins move courses to any account" do
      account1 = Account.create!(:name => "account1")
      account2 = Account.create!(:name => "account2")
      course(:account => account1)

      user_session(site_admin_user)

      put 'update', :id => @course.id, :course => { :account_id => account2.id }

      @course.reload
      @course.account_id.should == account2.id
    end
  end

  describe "POST 'unconclude'" do
    it "should unconclude the course" do
      course_with_teacher_logged_in(:active_all => true)
      delete 'destroy', :id => @course.id, :event => 'conclude'
      response.should be_redirect
      @course.reload.should be_completed
      @course.conclude_at.should <= Time.now
      Auditors::Course.expects(:record_unconcluded).with(anything, anything, source: :manual)

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

    it "should redirect to the new self enrollment form" do
      course(:active_all => true)
      @course.update_attribute(:self_enrollment, true)
      get 'self_enrollment', :course_id => @course.id, :self_enrollment => @course.self_enrollment_code
      response.should redirect_to(enroll_url(@course.self_enrollment_code))
    end

    it "should redirect to the new self enrollment form if using a long code" do
      course(:active_all => true)
      @course.update_attribute(:self_enrollment, true)
      get 'self_enrollment', :course_id => @course.id, :self_enrollment => @course.long_self_enrollment_code.dup
      response.should redirect_to(enroll_url(@course.self_enrollment_code))
    end

    it "should return to the course page for an incorrect code" do
      course(:active_all => true)
      @course.update_attribute(:self_enrollment, true)
      user
      user_session(@user)

      get 'self_enrollment', :course_id => @course.id, :self_enrollment => 'abc'
      response.should redirect_to(course_url(@course))
      @user.enrollments.length.should == 0
    end

    it "should redirect to the new enrollment form even if self_enrollment is disabled" do
      course(:active_all => true)
      @course.update_attribute(:self_enrollment, true) # generate code
      code = @course.self_enrollment_code
      @course.update_attribute(:self_enrollment, false)

      get 'self_enrollment', :course_id => @course.id, :self_enrollment => code
      response.should redirect_to(enroll_url(code))
    end
  end

  describe "POST 'self_unenrollment'" do
    it "should unenroll" do
      course_with_student_logged_in(:active_all => true)
      @enrollment.update_attribute(:self_enrolled, true)

      post 'self_unenrollment', :course_id => @course.id, :self_unenrollment => @enrollment.uuid
      response.should be_success
      @enrollment.reload
      @enrollment.should be_completed
    end

    it "should not unenroll for incorrect code" do
      course_with_student_logged_in(:active_all => true)
      @enrollment.update_attribute(:self_enrolled, true)

      post 'self_unenrollment', :course_id => @course.id, :self_unenrollment => 'abc'
      assert_status(400)
      @enrollment.reload
      @enrollment.should be_active
    end

    it "should not unenroll a non-self-enrollment" do
      course_with_student_logged_in(:active_all => true)

      post 'self_unenrollment', :course_id => @course.id, :self_unenrollment => @enrollment.uuid
      assert_status(400)
      @enrollment.reload
      @enrollment.should be_active
    end
  end

  describe "GET 'sis_publish_status'" do
    it 'should check for authorization' do
      course_with_student_logged_in :active_all => true
      get 'sis_publish_status', :course_id => @course.id
      assert_status(401)
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
      response_body["sis_publish_statuses"]["Published"].sort_by!{|x|x["id"]}
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

      @plugin = Canvas::Plugin.find!('grade_export')
      @ps = PluginSetting.new(:name => @plugin.id, :settings => @plugin.default_settings)
      @ps.posted_settings = @plugin.default_settings.merge({
          :format_type => "instructure_csv",
          :wait_for_success => "no",
          :publish_endpoint => "http://localhost/endpoint"
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

      SSLCommon.expects(:post_data).once
      post "publish_to_sis", :course_id => @course.id

      response.should be_success
      response_body = json_parse(response.body)
      response_body["sis_publish_statuses"]["Published"].sort_by!{|x|x["id"]}
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
      feed.entries.should_not be_empty
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

    it "should not include unpublished assignments or discussions" do
      discussion_topic_model(:context => @course)
      @assignment.unpublish
      @topic.unpublish!
      get 'public_feed', :format => 'atom', :feed_code => @enrollment.feed_code
      feed = Atom::Feed.load_feed(response.body) rescue nil
      feed.should_not be_nil
      feed.entries.should be_empty
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
      assert_status(401)
      @course.reload.should be_available
    end

    it "should log reset audit event" do
      course_with_teacher_logged_in(:active_all => true)
      Auditors::Course.expects(:record_reset).once.with(@course, anything, @user, anything)
      post 'reset_content', :course_id => @course.id
    end
  end

  context "changed_settings" do
    let(:controller) { CoursesController.new }

    it "should have changed settings for a new course" do
      course = Course.new
      course.hide_final_grade = false
      course.hide_distribution_graphs = false
      course.assert_defaults
      changes = course.changes

      changed_settings = controller.changed_settings(changes, course.settings)

      changes.merge!(
        hide_final_grade: false,
        hide_distribution_graphs: false
      )

      changed_settings.should == changes
    end

    it "should have changed settings for an updated course" do
      course = Account.default.courses.create!
      old_values = course.settings

      course.hide_final_grade = false
      course.hide_distribution_graphs = false
      changes = course.changes

      changed_settings = controller.changed_settings(changes, course.settings, old_values)

      changes.merge!(
        hide_final_grade: false,
        hide_distribution_graphs: false
      )

      changed_settings.should == changes
    end
  end

  describe "quotas" do
    context "with :manage_storage_quotas" do
      before do
        @account = Account.default
        account_admin_user :account => @account
        user_session @user
      end

      describe "create" do
        it "should set storage_quota" do
          post 'create', { :account_id => @account.id, :course =>
              { :name => 'xyzzy', :storage_quota => 111.megabytes } }
          @course = @account.courses.find_by_name('xyzzy')
          @course.storage_quota.should == 111.megabytes
        end

        it "should set storage_quota_mb" do
          post 'create', { :account_id => @account.id, :course =>
              { :name => 'xyzpdq', :storage_quota_mb => 111 } }
          @course = @account.courses.find_by_name('xyzpdq')
          @course.storage_quota_mb.should == 111
        end
      end

      describe "update" do
        before do
          @course = @account.courses.create!
        end

        it "should set storage_quota" do
          post 'update', { :id => @course.id, :course =>
            { :storage_quota => 111.megabytes } }
          @course.reload.storage_quota.should == 111.megabytes
        end

        it "should set storage_quota_mb" do
          post 'update', { :id => @course.id, :course =>
            { :storage_quota_mb => 111 } }
          @course.reload.storage_quota_mb.should == 111
        end
      end
    end

    context "without :manage_storage_quotas" do
      describe "create" do
        before do
          @account = Account.default
          custom_account_role 'lamer', :account => @account
          @account.role_overrides.create! :permission => 'manage_courses', :enabled => true,
                                          :enrollment_type => 'lamer'
          user
          @account.add_user @user, 'lamer'
          user_session @user
        end

        it "should ignore storage_quota" do
          post 'create', { :account_id => @account.id, :course =>
              { :name => 'xyzzy', :storage_quota => 111.megabytes } }
          @course = @account.courses.find_by_name('xyzzy')
          @course.storage_quota.should == @account.default_storage_quota
        end

        it "should ignore storage_quota_mb" do
          post 'create', { :account_id => @account.id, :course =>
              { :name => 'xyzpdq', :storage_quota_mb => 111 } }
          @course = @account.courses.find_by_name('xyzpdq')
          @course.storage_quota_mb.should == @account.default_storage_quota / 1.megabyte
        end
      end

      describe "update" do
        before do
          @account = Account.default
          course_with_teacher_logged_in(:account => @account, :active_all => true)
        end

        it "should ignore storage_quota" do
          post 'update', { :id => @course.id, :course =>
              { :public_description => 'wat', :storage_quota => 111.megabytes } }
          @course.reload
          @course.public_description.should == 'wat'
          @course.storage_quota.should == @account.default_storage_quota
        end

        it "should ignore storage_quota_mb" do
          post 'update', { :id => @course.id, :course =>
              { :public_description => 'wat', :storage_quota_mb => 111 } }
          @course.reload
          @course.public_description.should == 'wat'
          @course.storage_quota_mb.should == @account.default_storage_quota / 1.megabyte
        end
      end
    end
  end
end
