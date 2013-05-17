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

require File.expand_path(File.dirname(__FILE__) + '/../sharding_spec_helper')

describe UsersController do

  it "should filter account users by term" do
    a = Account.default
    u = user(:active_all => true)
    a.add_user(u)
    user_session(@user)
    t1 = a.default_enrollment_term
    t2 = a.enrollment_terms.create!(:name => 'Term 2')

    e1 = course_with_student(:active_all => true)
    c1 = e1.course
    c1.update_attributes!(:enrollment_term => t1)
    e2 = course_with_student(:active_all => true)
    c2 = e2.course
    c2.update_attributes!(:enrollment_term => t2)
    c3 = course_with_student(:active_all => true, :user => e1.user).course
    c3.update_attributes!(:enrollment_term => t1)

    User.update_account_associations(User.all.map(&:id))

    get 'index', :account_id => a.id
    assigns[:users].map(&:id).sort.should == [u, e1.user, c1.teachers.first, e2.user, c2.teachers.first, c3.teachers.first].map(&:id).sort

    get 'index', :account_id => a.id, :enrollment_term_id => t1.id
    assigns[:users].map(&:id).sort.should == [e1.user, c1.teachers.first, c3.teachers.first].map(&:id).sort # 1 student, enrolled twice, and 2 teachers

    get 'index', :account_id => a.id, :enrollment_term_id => t2.id
    assigns[:users].map(&:id).sort.should == [e2.user, c2.teachers.first].map(&:id).sort
  end

  it "should not include deleted courses in manageable courses" do
    course_with_teacher_logged_in(:course_name => "MyCourse1", :active_all => 1)
    course1 = @course
    course1.destroy
    course_with_teacher(:course_name => "MyCourse2", :user => @teacher, :active_all => 1)
    course2 = @course

    get 'manageable_courses', :user_id => @teacher.id, :term => "MyCourse"
    response.should be_success

    courses = json_parse
    courses.map { |c| c['id'] }.should == [course2.id]
  end

  context "GET 'delete'" do
    it "should fail when the user doesn't exist" do
      account_admin_user
      user_session(@admin)
      lambda { get 'delete', :user_id => (User.all.map(&:id).max + 1)}.should raise_error(ActiveRecord::RecordNotFound)
    end

    it "should fail when the current user doesn't have user manage permissions" do
      course_with_teacher_logged_in
      student_in_course :course => @course
      get 'delete', :user_id => @student.id
      response.status.should =~ /401 Unauthorized/
    end

    it "should succeed when the current user has the :manage permission and is not deleting any system-generated pseudonyms" do
      course_with_student_logged_in
      get 'delete', :user_id => @student.id
      response.should be_success
    end

    it "should fail when the current user won't be able to delete managed pseudonyms" do
      course_with_student_logged_in
      managed_pseudonym @student
      get 'delete', :user_id => @student.id
      flash[:error].should =~ /cannot delete a system-generated user/
      response.redirected_to.should == user_profile_url(@student)
    end

    it "should succeed when the current user has enough permissions to delete any system-generated pseudonyms" do
      account_admin_user
      user_session(@admin)
      course_with_student
      managed_pseudonym @student
      get 'delete', :user_id => @student.id
      flash[:error].should_not =~ /cannot delete a system-generated user/
      response.should be_success
    end
  end

  context "POST 'destroy'" do
    it "should fail when the user doesn't exist" do
      account_admin_user
      user_session(@admin)
      PseudonymSession.find(1).stubs(:destroy).returns(nil)
      lambda { post 'destroy', :id => (User.all.map(&:id).max + 1)}.should raise_error(ActiveRecord::RecordNotFound)
    end

    it "should fail when the current user doesn't have user manage permissions" do
      course_with_teacher_logged_in
      student_in_course :course => @course
      PseudonymSession.find(1).stubs(:destroy).returns(nil)
      post 'destroy', :id => @student.id
      response.status.should =~ /401 Unauthorized/
      @student.reload.workflow_state.should_not == 'deleted'
    end

    it "should succeed when the current user has the :manage permission and is not deleting any system-generated pseudonyms" do
      course_with_student_logged_in
      PseudonymSession.find(1).stubs(:destroy).returns(nil)
      post 'destroy', :id => @student.id
      response.redirected_to.should == root_url
      @student.reload.workflow_state.should == 'deleted'
    end

    it "should fail when the current user won't be able to delete managed pseudonyms" do
      course_with_student_logged_in
      managed_pseudonym @student
      PseudonymSession.find(1).stubs(:destroy).returns(nil)
      lambda { post 'destroy', :id => @student.id }.should raise_error
      @student.reload.workflow_state.should_not == 'deleted'
    end

    it "should succeed when the current user has enough permissions to delete any system-generated pseudonyms" do
      account_admin_user
      user_session(@admin)
      course_with_student
      managed_pseudonym @student
      PseudonymSession.find(1).stubs(:destroy).returns(nil)
      post 'destroy', :id => @student.id
      response.redirected_to.should == users_url
      @student.reload.workflow_state.should == 'deleted'
    end

    it "should clear the session and log the user out when the current user deletes himself, with managed pseudonyms and :manage_login permissions" do
      account_admin_user
      user_session(@admin)
      managed_pseudonym @admin
      PseudonymSession.find(1).expects(:destroy).returns(nil)
      post 'destroy', :id => @admin.id
      response.redirected_to.should == root_url
      @admin.reload.workflow_state.should == 'deleted'
    end

    it "should clear the session and log the user out when the current user deletes himself, without managed pseudonyms and :manage_login permissions" do
      course_with_student_logged_in
      PseudonymSession.find(1).expects(:destroy).returns(nil)
      post 'destroy', :id => @student.id
      response.redirected_to.should == root_url
      @student.reload.workflow_state.should == 'deleted'
    end
  end

  context "POST 'create'" do
    it "should not allow creating when self_registration is disabled and you're not an admin'" do
      post 'create', :pseudonym => { :unique_id => 'jacob@instructure.com' }, :user => { :name => 'Jacob Fugal' }
      response.should_not be_success
    end

    context 'self registration' do
      before :each do
        a = Account.default
        a.settings = { :self_registration => true }
        a.save!
      end

      it "should create a pre_registered user" do
        post 'create', :pseudonym => { :unique_id => 'jacob@instructure.com' }, :user => { :name => 'Jacob Fugal', :terms_of_use => '1' }
        response.should be_success

        p = Pseudonym.find_by_unique_id('jacob@instructure.com')
        p.should be_active
        p.user.should be_pre_registered
        p.user.name.should == 'Jacob Fugal'
        p.user.communication_channels.length.should == 1
        p.user.communication_channels.first.should be_unconfirmed
        p.user.communication_channels.first.path.should == 'jacob@instructure.com'
        p.user.associated_accounts.should == [Account.default]
      end

      it "should complain about conflicting unique_ids" do
        u = User.create! { |u| u.workflow_state = 'registered' }
        p = u.pseudonyms.create!(:unique_id => 'jacob@instructure.com')
        post 'create', :pseudonym => { :unique_id => 'jacob@instructure.com' }, :user => { :name => 'Jacob Fugal', :terms_of_use => '1' }
        response.status.should =~ /400 Bad Request/
        json = JSON.parse(response.body)
        json["errors"]["pseudonym"]["unique_id"].should be_present
        Pseudonym.find_all_by_unique_id('jacob@instructure.com').should == [p]
      end

      it "should not complain about conflicting ccs, in any state" do
        user1, user2, user3 = User.create!, User.create!, User.create!
        cc1 = user1.communication_channels.create!(:path => 'jacob@instructure.com', :path_type => 'email')
        cc2 = user2.communication_channels.create!(:path => 'jacob@instructure.com', :path_type => 'email') { |cc| cc.workflow_state == 'confirmed' }
        cc3 = user3.communication_channels.create!(:path => 'jacob@instructure.com', :path_type => 'email') { |cc| cc.workflow_state == 'retired' }

        post 'create', :pseudonym => { :unique_id => 'jacob@instructure.com' }, :user => { :name => 'Jacob Fugal', :terms_of_use => '1' }
        response.should be_success

        p = Pseudonym.find_by_unique_id('jacob@instructure.com')
        p.should be_active
        p.user.should be_pre_registered
        p.user.name.should == 'Jacob Fugal'
        p.user.communication_channels.length.should == 1
        p.user.communication_channels.first.should be_unconfirmed
        p.user.communication_channels.first.path.should == 'jacob@instructure.com'
        [cc1, cc2, cc3].should_not be_include(p.user.communication_channels.first)
      end

      it "should re-use 'conflicting' unique_ids if it hasn't been fully registered yet" do
        u = User.create! { |u| u.workflow_state = 'creation_pending' }
        p = Pseudonym.create!(:unique_id => 'jacob@instructure.com', :user => u)
        post 'create', :pseudonym => { :unique_id => 'jacob@instructure.com' }, :user => { :name => 'Jacob Fugal', :terms_of_use => '1' }
        response.should be_success

        Pseudonym.find_all_by_unique_id('jacob@instructure.com').should == [p]
        p.reload
        p.should be_active
        p.user.should be_pre_registered
        p.user.name.should == 'Jacob Fugal'
        p.user.communication_channels.length.should == 1
        p.user.communication_channels.first.should be_unconfirmed
        p.user.communication_channels.first.path.should == 'jacob@instructure.com'

        post 'create', :pseudonym => { :unique_id => 'jacob@instructure.com' }, :user => { :name => 'Jacob Fugal', :terms_of_use => '1' }
        response.should be_success

        Pseudonym.find_all_by_unique_id('jacob@instructure.com').should == [p]
        p.reload
        p.should be_active
        p.user.should be_pre_registered
        p.user.name.should == 'Jacob Fugal'
        p.user.communication_channels.length.should == 1
        p.user.communication_channels.first.should be_unconfirmed
        p.user.communication_channels.first.path.should == 'jacob@instructure.com'

        # case sensitive?
        post 'create', :pseudonym => { :unique_id => 'JACOB@instructure.com' }, :user => { :name => 'Jacob Fugal', :terms_of_use => '1' }
        response.should be_success

        Pseudonym.by_unique_id('jacob@instructure.com').all.should == [p]
        Pseudonym.by_unique_id('JACOB@instructure.com').all.should == [p]
        p.reload
        p.should be_active
        p.user.should be_pre_registered
        p.user.name.should == 'Jacob Fugal'
        p.user.communication_channels.length.should == 1
        p.user.communication_channels.first.should be_unconfirmed
        p.user.communication_channels.first.path.should == 'jacob@instructure.com'
      end

      it "should validate acceptance of the terms" do
        post 'create', :pseudonym => { :unique_id => 'jacob@instructure.com' }, :user => { :name => 'Jacob Fugal' }
        response.status.should =~ /400 Bad Request/
        json = JSON.parse(response.body)
        json["errors"]["user"]["terms_of_use"].should be_present
      end

      it "should require email pseudonyms by default" do
        post 'create', :pseudonym => { :unique_id => 'jacob' }, :user => { :name => 'Jacob Fugal', :terms_of_use => '1' }
        response.status.should =~ /400 Bad Request/
        json = JSON.parse(response.body)
        json["errors"]["pseudonym"]["unique_id"].should be_present
      end

      it "should require email pseudonyms if not self enrolling" do
        post 'create', :pseudonym => { :unique_id => 'jacob' }, :user => { :name => 'Jacob Fugal', :terms_of_use => '1' }, :pseudonym_type => 'username'
        response.status.should =~ /400 Bad Request/
        json = JSON.parse(response.body)
        json["errors"]["pseudonym"]["unique_id"].should be_present
      end

      it "should validate the self enrollment code" do
        post 'create', :pseudonym => { :unique_id => 'jacob@instructure.com', :password => 'asdfasdf', :password_confirmation => 'asdfasdf' }, :user => { :name => 'Jacob Fugal', :terms_of_use => '1', :self_enrollment_code => 'omg ... not valid', :initial_enrollment_type => 'student' }, :self_enrollment => '1'
        response.status.should =~ /400 Bad Request/
        json = JSON.parse(response.body)
        json["errors"]["user"]["self_enrollment_code"].should be_present
      end

      it "should ignore the password if not self enrolling" do
        post 'create', :pseudonym => { :unique_id => 'jacob@instructure.com', :password => 'asdfasdf', :password_confirmation => 'asdfasdf' }, :user => { :name => 'Jacob Fugal', :terms_of_use => '1', :initial_enrollment_type => 'student' }
        response.should be_success
        u = User.find_by_name 'Jacob Fugal'
        u.should be_pre_registered
        u.pseudonym.should be_password_auto_generated
      end

      it "should ignore the password if self enrolling with an email pseudonym" do
        course(:active_all => true)
        @course.update_attribute(:self_enrollment, true)

        post 'create', :pseudonym => { :unique_id => 'jacob@instructure.com', :password => 'asdfasdf', :password_confirmation => 'asdfasdf' }, :user => { :name => 'Jacob Fugal', :terms_of_use => '1', :self_enrollment_code => @course.self_enrollment_code, :initial_enrollment_type => 'student' }, :pseudonym_type => 'email', :self_enrollment => '1'
        response.should be_success
        u = User.find_by_name 'Jacob Fugal'
        u.should be_pre_registered
        u.pseudonym.should be_password_auto_generated
      end

      it "should require a password if self enrolling with a non-email pseudonym" do
        course(:active_all => true)
        @course.update_attribute(:self_enrollment, true)

        post 'create', :pseudonym => { :unique_id => 'jacob' }, :user => { :name => 'Jacob Fugal', :terms_of_use => '1', :self_enrollment_code => @course.self_enrollment_code, :initial_enrollment_type => 'student' }, :pseudonym_type => 'username', :self_enrollment => '1'
        response.status.should =~ /400 Bad Request/
        json = JSON.parse(response.body)
        json["errors"]["pseudonym"]["password"].should be_present
        json["errors"]["pseudonym"]["password_confirmation"].should be_present
      end

      it "should auto-register the user if self enrolling" do
        course(:active_all => true)
        @course.update_attribute(:self_enrollment, true)

        post 'create', :pseudonym => { :unique_id => 'jacob', :password => 'asdfasdf', :password_confirmation => 'asdfasdf' }, :user => { :name => 'Jacob Fugal', :terms_of_use => '1', :self_enrollment_code => @course.self_enrollment_code, :initial_enrollment_type => 'student' }, :pseudonym_type => 'username', :self_enrollment => '1'
        response.should be_success
        u = User.find_by_name 'Jacob Fugal'
        @course.students.should include(u)
        u.should be_registered
        u.pseudonym.should_not be_password_auto_generated
      end

      it "should validate the observee's credentials" do
        user_with_pseudonym(:active_all => true, :password => 'lolwut')

        post 'create', :pseudonym => { :unique_id => 'jacob@instructure.com' }, :observee => { :unique_id => @pseudonym.unique_id, :password => 'not it' }, :user => { :name => 'Jacob Fugal', :terms_of_use => '1', :initial_enrollment_type => 'observer' }
        response.status.should =~ /400 Bad Request/
        json = JSON.parse(response.body)
        json["errors"]["observee"]["unique_id"].should be_present
      end

      it "should link the user to the observee" do
        user_with_pseudonym(:active_all => true, :password => 'lolwut')

        post 'create', :pseudonym => { :unique_id => 'jacob@instructure.com' }, :observee => { :unique_id => @pseudonym.unique_id, :password => 'lolwut' }, :user => { :name => 'Jacob Fugal', :terms_of_use => '1', :initial_enrollment_type => 'observer' }
        response.should be_success
        u = User.find_by_name 'Jacob Fugal'
        u.should be_pre_registered
        response.should be_success
        u.observed_users.should include(@user)
      end
    end

    context 'account admin creating users' do

      describe 'successfully' do
        let!(:account) { Account.create! }

        before do
          user_with_pseudonym(:account => account)
          account.add_user(@user)
          user_session(@user, @pseudonym)
        end

        it "should create a pre_registered user (in the correct account)" do
          post 'create', :format => 'json', :account_id => account.id, :pseudonym => { :unique_id => 'jacob@instructure.com', :sis_user_id => 'testsisid' }, :user => { :name => 'Jacob Fugal' }
          response.should be_success
          p = Pseudonym.find_by_unique_id('jacob@instructure.com')
          p.account_id.should == account.id
          p.should be_active
          p.sis_user_id.should == 'testsisid'
          p.user.should be_pre_registered
        end

        it "should create users with non-email pseudonyms" do
          post 'create', :format => 'json', :account_id => account.id, :pseudonym => { :unique_id => 'jacob', :sis_user_id => 'testsisid' }, :user => { :name => 'Jacob Fugal' }
          response.should be_success
          p = Pseudonym.find_by_unique_id('jacob')
          p.account_id.should == account.id
          p.should be_active
          p.sis_user_id.should == 'testsisid'
          p.user.should be_pre_registered
        end


        it "should not require acceptance of the terms" do
          post 'create', :account_id => account.id, :pseudonym => { :unique_id => 'jacob@instructure.com' }, :user => { :name => 'Jacob Fugal' }
          response.should be_success
        end

        it "should allow setting a password" do
          post 'create', :account_id => account.id, :pseudonym => { :unique_id => 'jacob@instructure.com', :password => 'asdfasdf', :password_confirmation => 'asdfasdf' }, :user => { :name => 'Jacob Fugal' }
          u = User.find_by_name 'Jacob Fugal'
          u.should be_present
          u.pseudonym.should_not be_password_auto_generated
        end

      end

      it "should not allow an admin to set the sis id when creating a user if they don't have privileges to manage sis" do
        account = Account.create!
        admin = account_admin_user_with_role_changes(:account => account, :role_changes => {'manage_sis' => false})
        user_session(admin)
        post 'create', :format => 'json', :account_id => account.id, :pseudonym => { :unique_id => 'jacob@instructure.com', :sis_user_id => 'testsisid' }, :user => { :name => 'Jacob Fugal' }
        response.should be_success
        p = Pseudonym.find_by_unique_id('jacob@instructure.com')
        p.account_id.should == account.id
        p.should be_active
        p.sis_user_id.should be_nil
        p.user.should be_pre_registered
      end

      it "should notify the user if a merge opportunity arises" do
        notification = Notification.create(:name => 'Merge Email Communication Channel', :category => 'Registration')

        account = Account.create!
        user_with_pseudonym(:account => account)
        account.add_user(@user)
        user_session(@user, @pseudonym)
        @admin = @user

        u = User.create! { |u| u.workflow_state = 'registered' }
        u.communication_channels.create!(:path => 'jacob@instructure.com', :path_type => 'email') { |cc| cc.workflow_state = 'active' }
        u.pseudonyms.create!(:unique_id => 'jon@instructure.com')
        post 'create', :format => 'json', :account_id => account.id, :pseudonym => { :unique_id => 'jacob@instructure.com', :send_confirmation => '0' }, :user => { :name => 'Jacob Fugal' }
        response.should be_success
        p = Pseudonym.find_by_unique_id('jacob@instructure.com')
        Message.where(:communication_channel_id => p.user.email_channel, :notification_id => notification).first.should_not be_nil
      end

      it "should not notify the user if the merge opportunity can't log in'" do
        notification = Notification.create(:name => 'Merge Email Communication Channel', :category => 'Registration')

        account = Account.create!
        user_with_pseudonym(:account => account)
        account.add_user(@user)
        user_session(@user, @pseudonym)
        @admin = @user

        u = User.create! { |u| u.workflow_state = 'registered' }
        u.communication_channels.create!(:path => 'jacob@instructure.com', :path_type => 'email') { |cc| cc.workflow_state = 'active' }
        post 'create', :format => 'json', :account_id => account.id, :pseudonym => { :unique_id => 'jacob@instructure.com', :send_confirmation => '0' }, :user => { :name => 'Jacob Fugal' }
        response.should be_success
        p = Pseudonym.find_by_unique_id('jacob@instructure.com')
        Message.where(:communication_channel_id => p.user.email_channel, :notification_id => notification).first.should be_nil
      end
    end
  end

  context "GET 'grades'" do

    it "should not include designers in the teacher enrollments" do
      # teacher needs to be in two courses to get to the point where teacher
      # enrollments are queried
      @course1 = course(:active_all => true)
      @course2 = course(:active_all => true)
      @teacher = user(:active_all => true)
      @designer = user(:active_all => true)
      @course1.enroll_teacher(@teacher).accept!
      @course2.enroll_teacher(@teacher).accept!
      @course2.enroll_designer(@designer).accept!

      user_session(@teacher)
      get 'grades', :course_id => @course.id
      response.should be_success

      teacher_enrollments = assigns[:presenter].teacher_enrollments
      teacher_enrollments.should_not be_nil
      teachers = teacher_enrollments.map{ |e| e.user }
      teachers.should be_include(@teacher)
      teachers.should_not be_include(@designer)
    end

    it "should not redirect to an observer enrollment with no observee" do
      @course1 = course(:active_all => true)
      @course2 = course(:active_all => true)
      @user = user(:active_all => true)
      @course1.enroll_user(@user, 'ObserverEnrollment').accept!
      @course2.enroll_student(@user).accept!

      user_session(@user)
      get 'grades'
      response.should redirect_to course_grades_url(@course2)
    end

    it "should not include student view students in the grade average calculation" do
      course_with_teacher_logged_in(:active_all => true)
      course_with_teacher(:active_all => true, :user => @teacher)
      @s1 = student_in_course(:active_user => true).user
      @s2 = student_in_course(:active_user => true).user
      @test_student = @course.student_view_student
      @assignment = assignment_model(:course => @course, :points_possible => 5)
      @assignment.grade_student(@s1, :grade => 3)
      @assignment.grade_student(@s2, :grade => 4)
      @assignment.grade_student(@test_student, :grade => 5)
      run_transaction_commit_callbacks

      get 'grades'
      assigns[:presenter].course_grade_summaries[@course.id].should == { :score => 70, :students => 2 }
    end

    context 'across shards' do
      specs_require_sharding

      it 'loads courses from all shards' do
        course_with_teacher_logged_in :active_all => true
        @shard1.activate do
          account = Account.create!
          course = account.courses.create!
          @e2 = course.enroll_teacher(@teacher)
          @e2.update_attribute(:workflow_state, 'active')
        end

        get 'grades'
        response.should be_success
        enrollments = assigns[:presenter].teacher_enrollments
        enrollments.should include(@e2)
      end

    end
  end

  describe "GET 'avatar_image'" do
    it "should redirect to no-pic if avatars are disabled" do
      course_with_student_logged_in(:active_all => true)
      get 'avatar_image', :user_id  => @user.id
      response.should redirect_to 'http://test.host/images/no_pic.gif'
    end
    it "should handle passing an absolute fallback if avatars are disabled" do
      course_with_student_logged_in(:active_all => true)
      get 'avatar_image', :user_id  => @user.id, :fallback => "http://foo.com/my/custom/fallback/url.png"
      response.should redirect_to 'http://foo.com/my/custom/fallback/url.png'
    end
    it "should handle passing an absolute fallback if avatars are enabled" do
      course_with_student_logged_in(:active_all => true)
      @account = Account.default
      @account.enable_service(:avatars)
      @account.settings[:avatars] = 'enabled_pending'
      @account.save!
      @account.service_enabled?(:avatars).should be_true
      get 'avatar_image', :user_id  => @user.id, :fallback => "http://foo.com/my/custom/fallback/url.png"
      response.should redirect_to 'http://foo.com/my/custom/fallback/url.png'
    end
    it "should redirect to avatar silhouette if no avatar is set and avatars are enabled" do
      course_with_student_logged_in(:active_all => true)
      @account = Account.default
      @account.enable_service(:avatars)
      @account.settings[:avatars] = 'enabled_pending'
      @account.save!
      @account.service_enabled?(:avatars).should be_true
      get 'avatar_image', :user_id  => @user.id
      response.should redirect_to '/images/messages/avatar-50.png'
    end
    it "should handle passing a host-relative fallback" do
      course_with_student_logged_in(:active_all => true)
      get 'avatar_image', :user_id  => @user.id, :fallback => "/my/custom/fallback/url.png"
      response.should redirect_to 'http://test.host/my/custom/fallback/url.png'
    end
    it "should pass along the default fallback to gravatar" do
      course_with_student_logged_in(:active_all => true)
      @account = Account.default
      @account.enable_service(:avatars)
      @account.save!
      @account.service_enabled?(:avatars).should be_true
      get 'avatar_image', :user_id  => @user.id
      response.should redirect_to "https://secure.gravatar.com/avatar/000?s=50&d=#{CGI.escape("http://test.host/images/messages/avatar-50.png")}"
    end
    it "should handle passing an absolute fallback when avatars are enabled" do
      course_with_student_logged_in(:active_all => true)
      @account = Account.default
      @account.enable_service(:avatars)
      @account.save!
      @account.service_enabled?(:avatars).should be_true
      get 'avatar_image', :user_id  => @user.id, :fallback => "https://test.domain/my/custom/fallback/url.png"
      response.should redirect_to "https://secure.gravatar.com/avatar/000?s=50&d=#{CGI.escape("https://test.domain/my/custom/fallback/url.png")}"
    end
    it "should handle passing a host-relative fallback when avatars are enabled" do
      course_with_student_logged_in(:active_all => true)
      @account = Account.default
      @account.enable_service(:avatars)
      @account.save!
      @account.service_enabled?(:avatars).should be_true
      get 'avatar_image', :user_id  => @user.id, :fallback => "/my/custom/fallback/url.png"
      response.should redirect_to "https://secure.gravatar.com/avatar/000?s=50&d=#{CGI.escape("http://test.host/my/custom/fallback/url.png")}"
    end
    it "should take an invalid id and return silhouette" do
      @account = Account.default
      @account.enable_service(:avatars)
      @account.save!
      @account.service_enabled?(:avatars).should be_true
      get 'avatar_image', :user_id  => 'a'
      response.should redirect_to 'http://test.host/images/messages/avatar-50.png'
    end
    it "should take an invalid id with a hyphen and return silhouette" do
      @account = Account.default
      @account.enable_service(:avatars)
      @account.save!
      @account.service_enabled?(:avatars).should be_true
      get 'avatar_image', :user_id  => 'a-1'
      response.should redirect_to 'http://test.host/images/messages/avatar-50.png'
    end
  end

  describe "GET 'public_feed.atom'" do
    before(:each) do
      course_with_student(:active_all => true)
      assignment_model(:course => @course)
      @course.discussion_topics.create!(:title => "hi", :message => "blah", :user => @student)
      wiki_page_model(:course => @course)
    end

    it "should require authorization" do
      get 'public_feed', :format => 'atom', :feed_code => @user.feed_code + 'x'
      assigns[:problem].should match /The verification code is invalid/
    end

    it "should include absolute path for rel='self' link" do
      get 'public_feed', :format => 'atom', :feed_code => @user.feed_code
      feed = Atom::Feed.load_feed(response.body) rescue nil
      feed.should_not be_nil
      feed.links.first.rel.should match(/self/)
      feed.links.first.href.should match(/http:\/\//)
    end

    it "should include an author for each entry" do
      get 'public_feed', :format => 'atom', :feed_code => @user.feed_code
      feed = Atom::Feed.load_feed(response.body) rescue nil
      feed.should_not be_nil
      feed.entries.should_not be_empty
      feed.entries.all?{|e| e.authors.present?}.should be_true
    end
  end

  describe "GET 'admin_merge'" do
    let(:account) { Account.create! }

    before do
      account_admin_user
      user_session(@admin)
    end

    describe 'as site admin' do
      before { Account.site_admin.add_user(@admin) }

      it 'warns about merging a user with itself' do
        user = User.create!
        get 'admin_merge', :user_id => user.id, :pending_user_id => user.id
        flash[:error].should == 'You can\'t merge an account with itself.'
      end

      it 'does not issue warning if the users are different' do
        user = User.create!
        other_user = User.create!
        get 'admin_merge', :user_id => user.id, :pending_user_id => other_user.id
        flash[:error].should be_nil
      end
    end

    it "should not allow you to view any user by id" do
      user_with_pseudonym(:account => account)
      get 'admin_merge', :user_id => @admin.id, :pending_user_id => @user.id
      response.should be_success
      assigns[:pending_other_user].should be_nil
    end
  end

  describe "GET 'show'" do
    context "sharding" do
      specs_require_sharding

      it "should include enrollments from all shards" do
        course_with_teacher(:active_all => 1)
        @shard1.activate do
          account = Account.create!
          course = account.courses.create!
          @e2 = course.enroll_teacher(@teacher)
        end
        account_admin_user
        user_session(@admin)

        get 'show', :id => @teacher.id
        response.should be_success
        assigns[:enrollments].sort_by(&:id).should == [@enrollment, @e2]
      end
    end

    it "should respond to JSON request" do
      account = Account.create!
      course_with_student(:active_all => true, :account => account)
      account_admin_user(:account => account)
      user_with_pseudonym(:user => @admin, :account => account)
      user_session(@admin)
      get 'show', :id  => @student.id, :format => 'json'
      response.should be_success
      user = json_parse
      user['name'].should == @student.name
    end
  end
end
