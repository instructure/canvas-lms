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

require File.expand_path(File.dirname(__FILE__) + '/../spec_helper.rb')

describe User do
  
  context "validation" do
    it "should create a new instance given valid attributes" do
      user_model
    end
  end
  
  it "should get the first email from communication_channel" do
    @user = User.create
    @cc1 = mock('CommunicationChannel')
    @cc1.stubs(:path).returns('cc1')
    @cc2 = mock('CommunicationChannel')
    @cc2.stubs(:path).returns('cc2')
    @user.stubs(:communication_channels).returns([@cc1, @cc2])
    @user.stubs(:communication_channel).returns(@cc1)
    @user.communication_channel.should eql(@cc1)
  end
  
  it "should be able to assert a name" do
    @user = User.create
    @user.assert_name(nil)
    @user.name.should eql('User')
    @user.assert_name('david')
    @user.name.should eql('david')
    @user.assert_name('bill')
    @user.name.should eql('bill')
    @user.assert_name(nil)
    @user.name.should eql('bill')
    @user = User.find(@user)
    @user.name.should eql('bill')
  end

  it "should update account associations when a course account changes" do
    account1 = account_model
    account2 = account_model
    course_with_student
    @user.associated_accounts.length.should eql(1)
    @user.associated_accounts.first.should eql(Account.default)
    
    @course.account = account1
    @course.save!
    @course.reload
    @user.reload
    
    @user.associated_accounts.length.should eql(1)
    @user.associated_accounts.first.should eql(account1)
    
    @course.account = account2
    @course.save!
    @user.reload
    
    @user.associated_accounts.length.should eql(1)
    @user.associated_accounts.first.should eql(account2)
  end
  
  it "should update account associations when a course account moves in the hierachy" do
    account1 = account_model
    
    @enrollment = course_with_student(:account => account1)
    @course.account = account1
    @course.save!
    @course.reload
    @user.reload
    
    @user.associated_accounts.length.should eql(1)
    @user.associated_accounts.first.should eql(account1)
    
    account2 = account_model
    account1.parent_account = account2
    account1.save!
    @course.reload
    @user.reload
    
    @user.associated_accounts.length.should eql(2)
    @user.associated_accounts[0].should eql(account1)
    @user.associated_accounts[1].should eql(account2)
  end
  
  it "should update account associations when a user is associated to an account just by pseudonym" do
    account1 = account_model
    account2 = account_model
    user = user_with_pseudonym

    pseudonym = user.pseudonyms.first
    pseudonym.account = account1
    pseudonym.save
    
    user.reload
    user.associated_accounts.length.should eql(1)
    user.associated_accounts.first.should eql(account1)

    # Make sure that multiple sequential updates also work
    pseudonym.account = account2
    pseudonym.save
    pseudonym.account = account1
    pseudonym.save
    user.reload
    user.associated_accounts.length.should eql(1)
    user.associated_accounts.first.should eql(account1)

    account1.parent_account = account2
    account1.save!
    
    user.reload
    user.associated_accounts.length.should eql(2)
    user.associated_accounts[0].should eql(account1)
    user.associated_accounts[1].should eql(account2)
  end

  it "should update account associations when a user is associated to an account just by account_users" do
    account = account_model
    @user = User.create
    account.add_user(@user)

    @user.reload
    @user.associated_accounts.length.should eql(1)
    @user.associated_accounts.first.should eql(account)
  end
  
  it "should populate dashboard_messages" do
    Notification.create(:name => "Assignment Created")
    course_with_teacher(:active_all => true)
    StreamItem.for_user(@user).should be_empty
    @a = @course.assignments.new(:title => "some assignment")
    @a.workflow_state = "available"
    @a.save
    StreamItem.for_user(@user).should_not be_empty
  end

  it "should ignore orphaned stream item instances" do
    course_with_student(:active_all => true)
    google_docs_collaboration_model(:user_id => @user.id)
    @user.recent_stream_items.size.should == 1
    StreamItem.delete_all
    @user.unmemoize_all
    @user.recent_stream_items.size.should == 0
  end

  it "should be able to remove itself from a root account" do
    account1 = Account.create
    account2 = Account.create
    user = User.create
    user.register!
    p1 = user.pseudonyms.create(:unique_id => "user1")
    p2 = user.pseudonyms.create(:unique_id => "user2")
    p1.account = account1
    p2.account = account2
    p1.save!
    p2.save!
    account1.add_user(user)
    account2.add_user(user)
    course1 = account1.courses.create
    course2 = account2.courses.create
    course1.offer!
    course2.offer!
    enrollment1 = course1.enroll_student(user)
    enrollment2 = course2.enroll_student(user)
    enrollment1.workflow_state = 'active'
    enrollment2.workflow_state = 'active'
    enrollment1.save!
    enrollment2.save!
    user.associated_account_ids.include?(account1.id).should be_true
    user.associated_account_ids.include?(account2.id).should be_true
    user.remove_from_root_account(account2)
    user.reload
    user.associated_account_ids.include?(account1.id).should be_true
    user.associated_account_ids.include?(account2.id).should be_false
  end

  it "should search by multiple fields" do
    @account = Account.create!
    user1 = User.create! :name => "longname1", :short_name => "shortname1"
    user1.register!
    user2 = User.create! :name => "longname2", :short_name => "shortname2"
    user2.register!

    User.name_like("longname1").map(&:id).should == [user1.id]
    User.name_like("shortname2").map(&:id).should == [user2.id]
    User.name_like("sisid1").map(&:id).should == []
    User.name_like("uniqueid2").map(&:id).should == []

    p1 = user1.pseudonyms.new :unique_id => "uniqueid1", :account => @account
    p1.sis_user_id = "sisid1"
    p1.save!
    p2 = user2.pseudonyms.new :unique_id => "uniqueid2", :account => @account
    p2.sis_user_id = "sisid2"
    p2.save!

    User.name_like("longname1").map(&:id).should == [user1.id]
    User.name_like("shortname2").map(&:id).should == [user2.id]
    User.name_like("sisid1").map(&:id).should == [user1.id]
    User.name_like("uniqueid2").map(&:id).should == [user2.id]

    p3 = user1.pseudonyms.new :unique_id => "uniqueid3", :account => @account
    p3.sis_user_id = "sisid3"
    p3.save!
    
    User.name_like("longname1").map(&:id).should == [user1.id]
    User.name_like("shortname2").map(&:id).should == [user2.id]
    User.name_like("sisid1").map(&:id).should == [user1.id]
    User.name_like("uniqueid2").map(&:id).should == [user2.id]
    User.name_like("uniqueid3").map(&:id).should == [user1.id]

    p4 = user1.pseudonyms.new :unique_id => "uniqueid4", :account => @account
    p4.sis_user_id = "sisid3 2"
    p4.save!

    User.name_like("longname1").map(&:id).should == [user1.id]
    User.name_like("shortname2").map(&:id).should == [user2.id]
    User.name_like("sisid1").map(&:id).should == [user1.id]
    User.name_like("uniqueid2").map(&:id).should == [user2.id]
    User.name_like("uniqueid3").map(&:id).should == [user1.id]
    User.name_like("sisid3").map(&:id).should == [user1.id]

    user3 = User.create! :name => "longname1", :short_name => "shortname3"
    user3.register!
    
    User.name_like("longname1").map(&:id).sort.should == [user1.id, user3.id].sort
    User.name_like("shortname2").map(&:id).should == [user2.id]
    User.name_like("sisid1").map(&:id).should == [user1.id]
    User.name_like("uniqueid2").map(&:id).should == [user2.id]
    User.name_like("uniqueid3").map(&:id).should == [user1.id]
    User.name_like("sisid3").map(&:id).should == [user1.id]

    User.name_like("sisid3").map(&:id).should == [user1.id]
    User.name_like("uniqueid4").map(&:id).should == [user1.id]
    p4.destroy
    User.name_like("sisid3").map(&:id).should == [user1.id]
    User.name_like("uniqueid4").map(&:id).should == []

  end

  it "should be able to be removed from a root account with non-Canvas auth" do
    account1 = account_with_cas
    account2 = Account.create!
    user = User.create!
    user.register!
    p1 = user.pseudonyms.new :unique_id => "id1", :account => account1
    p1.sis_user_id = 'sis_id1'
    p1.save!
    user.pseudonyms.create! :unique_id => "id2", :account => account2
    lambda { p1.destroy }.should raise_error /Cannot delete system-generated pseudonyms/
    user.remove_from_root_account account1
    user.associated_root_accounts.should eql [account2]
  end

  it "should support incrementally adding to account associations" do
    user = User.create!
    user.user_account_associations.should == []
    account1, account2, account3 = Account.create!, Account.create!, Account.create!

    sort_account_associations = lambda { |a, b| a.keys.first <=> b.keys.first }

    User.update_account_associations([user], :incremental => true, :precalculated_associations => {account1.id => 0})
    user.user_account_associations.reload.map { |aa| {aa.account_id => aa.depth} }.should == [{account1.id => 0}]

    User.update_account_associations([user], :incremental => true, :precalculated_associations => {account2.id => 1})
    user.user_account_associations.reload.map { |aa| {aa.account_id => aa.depth} }.sort(&sort_account_associations).should == [{account1.id => 0}, {account2.id => 1}].sort(&sort_account_associations)

    User.update_account_associations([user], :incremental => true, :precalculated_associations => {account3.id => 1, account1.id => 2, account2.id => 0})
    user.user_account_associations.reload.map { |aa| {aa.account_id => aa.depth} }.sort(&sort_account_associations).should == [{account1.id => 0}, {account2.id => 0}, {account3.id => 1}].sort(&sort_account_associations)
  end

  it "should not have account associations for creation_pending or deleted" do
    user = User.create! { |u| u.workflow_state = 'creation_pending' }
    user.should be_creation_pending
    course = Course.create!
    course.offer!
    enrollment = course.enroll_student(user)
    enrollment.should be_invited
    user.user_account_associations.should == []
    Account.default.add_user(user)
    user.user_account_associations(true).should == []
    user.pseudonyms.create!(:unique_id => 'test@example.com')
    user.user_account_associations(true).should == []
    user.update_account_associations
    user.user_account_associations(true).should == []
    user.register!
    user.user_account_associations(true).map(&:account).should == [Account.default]
    user.destroy
    user.user_account_associations(true).should == []
  end

  it "should not create/update account associations for student view student" do
    account1 = account_model
    account2 = account_model
    course_with_teacher(:active_all => true)
    @fake_student = @course.student_view_student
    @fake_student.reload.user_account_associations.should be_empty

    @course.account_id = account1.id
    @course.save!
    @fake_student.reload.user_account_associations.should be_empty

    account1.parent_account = account2
    account1.save!
    @fake_student.reload.user_account_associations.should be_empty

    @course.complete!
    @fake_student.reload.user_account_associations.should be_empty

    @fake_student = @course.reload.student_view_student
    @fake_student.reload.user_account_associations.should be_empty

    @section2 = @course.course_sections.create!(:name => "Other Section")
    @fake_student = @course.reload.student_view_student
    @fake_student.reload.user_account_associations.should be_empty
  end

  def create_course_with_student_and_assignment
    @course = course_model
    @course.offer!
    @student = user_model
    @course.enroll_student @student
    @assignment = @course.assignments.create :title => "Test Assignment", :points_possible => 10
  end

  it "should not include recent feedback for muted assignments" do
    create_course_with_student_and_assignment
    @assignment.mute!
    @assignment.grade_student @student, :grade => 9
    @user.recent_feedback.should be_empty
  end

  it "should include recent feedback for unmuted assignments" do
    create_course_with_student_and_assignment
    @assignment.grade_student @user, :grade => 9
    @user.recent_feedback(:contexts => [@course]).should_not be_empty
  end

  it "should return appropriate courses with primary enrollment" do
    user
    @course1 = course(:course_name => "course", :active_course => true)
    @course1.enroll_user(@user, 'StudentEnrollment', :enrollment_state => 'active')

    @course2 = course(:course_name => "other course", :active_course => true)
    @course2.enroll_user(@user, 'TeacherEnrollment', :enrollment_state => 'active')

    @course3 = course(:course_name => "yet another course", :active_course => true)
    @course3.enroll_user(@user, 'StudentEnrollment', :enrollment_state => 'active')
    @course3.enroll_user(@user, 'TeacherEnrollment', :enrollment_state => 'active')

    @course4 = course(:course_name => "not yet active")
    @course4.enroll_user(@user, 'StudentEnrollment')

    @course5 = course(:course_name => "invited")
    @course5.enroll_user(@user, 'TeacherEnrollment')

    @course6 = course(:course_name => "active but date restricted", :active_course => true)
    e = @course6.enroll_user(@user, 'StudentEnrollment')
    e.accept!
    e.start_at = 1.day.from_now
    e.end_at = 2.days.from_now
    e.save!

    @course7 = course(:course_name => "soft concluded", :active_course => true)
    e = @course7.enroll_user(@user, 'StudentEnrollment')
    e.accept!
    e.start_at = 2.days.ago
    e.end_at = 1.day.ago
    e.save!


    # only four, in the right order (type, then name), and with the top type per course
    @user.courses_with_primary_enrollment.map{|c| [c.id, c.primary_enrollment]}.should eql [
      [@course5.id, 'TeacherEnrollment'],
      [@course2.id, 'TeacherEnrollment'],
      [@course3.id, 'TeacherEnrollment'],
      [@course1.id, 'StudentEnrollment']
    ]
  end

  it "should delete the user transactionally in case the pseudonym removal fails" do
    user_with_managed_pseudonym
    @pseudonym.should be_managed_password
    @user.workflow_state.should == "pre_registered"
    lambda { @user.destroy }.should raise_error("Cannot delete system-generated pseudonyms")
    @user.workflow_state.should == "deleted"
    @user.reload
    @user.workflow_state.should == "pre_registered"
    @account.account_authorization_config.destroy
    @pseudonym.should_not be_managed_password
    @user.destroy
    @user.workflow_state.should == "deleted"
    @user.reload
    @user.workflow_state.should == "deleted"
    user_with_managed_pseudonym
    @pseudonym.should be_managed_password
    @user.workflow_state.should == "pre_registered"
    @user.destroy(true)
    @user.workflow_state.should == "deleted"
    @user.reload
    @user.workflow_state.should == "deleted"
  end

  context "move_to_user" do
    it "should delete the old user" do
      @user1 = user_model
      @user2 = user_model
      @user2.move_to_user(@user1)
      @user1.reload
      @user2.reload
      @user1.should_not be_deleted
      @user2.should be_deleted
    end
    
    it "should move pseudonyms to the new user" do
      @user1 = user_model
      @user2 = user_model
      @user2.pseudonyms.create!(:unique_id => 'sam@yahoo.com')
      @user2.move_to_user(@user1)
      @user2.reload
      @user2.pseudonyms.should be_empty
      @user1.reload
      @user1.pseudonyms.map(&:unique_id).should be_include('sam@yahoo.com')
    end
    
    it "should move submissions to the new user (but only if they don't already exist)" do
      @user1 = user_model
      @user2 = user_model
      @a1 = assignment_model
      s1 = @a1.find_or_create_submission(@user1)
      s2 = @a1.find_or_create_submission(@user2)
      @a2 = assignment_model
      s3 = @a2.find_or_create_submission(@user2)
      @user2.submissions.length.should eql(2)
      @user1.submissions.length.should eql(1)
      @user2.move_to_user(@user1)
      @user2.reload
      @user1.reload
      @user2.submissions.length.should eql(1)
      @user2.submissions.first.id.should eql(s2.id)
      @user1.submissions.length.should eql(2)
      @user1.submissions.map(&:id).should be_include(s1.id)
      @user1.submissions.map(&:id).should be_include(s3.id)
    end

    it "should move ccs to the new user (but only if they don't already exist)" do
      @user1 = user_model
      @user2 = user_model
      # unconfirmed => active conflict
      @user1.communication_channels.create!(:path => 'a@instructure.com')
      @user2.communication_channels.create!(:path => 'A@instructure.com') { |cc| cc.workflow_state = 'active' }
      # active => unconfirmed conflict
      @user1.communication_channels.create!(:path => 'b@instructure.com') { |cc| cc.workflow_state = 'active' }
      @user2.communication_channels.create!(:path => 'B@instructure.com')
      # active => active conflict
      @user1.communication_channels.create!(:path => 'c@instructure.com') { |cc| cc.workflow_state = 'active' }
      @user2.communication_channels.create!(:path => 'C@instructure.com') { |cc| cc.workflow_state = 'active' }
      # unconfirmed => unconfirmed conflict
      @user1.communication_channels.create!(:path => 'd@instructure.com')
      @user2.communication_channels.create!(:path => 'D@instructure.com')
      # retired => unconfirmed conflict
      @user1.communication_channels.create!(:path => 'e@instructure.com') { |cc| cc.workflow_state = 'retired' }
      @user2.communication_channels.create!(:path => 'E@instructure.com')
      # unconfirmed => retired conflict
      @user1.communication_channels.create!(:path => 'f@instructure.com')
      @user2.communication_channels.create!(:path => 'F@instructure.com') { |cc| cc.workflow_state = 'retired' }
      # retired => active conflict
      @user1.communication_channels.create!(:path => 'g@instructure.com') { |cc| cc.workflow_state = 'retired' }
      @user2.communication_channels.create!(:path => 'G@instructure.com') { |cc| cc.workflow_state = 'active' }
      # active => retired conflict
      @user1.communication_channels.create!(:path => 'h@instructure.com') { |cc| cc.workflow_state = 'active' }
      @user2.communication_channels.create!(:path => 'H@instructure.com') { |cc| cc.workflow_state = 'retired' }
      # retired => retired conflict
      @user1.communication_channels.create!(:path => 'i@instructure.com') { |cc| cc.workflow_state = 'retired' }
      @user2.communication_channels.create!(:path => 'I@instructure.com') { |cc| cc.workflow_state = 'retired' }
      # <nothing> => active
      @user2.communication_channels.create!(:path => 'j@instructure.com') { |cc| cc.workflow_state = 'active' }
      # active => <nothing>
      @user1.communication_channels.create!(:path => 'k@instructure.com') { |cc| cc.workflow_state = 'active' }
      # <nothing> => unconfirmed
      @user2.communication_channels.create!(:path => 'l@instructure.com')
      # unconfirmed => <nothing>
      @user1.communication_channels.create!(:path => 'm@instructure.com')
      # <nothing> => retired
      @user2.communication_channels.create!(:path => 'n@instructure.com') { |cc| cc.workflow_state = 'retired' }
      # retired => <nothing>
      @user1.communication_channels.create!(:path => 'o@instructure.com') { |cc| cc.workflow_state = 'retired' }

      @user1.move_to_user(@user2)
      @user1.reload
      @user2.reload
      @user2.communication_channels.map { |cc| [cc.path, cc.workflow_state] }.sort.should == [
          ['A@instructure.com', 'active'],
          ['B@instructure.com', 'retired'],
          ['C@instructure.com', 'active'],
          ['D@instructure.com', 'unconfirmed'],
          ['E@instructure.com', 'unconfirmed'],
          ['F@instructure.com', 'retired'],
          ['G@instructure.com', 'active'],
          ['H@instructure.com', 'retired'],
          ['I@instructure.com', 'retired'],
          ['a@instructure.com', 'retired'],
          ['b@instructure.com', 'active'],
          ['c@instructure.com', 'retired'],
          ['d@instructure.com', 'retired'],
          ['e@instructure.com', 'retired'],
          ['f@instructure.com', 'unconfirmed'],
          ['g@instructure.com', 'retired'],
          ['h@instructure.com', 'active'],
          ['i@instructure.com', 'retired'],
          ['j@instructure.com', 'active'],
          ['k@instructure.com', 'active'],
          ['l@instructure.com', 'unconfirmed'],
          ['m@instructure.com', 'unconfirmed'],
          ['n@instructure.com', 'retired'],
          ['o@instructure.com', 'retired']
      ]
      @user1.communication_channels.should be_empty
    end

    it "should move and uniquify enrollments" do
      @user1 = user_model
      @user2 = user_model
      course(:active_all => 1)
      @enrollment1 = @course.enroll_user(@user1)
      @enrollment2 = @course.enroll_user(@user2, 'StudentEnrollment', :enrollment_state => 'active')
      @enrollment3 = StudentEnrollment.create!(:course => @course, :course_section => @course.course_sections.create!, :user => @user1)
      @enrollment4 = @course.enroll_teacher(@user1)

      @user1.move_to_user(@user2)
      @enrollment1.reload
      @enrollment1.user.should == @user2
      @enrollment1.should be_deleted
      @enrollment2.reload
      @enrollment2.should be_active
      @enrollment2.user.should == @user2
      @enrollment3.reload
      @enrollment3.should be_invited
      @enrollment4.reload
      @enrollment4.user.should == @user2
      @enrollment4.should be_invited

      @user1.reload
      @user1.enrollments.should be_empty
    end

    it "should move and uniquify observee enrollments" do
      @user1 = user_model
      @course1 = course(:active_all => 1)
      @enrollment1 = @course1.enroll_user(@user1)
      @user2 = user_model
      @course2 = course(:active_all => 1)
      @enrollment2 = @course1.enroll_user(@user2)

      @observer1 = user_model
      @observer2 = user_model
      @user1.observers << @observer1 << @observer2
      @user2.observers << @observer2
      ObserverEnrollment.count.should eql 3

      @user1.move_to_user(@user2)

      @user1.observee_enrollments.should be_empty
      @user2.observee_enrollments.size.should eql 3 # 1 deleted
      @user2.observee_enrollments.active_or_pending.size.should eql 2
      @observer1.observer_enrollments.active_or_pending.size.should eql 1
      @observer2.observer_enrollments.active_or_pending.size.should eql 1
    end

    it "should move and uniquify observers" do
      @user1 = user_model
      @user2 = user_model
      @observer1 = user_model
      @observer2 = user_model
      @user1.observers << @observer1 << @observer2
      @user2.observers << @observer2

      @user1.move_to_user(@user2)

      @user1.reload
      @user1.observers.should be_empty
      @user2.reload
      @user2.observers.sort_by(&:id).should eql [@observer1, @observer2]
    end

    it "should move and uniquify observed users" do
      @user1 = user_model
      @user2 = user_model
      @student1 = user_model
      @student2 = user_model
      @user1.observed_users << @student1 << @student2
      @user2.observed_users << @student2

      @user1.move_to_user(@user2)

      @user1.reload
      @user1.observed_users.should be_empty
      @user2.reload
      @user2.observed_users.sort_by(&:id).should eql [@student1, @student2]
    end

    it "should update account associations" do
      @account1 = account_model
      @account2 = account_model
      @pseudo1 = (@user1 = user_with_pseudonym :account => @account1).pseudonym
      @pseudo2 = (@user2 = user_with_pseudonym :account => @account2).pseudonym
      @subsubaccount1 = (@subaccount1 = @account1.sub_accounts.create!).sub_accounts.create!
      @subsubaccount2 = (@subaccount2 = @account2.sub_accounts.create!).sub_accounts.create!
      course_with_student(:account => @subsubaccount1, :user => @user1)
      course_with_student(:account => @subsubaccount2, :user => @user2)

      @user1.associated_accounts.map(&:id).sort.should == [@account1, @subaccount1, @subsubaccount1].map(&:id).sort
      @user2.associated_accounts.map(&:id).sort.should == [@account2, @subaccount2, @subsubaccount2].map(&:id).sort

      @pseudo1.user.should == @user1
      @pseudo2.user.should == @user2

      @user1.move_to_user @user2

      @pseudo1, @pseudo2 = [@pseudo1, @pseudo2].map{|p| Pseudonym.find(p.id)}
      @user1, @user2 = [@user1, @user2].map{|u| User.find(u.id)}

      @pseudo1.user.should == @pseudo2.user
      @pseudo1.user.should == @user2

      @user1.associated_accounts.map(&:id).sort.should == []
      @user2.associated_accounts.map(&:id).sort.should == [@account1, @account2, @subaccount1, @subaccount2, @subsubaccount1, @subsubaccount2].map(&:id).sort
    end

    it "should move conversations to the new user" do
      @user1 = user_model
      @user2 = user_model
      c1 = @user1.initiate_conversation([user.id, user.id]) # group conversation
      c1.add_message("hello")
      c1.update_attribute(:workflow_state, 'unread')
      c2 = @user1.initiate_conversation([user.id]) # private conversation
      c2.add_message("hello")
      c2.update_attribute(:workflow_state, 'unread')
      old_private_hash = c2.conversation.private_hash

      @user1.move_to_user @user2

      c1.reload.user_id.should eql @user2.id
      c1.conversation.participant_ids.should_not include(@user1.id)
      @user1.reload.unread_conversations_count.should eql 0

      c2.reload.user_id.should eql @user2.id
      c2.conversation.participant_ids.should_not include(@user1.id)
      c2.conversation.private_hash.should_not eql old_private_hash
      @user2.reload.unread_conversations_count.should eql 2
    end

    it "should point other user's observers to the new user" do
      @user1 = user_model
      @user2 = user_model
      @observer = user_model
      course
      @course.enroll_student(@user1)
      @oe = @course.enroll_user(@observer, 'ObserverEnrollment')
      @oe.update_attribute(:associated_user_id, @user1.id)
      @user1.move_to_user(@user2)
      @oe.reload.associated_user_id.should == @user2.id
    end
  end

  describe "can_masquerade?" do
    it "should allow self" do
      @user = user_with_pseudonym(:username => 'nobody1@example.com')
      @user.can_masquerade?(@user, Account.default).should be_true
    end

    it "should not allow other users" do
      @user1 = user_with_pseudonym(:username => 'nobody1@example.com')
      @user2 = user_with_pseudonym(:username => 'nobody2@example.com')

      @user1.can_masquerade?(@user2, Account.default).should be_false
      @user2.can_masquerade?(@user1, Account.default).should be_false
    end

    it "should allow site and account admins" do
      user = user_with_pseudonym(:username => 'nobody1@example.com')
      @admin = user_with_pseudonym(:username => 'nobody2@example.com')
      @site_admin = user_with_pseudonym(:username => 'nobody3@example.com', :account => Account.site_admin)
      Account.site_admin.add_user(@site_admin)
      Account.default.add_user(@admin)
      user.can_masquerade?(@site_admin, Account.default).should be_true
      @admin.can_masquerade?(@site_admin, Account.default).should be_true
      user.can_masquerade?(@admin, Account.default).should be_true
      @admin.can_masquerade?(@admin, Account.default).should be_true
      @admin.can_masquerade?(user, Account.default).should be_false
      @site_admin.can_masquerade?(@site_admin, Account.default).should be_true
      @site_admin.can_masquerade?(user, Account.default).should be_false
      @site_admin.can_masquerade?(@admin, Account.default).should be_false
    end

    it "should not allow restricted admins to become full admins" do
      user = user_with_pseudonym(:username => 'nobody1@example.com')
      @restricted_admin = user_with_pseudonym(:username => 'nobody3@example.com')
      account_admin_user_with_role_changes(:user => @restricted_admin, :membership_type => 'Restricted', :role_changes => { :become_user => true })
      @admin = user_with_pseudonym(:username => 'nobody2@example.com')
      Account.default.add_user(@admin)
      user.can_masquerade?(@restricted_admin, Account.default).should be_true
      @admin.can_masquerade?(@restricted_admin, Account.default).should be_false
      @restricted_admin.can_masquerade?(@admin, Account.default).should be_true
    end

    it "should allow to admin even if user is in multiple accounts" do
      user = user_with_pseudonym(:username => 'nobody1@example.com')
      @account2 = Account.create!
      user.pseudonyms.create!(:unique_id => 'nobodyelse@example.com', :account => @account2)
      @admin = user_with_pseudonym(:username => 'nobody2@example.com')
      @site_admin = user_with_pseudonym(:username => 'nobody3@example.com')
      Account.default.add_user(@admin)
      Account.site_admin.add_user(@site_admin)
      user.can_masquerade?(@admin, Account.default).should be_true
      user.can_masquerade?(@admin, @account2).should be_false
      user.can_masquerade?(@site_admin, Account.default).should be_true
      user.can_masquerade?(@site_admin, @account2).should be_true
      @account2.add_user(@admin)
    end

    it "should allow site admin when they don't otherwise qualify for :create_courses" do
      user = user_with_pseudonym(:username => 'nobody1@example.com')
      @admin = user_with_pseudonym(:username => 'nobody2@example.com')
      @site_admin = user_with_pseudonym(:username => 'nobody3@example.com', :account => Account.site_admin)
      Account.default.add_user(@admin)
      Account.site_admin.add_user(@site_admin)
      course
      @course.enroll_teacher(@admin)
      Account.default.update_attribute(:settings, {:teachers_can_create_courses => true})
      @admin.can_masquerade?(@site_admin, Account.default).should be_true
    end

    it "should allow teacher to become student view student" do
      course_with_teacher(:active_all => true)
      @fake_student = @course.student_view_student
      @fake_student.can_masquerade?(@teacher, Account.default).should be_true
    end
  end

  context "permissions" do
    it "should not allow account admin to modify admin privileges of other account admins" do
      RoleOverride.readonly_for(Account.default, :manage_role_overrides, 'AccountAdmin').should be_true
      RoleOverride.readonly_for(Account.default, :manage_account_memberships, 'AccountAdmin').should be_true
      RoleOverride.readonly_for(Account.default, :manage_account_settings, 'AccountAdmin').should be_true
    end
  end

  context "messageable_users" do
    before(:each) do
      @admin = user_model
      @student = user_model
      tie_user_to_account(@admin, :membership_type => 'AccountAdmin')
      tie_user_to_account(@student, :membership_type => 'Student')
    end

    def set_up_course_with_users
      @course = course_model(:name => 'the course')
      @this_section_teacher = @teacher
      @course.offer!

      @this_section_user = user_model
      @this_section_user_enrollment = @course.enroll_user(@this_section_user, 'StudentEnrollment', :enrollment_state => 'active')

      @other_section_user = user_model
      @other_section = @course.course_sections.create
      @course.enroll_user(@other_section_user, 'StudentEnrollment', :enrollment_state => 'active', :section => @other_section)
      @other_section_teacher = user_model
      @course.enroll_user(@other_section_teacher, 'TeacherEnrollment', :enrollment_state => 'active', :section => @other_section)

      @group = @course.groups.create(:name => 'the group')
      @group.users = [@this_section_user]

      @unrelated_user = user_model

      @deleted_user = user_model(:name => 'deleted')
      @course.enroll_user(@deleted_user, 'StudentEnrollment', :enrollment_state => 'active')
      @deleted_user.destroy
    end

    it "should only return users from the specified context and type" do
      set_up_course_with_users
      @course.enroll_user(@student, 'StudentEnrollment', :enrollment_state => 'active')

      @student.messageable_users(:context => "course_#{@course.id}").map(&:id).sort.
        should eql [@student, @this_section_user, @this_section_teacher, @other_section_user, @other_section_teacher].map(&:id).sort
      @student.enrollment_visibility[:user_counts][@course.id].should eql 5

      @student.messageable_users(:context => "course_#{@course.id}_students").map(&:id).sort.
        should eql [@student, @this_section_user, @other_section_user].map(&:id).sort

      @student.messageable_users(:context => "group_#{@group.id}").map(&:id).sort.
        should eql [@this_section_user].map(&:id).sort
      @student.group_membership_visibility[:user_counts][@group.id].should eql 1

      @student.messageable_users(:context => "section_#{@other_section.id}").map(&:id).sort.
        should eql [@other_section_user, @other_section_teacher].map(&:id).sort

      @student.messageable_users(:context => "section_#{@other_section.id}_teachers").map(&:id).sort.
        should eql [@other_section_teacher].map(&:id).sort
    end

    it "should not include users from other sections if visibility is limited to sections" do
      set_up_course_with_users
      enrollment = @course.enroll_user(@student, 'StudentEnrollment', :enrollment_state => 'active', :limit_privileges_to_course_section => true)
      # we currently force limit_privileges_to_course_section to be false for students; override it in the db
      Enrollment.update_all({ :limit_privileges_to_course_section => true }, :id => enrollment.id)
      messageable_users = @student.messageable_users.map(&:id)
      messageable_users.should include @this_section_user.id
      messageable_users.should_not include @other_section_user.id

      messageable_users = @student.messageable_users(:context => "course_#{@course.id}").map(&:id)
      messageable_users.should include @this_section_user.id
      messageable_users.should_not include @other_section_user.id

      messageable_users = @student.messageable_users(:context => "section_#{@other_section.id}").map(&:id)
      messageable_users.should be_empty
    end

    it "should not include deleted users" do
      set_up_course_with_users
      @student.messageable_users.map(&:id).should_not include(@deleted_user.id)
      @student.messageable_users(:search => @deleted_user.name).map(&:id).should be_empty
      @student.messageable_users(:ids => [@deleted_user.id]).map(&:id).should be_empty
      @student.messageable_users(:skip_visibility_checks => true).map(&:id).should_not include(@deleted_user.id)
      @student.messageable_users(:skip_visibility_checks => true, :search => @deleted_user.name).map(&:id).should be_empty
    end

    it "should include deleted iff skip_visibility_checks=true && ids are given" do
      set_up_course_with_users
      @student.messageable_users(:skip_visibility_checks => true, :ids => [@deleted_user.id]).map(&:id).should == [@deleted_user.id]
    end

    it "should only include users from the specified section" do
      set_up_course_with_users
      @course.enroll_user(@student, 'StudentEnrollment', :enrollment_state => 'active')
      messageable_users = @student.messageable_users(:context => "section_#{@course.default_section.id}").map(&:id)
      messageable_users.should include @this_section_user.id
      messageable_users.should_not include @other_section_user.id

      messageable_users = @student.messageable_users(:context => "section_#{@other_section.id}").map(&:id)
      messageable_users.should_not include @this_section_user.id
      messageable_users.should include @other_section_user.id
    end

    it "should include users from all sections if visibility is not limited to sections" do
      set_up_course_with_users
      @course.enroll_user(@student, 'StudentEnrollment', :enrollment_state => 'active')
      messageable_users = @student.messageable_users.map(&:id)
      messageable_users.should include @this_section_user.id
      messageable_users.should include @other_section_user.id
    end

    it "should return users for a specified group if the receiver can access the group" do
      set_up_course_with_users
      @course.enroll_user(@student, 'StudentEnrollment', :enrollment_state => 'active')

      @this_section_user.messageable_users(:context => "group_#{@group.id}").map(&:id).should eql [@this_section_user.id]
      # student can see it too, even though he's not in the group (since he can view the roster)
      @student.messageable_users(:context => "group_#{@group.id}").map(&:id).should eql [@this_section_user.id]
    end

    it "should respect section visibility when returning users for a specified group" do
      set_up_course_with_users
      enrollment = @course.enroll_user(@student, 'StudentEnrollment', :enrollment_state => 'active', :limit_privileges_to_course_section => true)
      # we currently force limit_privileges_to_course_section to be false for students; override it in the db
      Enrollment.update_all({ :limit_privileges_to_course_section => true }, :id => enrollment.id)

      @group.users << @other_section_user

      @this_section_user.messageable_users(:context => "group_#{@group.id}").map(&:id).sort.should eql [@this_section_user.id, @other_section_user.id]
      @this_section_user.group_membership_visibility[:user_counts][@group.id].should eql 2
      # student can only see people in his section
      @student.messageable_users(:context => "group_#{@group.id}").map(&:id).should eql [@this_section_user.id]
      @student.group_membership_visibility[:user_counts][@group.id].should eql 1
    end

    it "should only show admins and the observed if the receiver is an observer" do
      set_up_course_with_users
      @course.enroll_user(@admin, 'TeacherEnrollment', :enrollment_state => 'active')
      @course.enroll_user(@student, 'StudentEnrollment', :enrollment_state => 'active')

      observer = user_model

      enrollment = @course.enroll_user(observer, 'ObserverEnrollment', :enrollment_state => 'active')
      enrollment.associated_user_id = @student.id
      enrollment.save

      messageable_users = observer.messageable_users.map(&:id)
      messageable_users.should include @admin.id
      messageable_users.should include @student.id
      messageable_users.should_not include @this_section_user.id
      messageable_users.should_not include @other_section_user.id
    end

    it "should not show non-linked observers to students" do
      set_up_course_with_users
      @course.enroll_user(@admin, 'TeacherEnrollment', :enrollment_state => 'active')
      student1, student2 = user_model, user_model
      @course.enroll_user(student1, 'StudentEnrollment', :enrollment_state => 'active')
      @course.enroll_user(student2, 'StudentEnrollment', :enrollment_state => 'active')

      observer = user_model
      enrollment = @course.enroll_user(observer, 'ObserverEnrollment', :enrollment_state => 'active')
      enrollment.associated_user_id = student1.id
      enrollment.save

      student1.messageable_users.map(&:id).should include observer.id
      student1.enrollment_visibility[:user_counts][@course.id].should eql 8
      student2.messageable_users.map(&:id).should_not include observer.id
      student2.enrollment_visibility[:user_counts][@course.id].should eql 7
    end

    it "should include all shared contexts and enrollment information" do
      set_up_course_with_users
      @first_course = @course
      @first_course.enroll_user(@this_section_user, 'TaEnrollment', :enrollment_state => 'active')
      @first_course.enroll_user(@admin, 'TeacherEnrollment', :enrollment_state => 'active')

      @other_course = course_model
      @other_course.offer!
      @other_course.enroll_user(@admin, 'TeacherEnrollment', :enrollment_state => 'active')
      # other_section_user is a teacher in one course, student in another
      @other_course.enroll_user(@other_section_user, 'TeacherEnrollment', :enrollment_state => 'active')

      messageable_users = @admin.messageable_users
      this_section_user = messageable_users.detect{|u| u.id == @this_section_user.id}
      this_section_user.common_courses.keys.should include @first_course.id
      this_section_user.common_courses[@first_course.id].sort.should eql ['StudentEnrollment', 'TaEnrollment']

      two_context_guy = messageable_users.detect{|u| u.id == @other_section_user.id}
      two_context_guy.common_courses.keys.should include @first_course.id
      two_context_guy.common_courses[@first_course.id].sort.should eql ['StudentEnrollment']
      two_context_guy.common_courses.keys.should include @other_course.id
      two_context_guy.common_courses[@other_course.id].sort.should eql ['TeacherEnrollment']
    end

    it "should include users with no shared contexts iff admin" do
      @admin.messageable_users(:ids => [@student.id]).should_not be_empty
      @student.messageable_users(:ids => [@admin.id]).should be_empty
    end

    it "should not do admin catch-all if specific contexts requested" do
      course1 = course_model
      course2 = course_model
      course2.offer!

      enrollment = course2.enroll_teacher(@admin)
      enrollment.workflow_state = 'active'
      enrollment.save
      @admin.reload

      enrollment = course2.enroll_student(@student)
      enrollment.workflow_state = 'active'
      enrollment.save

      @admin.messageable_users(:context => "course_#{course1.id}", :ids => [@student.id]).should be_empty
      @admin.messageable_users(:context => "course_#{course2.id}", :ids => [@student.id]).should_not be_empty
      @student.messageable_users(:context => "course_#{course2.id}", :ids => [@admin.id]).should_not be_empty
    end

    it "should return names with shared contexts" do
      set_up_course_with_users
      @course.enroll_user(@student, 'StudentEnrollment', :enrollment_state => 'active')
      @group.users << @student

      @student.shared_contexts(@this_section_user).should eql ['the course', 'the group']
      @student.short_name_with_shared_contexts(@this_section_user).should eql "#{@this_section_user.short_name} (the course and the group)"

      @student.shared_contexts(@other_section_user).should eql ['the course']
      @student.short_name_with_shared_contexts(@other_section_user).should eql "#{@other_section_user.short_name} (the course)"

      @student.shared_contexts(@unrelated_user).should eql []
      @student.short_name_with_shared_contexts(@unrelated_user).should eql @unrelated_user.short_name
    end

    it "should not rank results by default" do
      set_up_course_with_users
      @course.enroll_user(@student, 'StudentEnrollment', :enrollment_state => 'active')

      # ordered by name (all the same), then id
      @student.messageable_users.map(&:id).
        should eql [@student.id, @this_section_teacher.id, @this_section_user.id, @other_section_user.id, @other_section_teacher.id]
    end

    it "should rank results if requested" do
      set_up_course_with_users
      @course.enroll_user(@student, 'StudentEnrollment', :enrollment_state => 'active')

      # ordered by rank, then name (all the same), then id
      @student.messageable_users(:rank_results => true).map(&:id).
        should eql [@this_section_user.id] + # two contexts (course and group)
                   [@student.id, @this_section_teacher.id, @other_section_user.id, @other_section_teacher.id] # just the course
    end

    context "concluded enrollments" do
      it "should return concluded enrollments" do # i.e. you can do a bare search for people who used to be in your class
        set_up_course_with_users
        @course.enroll_user(@student, 'StudentEnrollment', :enrollment_state => 'active')
        @this_section_user_enrollment.conclude
  
        @this_section_user.messageable_users.map(&:id).should include @this_section_user.id
        @student.messageable_users.map(&:id).should include @this_section_user.id
      end
  
      it "should not return concluded student enrollments in the course" do # when browsing a course you should not see concluded enrollments
        set_up_course_with_users
        @course.enroll_user(@student, 'StudentEnrollment', :enrollment_state => 'active')
        @course.complete!
  
        @this_section_user.messageable_users(:context => "course_#{@course.id}").map(&:id).should_not include @this_section_user.id
        # if the course was a concluded, a student should be able to browse it and message an admin (if if the admin's enrollment concluded too)
        @this_section_user.messageable_users(:context => "course_#{@course.id}").map(&:id).should include @this_section_teacher.id
        @this_section_user.enrollment_visibility[:user_counts][@course.id].should eql 2 # just the admins
        @student.messageable_users(:context => "course_#{@course.id}").map(&:id).should_not include @this_section_user.id
        @student.messageable_users(:context => "course_#{@course.id}").map(&:id).should include @this_section_teacher.id
        @student.enrollment_visibility[:user_counts][@course.id].should eql 2
      end
  
      it "should return concluded enrollments in the group if they are still members" do
        set_up_course_with_users
        @course.enroll_user(@student, 'StudentEnrollment', :enrollment_state => 'active')
        @this_section_user_enrollment.conclude
  
        @this_section_user.messageable_users(:context => "group_#{@group.id}").map(&:id).should eql [@this_section_user.id]
        @this_section_user.group_membership_visibility[:user_counts][@group.id].should eql 1
        @student.messageable_users(:context => "group_#{@group.id}").map(&:id).should eql [@this_section_user.id]
        @student.group_membership_visibility[:user_counts][@group.id].should eql 1
      end
  
      it "should return concluded enrollments in the group and section if they are still members" do
        set_up_course_with_users
        enrollment = @course.enroll_user(@student, 'StudentEnrollment', :enrollment_state => 'active', :limit_privileges_to_course_section => true)
        # we currently force limit_privileges_to_course_section to be false for students; override it in the db
        Enrollment.update_all({ :limit_privileges_to_course_section => true }, :id => enrollment.id)

        @group.users << @other_section_user
        @this_section_user_enrollment.conclude
  
        @this_section_user.messageable_users(:context => "group_#{@group.id}").map(&:id).sort.should eql [@this_section_user.id, @other_section_user.id]
        @this_section_user.group_membership_visibility[:user_counts][@group.id].should eql 2
        # student can only see people in his section
        @student.messageable_users(:context => "group_#{@group.id}").map(&:id).should eql [@this_section_user.id]
        @student.group_membership_visibility[:user_counts][@group.id].should eql 1
      end
    end

    context "admin_context" do
      before do
        set_up_course_with_users
        account_admin_user
      end

      it "should find users in the course" do
        @admin.messageable_users(:context => @course.asset_string, :admin_context => @course).map(&:id).sort.should ==
          [@this_section_teacher.id, @this_section_user.id, @other_section_user.id, @other_section_teacher.id]
      end

      it "should find users in the section" do
        @admin.messageable_users(:context => "section_#{@course.default_section.id}", :admin_context => @course.default_section).map(&:id).sort.should ==
          [@this_section_teacher.id, @this_section_user.id]
      end

      it "should find users in the group" do
        @admin.messageable_users(:context => @group.asset_string, :admin_context => @group).map(&:id).sort.should ==
          [@this_section_user.id]
      end
    end

    context "skip_visibility_checks" do
      it "should optionally show invited enrollments" do
        course(:active_all => true)
        student_in_course(:user_state => 'creation_pending')
        @teacher.messageable_users(:skip_visibility_checks => true).map(&:id).should include @student.id
      end

      it "should optionally show pending enrollments in unpublished courses" do
        course()
        teacher_in_course(:active_user => true)
        student_in_course()
        @teacher.messageable_users(:skip_visibility_checks => true, :admin_context => @course).map(&:id).should include @student.id
      end
    end
  end
  
  context "lti_role_types" do
    it "should return the correct role types" do
      course_model
      @course.offer
      teacher = user_model
      designer = user_model
      student = user_model
      nobody = user_model
      admin = user_model
      @course.root_account.add_user(admin)
      @course.enroll_teacher(teacher).accept
      @course.enroll_designer(designer).accept
      @course.enroll_student(student).accept
      teacher.lti_role_types(@course).should == ['Instructor']
      designer.lti_role_types(@course).should == ['ContentDeveloper']
      student.lti_role_types(@course).should == ['Learner']
      nobody.lti_role_types(@course).should == ['urn:lti:sysrole:ims/lis/None']
      admin.lti_role_types(@course).should == ['urn:lti:instrole:ims/lis/Administrator']
    end
    
    it "should return multiple role types if applicable" do
      course_model
      @course.offer
      teacher = user_model
      @course.root_account.add_user(teacher)
      @course.enroll_teacher(teacher).accept
      @course.enroll_student(teacher).accept
      teacher.lti_role_types(@course).sort.should == ['Instructor','Learner','urn:lti:instrole:ims/lis/Administrator'].sort
    end
    
    it "should not return role types from other contexts" do
      @course1 = course_model
      @course2 = course_model
      @course.offer
      teacher = user_model
      student = user_model
      @course1.enroll_teacher(teacher).accept
      @course1.enroll_student(student).accept
      teacher.lti_role_types(@course2).should == ['urn:lti:sysrole:ims/lis/None']
      student.lti_role_types(@course2).should == ['urn:lti:sysrole:ims/lis/None']
    end
  end
  
  context "tabs_available" do
    it "should not include unconfigured external tools" do
      tool = Account.default.context_external_tools.new(:consumer_key => 'bob', :shared_secret => 'bob', :name => 'bob', :domain => "example.com")
      tool.settings[:course_navigation] = {:url => "http://www.example.com", :text => "Example URL"}
      tool.save!
      tool.has_user_navigation.should == false
      user_model
      tabs = @user.profile.tabs_available(@user, :root_account => Account.default)
      tabs.map{|t| t[:id] }.should_not be_include(tool.asset_string)
    end
    
    it "should include configured external tools" do
      tool = Account.default.context_external_tools.new(:consumer_key => 'bob', :shared_secret => 'bob', :name => 'bob', :domain => "example.com")
      tool.settings[:user_navigation] = {:url => "http://www.example.com", :text => "Example URL"}
      tool.save!
      tool.has_user_navigation.should == true
      user_model
      tabs = @user.profile.tabs_available(@user, :root_account => Account.default)
      tabs.map{|t| t[:id] }.should be_include(tool.asset_string)
      tab = tabs.detect{|t| t[:id] == tool.asset_string }
      tab[:href].should == :user_external_tool_path
      tab[:args].should == [@user.id, tool.id]
      tab[:label].should == "Example URL"
    end
  end
  
  context "avatars" do
    it "should find only users with avatars set" do
      user_model
      @user.avatar_state = 'submitted'
      @user.save!
      User.with_avatar_state('submitted').count.should == 0
      User.with_avatar_state('any').count.should == 0
      @user.avatar_image_url = 'http://www.example.com'
      @user.save!
      User.with_avatar_state('submitted').count.should == 1
      User.with_avatar_state('any').count.should == 1
    end

    it "should clear avatar state when assigning by service that no longer exists" do
      user_model
      @user.avatar_image_url = 'http://www.example.com'
      @user.avatar_image = { 'type' => 'twitter' }
      @user.avatar_image_url.should be_nil
    end

    it "should allow external url's to be assigned" do
      user_model
      @user.avatar_image = { 'type' => 'external', 'url' => 'http://www.example.com/image.jpg' }
      @user.save!
      @user.reload.avatar_image_url.should == 'http://www.example.com/image.jpg'
    end

    it "should return a useful avatar_fallback_url" do
      User.avatar_fallback_url.should ==
        "https://#{HostUrl.default_host}/images/messages/avatar-50.png"
      User.avatar_fallback_url("/somepath").should ==
        "https://#{HostUrl.default_host}/somepath"
      User.avatar_fallback_url("//somedomain/path").should ==
        "https://somedomain/path"
      User.avatar_fallback_url("http://somedomain/path").should ==
        "http://somedomain/path"
      User.avatar_fallback_url(nil, OpenObject.new(:host => "foo", :scheme => "http")).should ==
        "http://foo/images/messages/avatar-50.png"
      User.avatar_fallback_url("/somepath", OpenObject.new(:host => "bar", :scheme => "https")).should ==
        "https://bar/somepath"
      User.avatar_fallback_url("//somedomain/path", OpenObject.new(:host => "bar", :scheme => "https")).should ==
        "https://somedomain/path"
      User.avatar_fallback_url("http://somedomain/path", OpenObject.new(:host => "bar", :scheme => "https")).should ==
        "http://somedomain/path"
      User.avatar_fallback_url('%{fallback}').should ==
        '%{fallback}'
    end

    describe "#clear_avatar_image_url_with_uuid" do
      before :each do
        user_model
        @user.avatar_image_url = '1234567890ABCDEF'
        @user.save!
      end
      it "should raise ArgumentError when uuid nil or blank" do
        lambda { @user.clear_avatar_image_url_with_uuid(nil) }.should  raise_error(ArgumentError, "'uuid' is required and cannot be blank")
        lambda { @user.clear_avatar_image_url_with_uuid('') }.should raise_error(ArgumentError, "'uuid' is required and cannot be blank")
        lambda { @user.clear_avatar_image_url_with_uuid('  ') }.should raise_error(ArgumentError, "'uuid' is required and cannot be blank")
      end
      it "should clear avatar_image_url when uuid matches" do
        @user.clear_avatar_image_url_with_uuid('1234567890ABCDEF')
        @user.avatar_image_url.should be_nil
        @user.changed?.should == false   # should be saved
      end
      it "should not clear avatar_image_url when no match" do
        @user.clear_avatar_image_url_with_uuid('NonMatchingText')
        @user.avatar_image_url.should == '1234567890ABCDEF'
      end
      it "should not error when avatar_image_url is nil" do
        @user.avatar_image_url = nil
        @user.save!
        #
        lambda { @user.clear_avatar_image_url_with_uuid('something') }.should_not raise_error
        @user.avatar_image_url.should be_nil
      end
    end
  end

  it "should find sections for course" do
    course_with_student
    @student.sections_for_course(@course).should include @course.default_section
  end

  describe "name_parts" do
    it "should infer name parts" do
      User.name_parts('Cody Cutrer').should == ['Cody', 'Cutrer', nil]
      User.name_parts('  Cody  Cutrer   ').should == ['Cody', 'Cutrer', nil]
      User.name_parts('Cutrer, Cody').should == ['Cody', 'Cutrer', nil]
      User.name_parts('Cutrer, Cody Houston').should == ['Cody Houston', 'Cutrer', nil]
      User.name_parts('St. Clair, John').should == ['John', 'St. Clair', nil]
      # sorry, can't figure this out
      User.name_parts('John St. Clair').should == ['John St.', 'Clair', nil]
      User.name_parts('Jefferson Thomas Cutrer IV').should == ['Jefferson Thomas', 'Cutrer', 'IV']
      User.name_parts('Jefferson Thomas Cutrer, IV').should == ['Jefferson Thomas', 'Cutrer', 'IV']
      User.name_parts('Cutrer, Jefferson, IV').should == ['Jefferson', 'Cutrer', 'IV']
      User.name_parts('Cutrer, Jefferson IV').should == ['Jefferson', 'Cutrer', 'IV']
      User.name_parts(nil).should == [nil, nil, nil]
      User.name_parts('Bob').should == ['Bob', nil, nil]
      User.name_parts('Ho, Chi, Min').should == ['Chi Min', 'Ho', nil]
      # sorry, don't understand cultures that put the surname first
      # they should just manually specify their sort name
      User.name_parts('Ho Chi Min').should == ['Ho Chi', 'Min', nil]
      User.name_parts('').should == [nil, nil, nil]
      User.name_parts('John Doe').should == ['John', 'Doe', nil]
      User.name_parts('Junior').should == ['Junior', nil, nil]
      User.name_parts('John St. Clair', 'St. Clair').should == ['John', 'St. Clair', nil]
      User.name_parts('John St. Clair', 'Cutrer').should == ['John St.', 'Clair', nil]
      User.name_parts('St. Clair', 'St. Clair').should == [nil, 'St. Clair', nil]
      User.name_parts('St. Clair,').should == [nil, 'St. Clair', nil]
    end

    it "should keep the sortable_name up to date if all that changed is the name" do
      u = User.new
      u.name = 'Cody Cutrer'
      u.save!
      u.sortable_name.should == 'Cutrer, Cody'

      u.name = 'Bracken Mosbacker'
      u.save!
      u.sortable_name.should == 'Mosbacker, Bracken'

      u.name = 'John St. Clair'
      u.sortable_name = 'St. Clair, John'
      u.save!
      u.sortable_name.should == 'St. Clair, John'

      u.name = 'Matthew St. Clair'
      u.save!
      u.sortable_name.should == "St. Clair, Matthew"

      u.name = 'St. Clair'
      u.save!
      u.sortable_name.should == "St. Clair,"
    end
  end

  context "group_member_json" do
    before :each do
      @account = Account.default
      @enrollment = course_with_student(:active_all => true)
      @section = @enrollment.course_section
      @student.sortable_name = 'Doe, John'
      @student.short_name = 'Johnny'
      @student.save
    end

    it "should include user_id, name, and display_name" do
      @student.group_member_json(@account).should == {
        :user_id => @student.id,
        :name => 'Doe, John',
        :display_name => 'Johnny'
      }
    end

    it "should include course section (section_id and section_code) if appropriate" do
      @student.group_member_json(@account).should == {
        :user_id => @student.id,
        :name => 'Doe, John',
        :display_name => 'Johnny'
      }

      @student.group_member_json(@course).should == {
        :user_id => @student.id,
        :name => 'Doe, John',
        :display_name => 'Johnny',
        :sections => [ {
          :section_id => @section.id,
          :section_code => @section.section_code
        } ]
      }
    end
  end

  describe "menu_courses" do
    it "should include temporary invitations" do
      user_with_pseudonym(:active_all => 1)
      @user1 = @user
      user
      @user2 = @user
      @user2.update_attribute(:workflow_state, 'creation_pending')
      @user2.communication_channels.create!(:path => @cc.path)
      course(:active_all => 1)
      @course.enroll_user(@user2)

      @user1.menu_courses.should == [@course]
    end
  end

  describe "cached_current_enrollments" do
    it "should include temporary invitations" do
      user_with_pseudonym(:active_all => 1)
      @user1 = @user
      user
      @user2 = @user
      @user2.update_attribute(:workflow_state, 'creation_pending')
      @user2.communication_channels.create!(:path => @cc.path)
      course(:active_all => 1)
      @enrollment = @course.enroll_user(@user2)

      @user1.cached_current_enrollments.should == [@enrollment]
    end
  end

  describe "pseudonym_for_account" do
    before do
      @account2 = Account.create!
      @account3 = Account.create!
      Pseudonym.any_instance.stubs(:works_for_account?).returns(false)
      Pseudonym.any_instance.stubs(:works_for_account?).with(Account.default, false).returns(true)
    end

    it "should return an active pseudonym" do
      user_with_pseudonym(:active_all => 1)
      @user.find_pseudonym_for_account(Account.default).should == @pseudonym
    end

    it "should return a trusted pseudonym" do
      user_with_pseudonym(:active_all => 1, :account => @account2)
      @user.find_pseudonym_for_account(Account.default).should == @pseudonym
    end

    it "should return nil if none work" do
      user_with_pseudonym(:active_all => 1)
      @user.find_pseudonym_for_account(@account2).should == nil
    end

    it "should create a copy of an existing pseudonym" do
      @account1 = Account.create!
      @account2 = Account.create!
      @account3 = Account.create!

      # from unrelated account
      user_with_pseudonym(:active_all => 1, :account => @account2, :username => 'unrelated@example.com', :password => 'abcdef')
      new_pseudonym = @user.find_or_initialize_pseudonym_for_account(@account1)
      new_pseudonym.should_not be_nil
      new_pseudonym.should be_new_record
      new_pseudonym.unique_id.should == 'unrelated@example.com'

      # from default account
      @user.pseudonyms.create!(:unique_id => 'default@example.com', :password => 'abcdef', :password_confirmation => 'abcdef')
      @user.pseudonyms.create!(:account => @account3, :unique_id => 'preferred@example.com', :password => 'abcdef', :password_confirmation => 'abcdef')
      new_pseudonym = @user.find_or_initialize_pseudonym_for_account(@account1)
      new_pseudonym.should_not be_nil
      new_pseudonym.should be_new_record
      new_pseudonym.unique_id.should == 'default@example.com'

      # from site admin account
      @user.pseudonyms.create!(:account => Account.site_admin, :unique_id => 'siteadmin@example.com', :password => 'abcdef', :password_confirmation => 'abcdef')
      new_pseudonym = @user.find_or_initialize_pseudonym_for_account(@account1)
      new_pseudonym.should_not be_nil
      new_pseudonym.should be_new_record
      new_pseudonym.unique_id.should == 'siteadmin@example.com'

      # from preferred account
      new_pseudonym = @user.find_or_initialize_pseudonym_for_account(@account1, @account3)
      new_pseudonym.should_not be_nil
      new_pseudonym.should be_new_record
      new_pseudonym.unique_id.should == 'preferred@example.com'

      # from unrelated account, if other options are not viable
      user2 = User.create!
      @account1.pseudonyms.create!(:user => user2, :unique_id => 'preferred@example.com', :password => 'abcdef', :password_confirmation => 'abcdef')
      @user.pseudonyms.detect { |p| p.account == Account.site_admin }.update_attribute(:password_auto_generated, true)
      Account.default.account_authorization_configs.create!(:auth_type => 'cas')
      new_pseudonym = @user.find_or_initialize_pseudonym_for_account(@account1, @account3)
      new_pseudonym.should_not be_nil
      new_pseudonym.should be_new_record
      new_pseudonym.unique_id.should == 'unrelated@example.com'
      new_pseudonym.save!
      new_pseudonym.valid_password?('abcdef').should be_true
    end

    it "should not create a new one when there are no viable candidates" do
      @account1 = Account.create!
      # no pseudonyms
      user
      @user.find_or_initialize_pseudonym_for_account(@account1).should be_nil

      # auto-generated password
      @account2 = Account.create!
      @user.pseudonyms.create!(:account => @account2, :unique_id => 'bracken@instructure.com')
      @user.find_or_initialize_pseudonym_for_account(@account1).should be_nil

      # delegated auth
      @account3 = Account.create!
      @account3.account_authorization_configs.create!(:auth_type => 'cas')
      @account3.should be_delegated_authentication
      @user.pseudonyms.create!(:account => @account3, :unique_id => 'jacob@instructure.com', :password => 'abcdef', :password_confirmation => 'abcdef')
      @user.find_or_initialize_pseudonym_for_account(@account1).should be_nil

      # conflict
      @user2 = User.create! { |u| u.workflow_state = 'registered' }
      @user2.pseudonyms.create!(:account => @account1, :unique_id => 'jt@instructure.com', :password => 'abcdef', :password_confirmation => 'abcdef')
      @user.pseudonyms.create!(:unique_id => 'jt@instructure.com', :password => 'ghijkl', :password_confirmation => 'ghijkl')
      @user.find_or_initialize_pseudonym_for_account(@account1).should be_nil
    end
  end

  describe "email_channel" do
    it "should not return retired channels" do
      u = User.new
      retired = u.communication_channels.build(:path => 'retired@example.com', :path_type => 'email') { |cc| cc.workflow_state = 'retired'}
      u.email_channel.should be_nil
      active = u.communication_channels.build(:path => 'active@example.com', :path_type => 'email') { |cc| cc.workflow_state = 'active'}
      u.email_channel.should == active
    end
  end

  describe "sis_pseudonym_for" do
    it "should return active pseudonyms only" do
      course :active_all => true, :account => Account.default
      u = User.create!
      u.pseudonyms.create!(:account => Account.default, :unique_id => "user2@example.com", :password => "asdfasdf", :password_confirmation => "asdfasdf") {|x| x.workflow_state = 'deleted'; x.sis_user_id = "user2" }
      u.sis_pseudonym_for(@course).should be_nil
      @p = u.pseudonyms.create!(:account => Account.default, :unique_id => "user1@example.com", :password => "asdfasdf", :password_confirmation => "asdfasdf") {|x| x.workflow_state = 'active'; x.sis_user_id = "user1" }
      u.sis_pseudonym_for(@course).should == @p
    end

    it "should return pseudonyms in the right account" do
      course :active_all => true, :account => Account.default
      other_account = account_model
      u = User.create!
      u.pseudonyms.create!(:account => other_account, :unique_id => "user1@example.com", :password => "asdfasdf", :password_confirmation => "asdfasdf") {|x| x.workflow_state = 'active'; x.sis_user_id = "user1" }
      u.sis_pseudonym_for(@course).should be_nil
      @p = u.pseudonyms.create!(:account => Account.default, :unique_id => "user2@example.com", :password => "asdfasdf", :password_confirmation => "asdfasdf") {|x| x.workflow_state = 'active'; x.sis_user_id = "user2" }
      u.sis_pseudonym_for(@course).should == @p
    end

    it "should return pseudonyms with a sis id only" do
      course :active_all => true, :account => Account.default
      u = User.create!
      u.pseudonyms.create!(:account => Account.default, :unique_id => "user1@example.com", :password => "asdfasdf", :password_confirmation => "asdfasdf") {|x| x.workflow_state = 'active' }
      u.sis_pseudonym_for(@course).should be_nil
      @p = u.pseudonyms.create!(:account => Account.default, :unique_id => "user2@example.com", :password => "asdfasdf", :password_confirmation => "asdfasdf") {|x| x.workflow_state = 'active'; x.sis_user_id = "user2" }
      u.sis_pseudonym_for(@course).should == @p
    end

    it "should find the right root account for a course" do
      @account = account_model
      course :active_all => true, :account => @account
      u = User.create!
      pseudonyms = mock()
      u.stubs(:pseudonyms).returns(pseudonyms)
      pseudonyms.stubs(:loaded?).returns(false)
      pseudonyms.stubs(:active).returns(pseudonyms)
      pseudonyms.expects(:find_by_account_id).with(@account.id, :conditions => ["sis_user_id IS NOT NULL"]).returns(42)
      u.sis_pseudonym_for(@course).should == 42
    end

    it "should find the right root account for a group" do
      @account = account_model
      course :active_all => true, :account => @account
      @group = group :group_context => @course
      u = User.create!
      pseudonyms = mock()
      u.stubs(:pseudonyms).returns(pseudonyms)
      pseudonyms.stubs(:loaded?).returns(false)
      pseudonyms.stubs(:active).returns(pseudonyms)
      pseudonyms.expects(:find_by_account_id).with(@account.id, :conditions => ["sis_user_id IS NOT NULL"]).returns(42)
      u.sis_pseudonym_for(@group).should == 42
    end

    it "should find the right root account for a non-root-account" do
      @root_account = account_model
      @account = @root_account.sub_accounts.create!
      u = User.create!
      pseudonyms = mock()
      u.stubs(:pseudonyms).returns(pseudonyms)
      pseudonyms.stubs(:loaded?).returns(false)
      pseudonyms.stubs(:active).returns(pseudonyms)
      pseudonyms.expects(:find_by_account_id).with(@root_account.id, :conditions => ["sis_user_id IS NOT NULL"]).returns(42)
      u.sis_pseudonym_for(@account).should == 42
    end

    it "should find the right root account for a root account" do
      @account = account_model
      u = User.create!
      pseudonyms = mock()
      u.stubs(:pseudonyms).returns(pseudonyms)
      pseudonyms.stubs(:loaded?).returns(false)
      pseudonyms.stubs(:active).returns(pseudonyms)
      pseudonyms.expects(:find_by_account_id).with(@account.id, :conditions => ["sis_user_id IS NOT NULL"]).returns(42)
      u.sis_pseudonym_for(@account).should == 42
    end

    it "should bail if it can't find a root account" do
      context = Course.new # some context that doesn't have an account
      (lambda {User.create!.sis_pseudonym_for(context)}).should raise_error("could not resolve root account")
    end
  end

  describe "flag_as_admin" do
    it "should add an AccountUser" do
      @account = account_model
      u = User.create!
      u.account_users.should be_empty
      u.flag_as_admin(@account)
      u.reload
      u.account_users.size.should == 1
      admin = u.account_users.first
      admin.account.should == @account
    end

    it "should default to the AccountAdmin role" do
      @account = account_model
      u = User.create!
      u.flag_as_admin(@account)
      u.reload
      admin = u.account_users.first
      admin.membership_type.should == 'AccountAdmin'
    end

    it "should respect a provided role" do
      @account = account_model
      u = User.create!
      u.flag_as_admin(@account, "CustomAccountUser")
      u.reload
      admin = u.account_users.first
      admin.membership_type.should == 'CustomAccountUser'
    end

    it "should send an account registration email for users that haven't registered yet" do
      AccountUser.any_instance.expects(:account_user_registration!)
      @account = account_model
      u = User.create!
      u.flag_as_admin(@account)
    end

    it "should send the pre-registered account registration email for users the have already registered" do
      AccountUser.any_instance.expects(:account_user_notification!)
      @account = account_model
      u = User.create!
      u.register
      u.flag_as_admin(@account)
    end
  end

  describe "email=" do
    it "should work" do
      @user = User.create!
      @user.email = 'john@example.com'
      @user.communication_channels.map(&:path).should == ['john@example.com']
      @user.email.should == 'john@example.com'
    end
  end

  describe "event methods" do
    describe "calendar_events_for_calendar" do
      it "should include own scheduled appointments" do
        course_with_student(:active_all => true)
        ag = AppointmentGroup.create!(:title => 'test appointment', :contexts => [@course], :new_appointments => [[Time.now, Time.now + 1.hour], [Time.now + 1.hour, Time.now + 2.hour]])
        ag.appointments.first.reserve_for(@user, @user)
        events = @user.calendar_events_for_calendar
        events.size.should eql 1
        events.first.title.should eql 'test appointment'
      end

      it "should include manageable appointments" do
        course(:active_all => true)
        @user = @course.instructors.first
        ag = AppointmentGroup.create!(:title => 'test appointment', :contexts => [@course], :new_appointments => [[Time.now, Time.now + 1.hour]])
        events = @user.calendar_events_for_calendar
        events.size.should eql 1
        events.first.title.should eql 'test appointment'
      end
    end

    describe "upcoming_events" do
      it "should include manageable appointment groups" do
        course(:active_all => true)
        @user = @course.instructors.first
        ag = AppointmentGroup.create!(:title => 'test appointment', :contexts => [@course], :new_appointments => [[Time.now, Time.now + 1.hour]])
        events = @user.upcoming_events
        events.size.should eql 1
        events.first.title.should eql 'test appointment'
      end
    end
  end

  describe "assignments_needing_submitting" do
    # NOTE: More thorough testing of the Assignment#not_locked named scope is in assignment_spec.rb
    context "locked assignments" do
      before :each do
        course_with_student_logged_in(:active_all => true)
        assignment_quiz([], :course => @course, :user => @user)
        # Setup default values for tests (leave unsaved for easy changes)
        @quiz.unlock_at = nil
        @quiz.lock_at = nil
        @quiz.due_at = 2.days.from_now
      end
      it "should include assignments with no locks" do
        @quiz.save!
        list = @student.assignments_needing_submitting(:contexts => [@course])
        list.size.should eql 1
        list.first.title.should eql 'Test Assignment'
      end
      it "should include assignments with unlock_at in the past" do
        @quiz.unlock_at = 1.hour.ago
        @quiz.save!
        list = @student.assignments_needing_submitting(:contexts => [@course])
        list.size.should eql 1
        list.first.title.should eql 'Test Assignment'
      end
      it "should include assignments with lock_at in the future" do
        @quiz.lock_at = 1.hour.from_now
        @quiz.save!
        list = @student.assignments_needing_submitting(:contexts => [@course])
        list.size.should eql 1
        list.first.title.should eql 'Test Assignment'
      end
      it "should not include assignments where unlock_at is in future" do
        @quiz.unlock_at = 1.hour.from_now
        @quiz.save!
        @student.assignments_needing_submitting(:contexts => [@course]).count.should == 0
      end
      it "should not include assignments where lock_at is in past" do
        @quiz.lock_at = 1.hour.ago
        @quiz.save!
        @student.assignments_needing_submitting(:contexts => [@course]).count.should == 0
      end
    end
  end

  describe "avatar_key" do
    it "should return a valid avatar key for a valid user id" do
      User.avatar_key(1).should == "1-#{Canvas::Security.hmac_sha1('1')[0,10]}"
      User.avatar_key("1").should == "1-#{Canvas::Security.hmac_sha1('1')[0,10]}"
      User.avatar_key("2").should == "2-#{Canvas::Security.hmac_sha1('2')[0,10]}"
      User.avatar_key("161612461246").should == "161612461246-#{Canvas::Security.hmac_sha1('161612461246')[0,10]}"
    end
    it" should return '0' for an invalid user id" do
      User.avatar_key(nil).should == "0"
      User.avatar_key("").should == "0"
      User.avatar_key(0).should == "0"
    end
  end
  describe "user_id_from_avatar_key" do
    it "should return a valid user id for a valid avatar key" do
      User.user_id_from_avatar_key("1-#{Canvas::Security.hmac_sha1('1')[0,10]}").should == '1'
      User.user_id_from_avatar_key("2-#{Canvas::Security.hmac_sha1('2')[0,10]}").should == '2'
      User.user_id_from_avatar_key("1536394658-#{Canvas::Security.hmac_sha1('1536394658')[0,10]}").should == '1536394658'
    end
    it "should return nil for an invalid avatar key" do
      User.user_id_from_avatar_key("1-#{Canvas::Security.hmac_sha1('1')}").should == nil
      User.user_id_from_avatar_key("1").should == nil
      User.user_id_from_avatar_key("2-123456").should == nil
      User.user_id_from_avatar_key("a").should == nil
      User.user_id_from_avatar_key(nil).should == nil
      User.user_id_from_avatar_key("").should == nil
      User.user_id_from_avatar_key("-").should == nil
      User.user_id_from_avatar_key("-159135").should == nil
    end
  end

  describe "order_by_sortable_name" do
    it "should sort lexicographically" do
      User.create!(:name => "John Johnson")
      User.create!(:name => "John John")
      User.order_by_sortable_name.all.map(&:sortable_name).should == ["John, John", "Johnson, John"]
    end
  end

  describe "quota" do
    it "should default to User.default_storage_quota" do
      user().quota.should eql User.default_storage_quota
    end

    it "should sum up associated root account quotas" do
      user()
      @user.associated_root_accounts << Account.create! << (a = Account.create!)
      a.update_attribute :default_user_storage_quota_mb, a.default_user_storage_quota_mb + 10
      @user.quota.should eql(2 * User.default_storage_quota + 10.megabytes)
    end
  end

  it "should build a profile if one doesn't already exist" do
    user = User.create! :name => "John Johnson"
    profile = user.profile
    profile.id.should be_nil
    profile.bio = "bio!"
    profile.save!
    user.profile.should == profile
  end

  describe "common_account_chain" do
    before do
      user_with_pseudonym
    end

    it "work for just root accounts" do
      root_acct1 = Account.create!
      root_acct2 = Account.create!

      @user.user_account_associations.create!(:account_id => root_acct2.id)
      @user.reload
      @user.common_account_chain(root_acct1).should be_nil
      @user.common_account_chain(root_acct2).should eql [root_acct2]
    end

    it "should work for one level of sub accounts" do
      root_acct = Account.create!
      sub_acct1 = Account.create!(:parent_account => root_acct)
      sub_acct2 = Account.create!(:parent_account => root_acct)

      @user.user_account_associations.create!(:account_id => root_acct.id)
      @user.reload.common_account_chain(root_acct).should eql [root_acct]

      @user.user_account_associations.create!(:account_id => sub_acct1.id)
      @user.reload.common_account_chain(root_acct).should eql [root_acct, sub_acct1]

      @user.user_account_associations.create!(:account_id => sub_acct2.id)
      @user.reload.common_account_chain(root_acct).should eql [root_acct]
    end

    it "should work for two levels of sub accounts" do
      root_acct = Account.create!
      sub_acct1 = Account.create!(:parent_account => root_acct)
      sub_sub_acct1 = Account.create!(:parent_account => sub_acct1)
      sub_sub_acct2 = Account.create!(:parent_account => sub_acct1)
      sub_acct2 = Account.create!(:parent_account => root_acct)

      @user.user_account_associations.create!(:account_id => root_acct.id)
      @user.reload.common_account_chain(root_acct).should eql [root_acct]

      @user.user_account_associations.create!(:account_id => sub_acct1.id)
      @user.reload.common_account_chain(root_acct).should eql [root_acct, sub_acct1]

      @user.user_account_associations.create!(:account_id => sub_sub_acct1.id)
      @user.reload.common_account_chain(root_acct).should eql [root_acct, sub_acct1, sub_sub_acct1]

      @user.user_account_associations.create!(:account_id => sub_sub_acct2.id)
      @user.reload.common_account_chain(root_acct).should eql [root_acct, sub_acct1]

      @user.user_account_associations.create!(:account_id => sub_acct2.id)
      @user.reload.common_account_chain(root_acct).should eql [root_acct]
    end
  end
end
