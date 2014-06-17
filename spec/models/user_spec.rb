#
# Copyright (C) 2011 - 2013 Instructure, Inc.
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

require File.expand_path(File.dirname(__FILE__) + '/../sharding_spec_helper.rb')

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
    account.account_users.create!(user: @user)

    @user.reload
    @user.associated_accounts.length.should eql(1)
    @user.associated_accounts.first.should eql(account)
  end

  it "should populate dashboard_messages" do
    Notification.create(:name => "Assignment Created")
    course_with_teacher(:active_all => true)
    @user.stream_item_instances.should be_empty
    @a = @course.assignments.new(:title => "some assignment")
    @a.workflow_state = "available"
    @a.save
    @user.stream_item_instances(true).should_not be_empty
  end

  it "should ignore orphaned stream item instances" do
    course_with_student(:active_all => true)
    google_docs_collaboration_model(:user_id => @user.id)
    @user.recent_stream_items.size.should == 1
    StreamItem.delete_all
    @user.recent_stream_items.size.should == 0
  end

  it "should ignore stream item instances from concluded courses" do
    course_with_teacher(:active_all => true)
    google_docs_collaboration_model(:user_id => @user.id)
    @user.recent_stream_items.size.should == 1
    @course.soft_conclude!
    @course.save
    @user.recent_stream_items.size.should == 0
  end

  describe "#recent_stream_items" do
    it "should skip submission stream items" do
      course_with_teacher(:active_all => true)
      course_with_student(:active_all => true, :course => @course)
      assignment = @course.assignments.create!(:title => "some assignment", :submission_types => ['online_text_entry'])
      sub = assignment.submit_homework @student, body: "submission"
      sub.add_comment :author => @teacher, :comment => "lol"
      item = StreamItem.last
      item.asset.should == sub
      @student.visible_stream_item_instances.map(&:stream_item).should include item
      @student.recent_stream_items.should_not include item
    end
  end

  describe "#cached_recent_stream_items" do
    before(:once) do
      @contexts = []
      # create stream item 1
      course_with_teacher(:active_all => true)
      @contexts << @course
      discussion_topic_model(:context => @course)
      # create stream item 2
      course_with_teacher(:active_all => true, :user => @teacher)
      @contexts << @course
      discussion_topic_model(:context => @course)

      @dashboard_key = StreamItemCache.recent_stream_items_key(@teacher)
      @context_keys = @contexts.map { |context|
        StreamItemCache.recent_stream_items_key(@teacher, context.class.base_class.name, context.id)
      }
    end

    it "creates cache keys for each context" do
      enable_cache do
        @teacher.cached_recent_stream_items(:contexts => @contexts)
        Rails.cache.read(@dashboard_key).should be_blank
        @context_keys.each do |context_key|
          Rails.cache.read(context_key).should_not be_blank
        end
      end
    end

    it "creates one cache key when there are no contexts" do
      enable_cache do
        @teacher.cached_recent_stream_items # cache the dashboard items
        Rails.cache.read(@dashboard_key).should_not be_blank
        @context_keys.each do |context_key|
          Rails.cache.read(context_key).should be_blank
        end
      end
    end
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
    account1.account_users.create!(user: user)
    account2.account_users.create!(user: user)
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

  describe "update_account_associations" do
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
      Account.default.account_users.create!(user: user)
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

    context "sharding" do
      specs_require_sharding

      it "should create associations for a user in multiple shards" do
        user
        Account.site_admin.account_users.create!(user: @user)
        @user.user_account_associations.map(&:account).should == [Account.site_admin]

        @shard1.activate do
          @account = Account.create!
          au = @account.account_users.create!(user: @user)
          @user.user_account_associations.with_each_shard.map(&:account).sort_by(&:id).should ==
              [Account.site_admin, @account].sort_by(&:id)
          @account.user_account_associations.map(&:user).should == [@user]

          au.destroy

          @user.user_account_associations.with_each_shard.map(&:account).should == [Account.site_admin]
          @account.reload.user_account_associations.map(&:user).should == []

          @account.account_users.create!(user: @user)

          @user.user_account_associations.with_each_shard.map(&:account).sort_by(&:id).should ==
              [Account.site_admin, @account].sort_by(&:id)
          @account.reload.user_account_associations.map(&:user).should == [@user]

          UserAccountAssociation.delete_all
        end
        UserAccountAssociation.delete_all

        @shard2.activate do
          @user.update_account_associations

          @user.user_account_associations.with_each_shard.map(&:account).sort_by(&:id).should ==
              [Account.site_admin, @account].sort_by(&:id)
          @account.reload.user_account_associations.map(&:user).should == [@user]
        end
        UserAccountAssociation.delete_all

        @shard1.activate do
          # check sharding for when we pass user IDs into update_account_associations, rather than user objects themselves
          User.update_account_associations([@user.id], :all_shards => true)
          @account.reload.all_users.should == [@user]
        end
        @shard2.activate { @account.reload.all_users.should == [@user] }
      end
    end
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

  it "should not include recent feedback for unpublished assignments" do
    create_course_with_student_and_assignment
    @assignment.grade_student @user, :grade => 9
    @assignment.unpublish
    @user.recent_feedback(:contexts => [@course]).should be_empty
  end

  it "should not include recent feedback for other students in admin feedback" do
    create_course_with_student_and_assignment
    other_teacher = @teacher
    teacher = teacher_in_course(:active_all => true).user
    student = student_in_course(:active_all => true).user
    sub = @assignment.grade_student(student, :grade => 9).first
    sub.submission_comments.create!(:comment => 'c1', :author => other_teacher, :recipient_id => student.id)
    sub.save!
    teacher.recent_feedback(:contexts => [@course]).should be_empty
  end

  describe '#courses_with_primary_enrollment' do

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

    describe 'with cross sharding' do
      specs_require_sharding

      it 'pulls the enrollments that are completed with global ids' do
        alice = bob = bobs_enrollment = alices_enrollment = nil

        duped_enrollment_id = 0

        @shard1.activate do
          alice = User.create!(:name => 'alice')
          bob = User.create!(:name => 'bob')
          account = Account.create!
          courseX = account.courses.build
          courseX.workflow_state = 'available'
          courseX.save!
          bobs_enrollment = StudentEnrollment.create!(:course => courseX, :user => bob, :workflow_state => 'completed')
          duped_enrollment_id = bobs_enrollment.id
        end

        @shard2.activate do
          account = Account.create!
          courseY = account.courses.build
          courseY.workflow_state = 'available'
          courseY.save!
          alices_enrollment = StudentEnrollment.new(:course => courseY, :user => alice, :workflow_state => 'active')
          alices_enrollment.id = duped_enrollment_id
          alices_enrollment.save!
        end

        alice.courses_with_primary_enrollment.size.should == 1
      end

      it 'still filters out completed enrollments for the correct user' do
        alice = nil
        @shard1.activate do
          alice = User.create!(:name => 'alice')
          account = Account.create!
          courseX = account.courses.build
          courseX.workflow_state = 'available'
          courseX.save!
          StudentEnrollment.create!(:course => courseX, :user => alice, :workflow_state => 'completed')
        end
        alice.courses_with_primary_enrollment.size.should == 0
      end

    end
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

  it "should record deleted_at" do
    user = User.create
    user.destroy
    user.deleted_at.should_not be_nil
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
      Account.site_admin.account_users.create!(user: @site_admin)
      Account.default.account_users.create!(user: @admin)
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
      Account.default.account_users.create!(user: @admin)
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
      Account.default.account_users.create!(user: @admin)
      Account.site_admin.account_users.create!(user: @site_admin)
      user.can_masquerade?(@admin, Account.default).should be_true
      user.can_masquerade?(@admin, @account2).should be_false
      user.can_masquerade?(@site_admin, Account.default).should be_true
      user.can_masquerade?(@site_admin, @account2).should be_true
      @account2.account_users.create!(user: @admin)
    end

    it "should allow site admin when they don't otherwise qualify for :create_courses" do
      user = user_with_pseudonym(:username => 'nobody1@example.com')
      @admin = user_with_pseudonym(:username => 'nobody2@example.com')
      @site_admin = user_with_pseudonym(:username => 'nobody3@example.com', :account => Account.site_admin)
      Account.default.account_users.create!(user: @admin)
      Account.site_admin.account_users.create!(user: @site_admin)
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

  describe '#has_subset_of_account_permissions?' do
    let(:user) { User.new }
    let(:other_user) { User.new }

    it 'returns true for self' do
      user.has_subset_of_account_permissions?(user, nil).should be_true
    end

    it 'is false if the account is not a root account' do
      user.has_subset_of_account_permissions?(other_user, stub(:root_account? => false)).should be_false
    end

    it 'is true if there are no account users for this root account' do
      account = stub(:root_account? => true, :all_account_users_for => [])
      user.has_subset_of_account_permissions?(other_user, account).should be_true
    end

    it 'is true when all account_users for current user are subsets of target user' do
      account = stub(:root_account? => true, :all_account_users_for => [stub(:is_subset_of? => true)])
      user.has_subset_of_account_permissions?(other_user, account).should be_true
    end

    it 'is false when any account_user for current user is not a subset of target user' do
      account = stub(:root_account? => true, :all_account_users_for => [stub(:is_subset_of? => false)])
      user.has_subset_of_account_permissions?(other_user, account).should be_false
    end
  end

  context "permissions" do
    it "should not allow account admin to modify admin privileges of other account admins" do
      RoleOverride.readonly_for(Account.default, :manage_role_overrides, AccountUser::BASE_ROLE_NAME, 'AccountAdmin').should be_true
      RoleOverride.readonly_for(Account.default, :manage_account_memberships, AccountUser::BASE_ROLE_NAME, 'AccountAdmin').should be_true
      RoleOverride.readonly_for(Account.default, :manage_account_settings, AccountUser::BASE_ROLE_NAME, 'AccountAdmin').should be_true
    end
  end

  context "check_courses_right?" do
    before :once do
      course_with_teacher(:active_all => true)
      @student = user_model
    end

    before :each do
      @course.stubs(:grants_right?).returns(true)
    end

    it "should require parameters" do
      @student.check_courses_right?(nil, :some_right).should be_false
      @student.check_courses_right?(@teacher, nil).should be_false
    end

    it "should check current courses" do
      @student.expects(:courses).once.returns([@course])
      @student.expects(:concluded_courses).never
      @student.check_courses_right?(@teacher, :some_right).should be_true
    end

    it "should check concluded courses" do
      @student.expects(:courses).once.returns([])
      @student.expects(:concluded_courses).once.returns([@course])
      @student.check_courses_right?(@teacher, :some_right).should be_true
    end
  end

  context "search_messageable_users" do
    before(:once) do
      @admin = user_model
      @student = user_model
      tie_user_to_account(@admin, :membership_type => 'AccountAdmin')
      tie_user_to_account(@student, :membership_type => 'Student')
      set_up_course_with_users
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

    # convenience to search and then get the first page. none of these specs
    # should be putting more than a handful of users into the search results...
    # right?
    def search_messageable_users(viewing_user, *args)
      viewing_user.search_messageable_users(*args).paginate(:page => 1, :per_page => 20)
    end

    it "should include yourself even when not enrolled in courses" do
      @student = user_model
      search_messageable_users(@student).map(&:id).should include(@student.id)
    end

    it "should only return users from the specified context and type" do
      @course.enroll_user(@student, 'StudentEnrollment', :enrollment_state => 'active')

      search_messageable_users(@student, :context => "course_#{@course.id}").map(&:id).sort.
        should eql [@student, @this_section_user, @this_section_teacher, @other_section_user, @other_section_teacher].map(&:id).sort
      @student.count_messageable_users_in_course(@course).should eql 5

      search_messageable_users(@student, :context => "course_#{@course.id}_students").map(&:id).sort.
        should eql [@student, @this_section_user, @other_section_user].map(&:id).sort

      search_messageable_users(@student, :context => "group_#{@group.id}").map(&:id).sort.
        should eql [@this_section_user].map(&:id).sort
      @student.count_messageable_users_in_group(@group).should eql 1

      search_messageable_users(@student, :context => "section_#{@other_section.id}").map(&:id).sort.
        should eql [@other_section_user, @other_section_teacher].map(&:id).sort

      search_messageable_users(@student, :context => "section_#{@other_section.id}_teachers").map(&:id).sort.
        should eql [@other_section_teacher].map(&:id).sort
    end

    it "should not include users from other sections if visibility is limited to sections" do
      enrollment = @course.enroll_user(@student, 'StudentEnrollment', :enrollment_state => 'active', :limit_privileges_to_course_section => true)
      # we currently force limit_privileges_to_course_section to be false for students; override it in the db
      Enrollment.where(:id => enrollment).update_all(:limit_privileges_to_course_section => true)
      messageable_users = search_messageable_users(@student).map(&:id)
      messageable_users.should include @this_section_user.id
      messageable_users.should_not include @other_section_user.id

      messageable_users = search_messageable_users(@student, :context => "course_#{@course.id}").map(&:id)
      messageable_users.should include @this_section_user.id
      messageable_users.should_not include @other_section_user.id

      messageable_users = search_messageable_users(@student, :context => "section_#{@other_section.id}").map(&:id)
      messageable_users.should be_empty
    end

    it "should let students message the entire class by default" do
      @course.enroll_user(@student, 'StudentEnrollment', :enrollment_state => 'active')

      search_messageable_users(@student, :context => "course_#{@course.id}").map(&:id).sort.
        should eql [@student, @this_section_user, @this_section_teacher, @other_section_user, @other_section_teacher].map(&:id).sort
    end

    it "should not let users message the entire class if they cannot send_messages" do
      RoleOverride.create!(:context => @course.account, :permission => 'send_messages',
                           :enrollment_type => "StudentEnrollment", :enabled => false)
      @course.enroll_user(@student, 'StudentEnrollment', :enrollment_state => 'active')

      # can only message self or the admins
      search_messageable_users(@student, :context => "course_#{@course.id}").map(&:id).sort.
        should eql [@student, @this_section_teacher, @other_section_teacher].map(&:id).sort
    end

    it "should not include deleted users" do
      search_messageable_users(@student).map(&:id).should_not include(@deleted_user.id)
      search_messageable_users(@student, :search => @deleted_user.name).map(&:id).should be_empty
      search_messageable_users(@student, :strict_checks => false).map(&:id).should_not include(@deleted_user.id)
      search_messageable_users(@student, :strict_checks => false, :search => @deleted_user.name).map(&:id).should be_empty
    end

    it "should include deleted iff strict_checks=false" do
      @student.load_messageable_user(@deleted_user.id, :strict_checks => false).should_not be_nil
      @student.load_messageable_user(@deleted_user.id).should be_nil
    end

    it "should only include users from the specified section" do
      @course.enroll_user(@student, 'StudentEnrollment', :enrollment_state => 'active')
      messageable_users = search_messageable_users(@student, :context => "section_#{@course.default_section.id}").map(&:id)
      messageable_users.should include @this_section_user.id
      messageable_users.should_not include @other_section_user.id

      messageable_users = search_messageable_users(@student, :context => "section_#{@other_section.id}").map(&:id)
      messageable_users.should_not include @this_section_user.id
      messageable_users.should include @other_section_user.id
    end

    it "should include users from all sections if visibility is not limited to sections" do
      @course.enroll_user(@student, 'StudentEnrollment', :enrollment_state => 'active')
      messageable_users = search_messageable_users(@student).map(&:id)
      messageable_users.should include @this_section_user.id
      messageable_users.should include @other_section_user.id
    end

    it "should return users for a specified group if the receiver can access the group" do
      @course.enroll_user(@student, 'StudentEnrollment', :enrollment_state => 'active')

      search_messageable_users(@this_section_user, :context => "group_#{@group.id}").map(&:id).should eql [@this_section_user.id]
      # student can see it too, even though he's not in the group (since he can view the roster)
      search_messageable_users(@student, :context => "group_#{@group.id}").map(&:id).should eql [@this_section_user.id]
    end

    it "should respect section visibility when returning users for a specified group" do
      enrollment = @course.enroll_user(@student, 'StudentEnrollment', :enrollment_state => 'active', :limit_privileges_to_course_section => true)
      # we currently force limit_privileges_to_course_section to be false for students; override it in the db
      Enrollment.where(:id => enrollment).update_all(:limit_privileges_to_course_section => true)

      @group.users << @other_section_user

      search_messageable_users(@this_section_user, :context => "group_#{@group.id}").map(&:id).sort.should eql [@this_section_user.id, @other_section_user.id]
      @this_section_user.count_messageable_users_in_group(@group).should eql 2
      # student can only see people in his section
      search_messageable_users(@student, :context => "group_#{@group.id}").map(&:id).should eql [@this_section_user.id]
      @student.count_messageable_users_in_group(@group).should eql 1
    end

    it "should only show admins and the observed if the receiver is an observer" do
      @course.enroll_user(@admin, 'TeacherEnrollment', :enrollment_state => 'active')
      @course.enroll_user(@student, 'StudentEnrollment', :enrollment_state => 'active')

      observer = user_model

      enrollment = @course.enroll_user(observer, 'ObserverEnrollment', :enrollment_state => 'active')
      enrollment.associated_user_id = @student.id
      enrollment.save

      messageable_users = search_messageable_users(observer).map(&:id)
      messageable_users.should include @admin.id
      messageable_users.should include @student.id
      messageable_users.should_not include @this_section_user.id
      messageable_users.should_not include @other_section_user.id
    end

    it "should not show non-linked observers to students" do
      @course.enroll_user(@admin, 'TeacherEnrollment', :enrollment_state => 'active')
      student1, student2 = user_model, user_model
      @course.enroll_user(student1, 'StudentEnrollment', :enrollment_state => 'active')
      @course.enroll_user(student2, 'StudentEnrollment', :enrollment_state => 'active')

      observer = user_model
      enrollment = @course.enroll_user(observer, 'ObserverEnrollment', :enrollment_state => 'active')
      enrollment.associated_user_id = student1.id
      enrollment.save

      search_messageable_users(student1).map(&:id).should include observer.id
      student1.count_messageable_users_in_course(@course).should eql 8
      search_messageable_users(student2).map(&:id).should_not include observer.id
      student2.count_messageable_users_in_course(@course).should eql 7
    end

    it "should include all shared contexts and enrollment information" do
      @first_course = @course
      @first_course.enroll_user(@this_section_user, 'TaEnrollment', :enrollment_state => 'active')
      @first_course.enroll_user(@admin, 'TeacherEnrollment', :enrollment_state => 'active')

      @other_course = course_model
      @other_course.offer!
      @other_course.enroll_user(@admin, 'TeacherEnrollment', :enrollment_state => 'active')
      # other_section_user is a teacher in one course, student in another
      @other_course.enroll_user(@other_section_user, 'TeacherEnrollment', :enrollment_state => 'active')

      messageable_users = search_messageable_users(@admin)
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
      search_messageable_users(@admin).map(&:id).should include(@student.id)
      search_messageable_users(@student).map(&:id).should_not include(@admin.id)
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

      search_messageable_users(@admin, :context => "course_#{course1.id}", :ids => [@student.id]).should be_empty
      search_messageable_users(@admin, :context => "course_#{course2.id}", :ids => [@student.id]).should_not be_empty
      search_messageable_users(@student, :context => "course_#{course2.id}", :ids => [@admin.id]).should_not be_empty
    end

    it "should not rank results by default" do
      @course.enroll_user(@student, 'StudentEnrollment', :enrollment_state => 'active')

      # ordered by name (all the same), then id
      search_messageable_users(@student).map(&:id).
        should eql [@student.id, @this_section_teacher.id, @this_section_user.id, @other_section_user.id, @other_section_teacher.id]
    end

    context "concluded enrollments" do
      it "should return concluded enrollments" do # i.e. you can do a bare search for people who used to be in your class
        @course.enroll_user(@student, 'StudentEnrollment', :enrollment_state => 'active')
        @this_section_user_enrollment.conclude

        search_messageable_users(@this_section_user).map(&:id).should include @this_section_user.id
        search_messageable_users(@student).map(&:id).should include @this_section_user.id
      end

      it "should not return concluded student enrollments in the course" do # when browsing a course you should not see concluded enrollments
        @course.enroll_user(@student, 'StudentEnrollment', :enrollment_state => 'active')
        @course.complete!

        search_messageable_users(@this_section_user, :context => "course_#{@course.id}").map(&:id).should_not include @this_section_user.id
        # if the course was a concluded, a student should be able to browse it and message an admin (if if the admin's enrollment concluded too)
        search_messageable_users(@this_section_user, :context => "course_#{@course.id}").map(&:id).should include @this_section_teacher.id
        @this_section_user.count_messageable_users_in_course(@course).should eql 2 # just the admins
        search_messageable_users(@student, :context => "course_#{@course.id}").map(&:id).should_not include @this_section_user.id
        search_messageable_users(@student, :context => "course_#{@course.id}").map(&:id).should include @this_section_teacher.id
        @student.count_messageable_users_in_course(@course).should eql 2
      end

      it "should return concluded enrollments in the group if they are still members" do
        @course.enroll_user(@student, 'StudentEnrollment', :enrollment_state => 'active')
        @this_section_user_enrollment.conclude

        search_messageable_users(@this_section_user, :context => "group_#{@group.id}").map(&:id).should eql [@this_section_user.id]
        @this_section_user.count_messageable_users_in_group(@group).should eql 1
        search_messageable_users(@student, :context => "group_#{@group.id}").map(&:id).should eql [@this_section_user.id]
        @student.count_messageable_users_in_group(@group).should eql 1
      end

      it "should return concluded enrollments in the group and section if they are still members" do
        enrollment = @course.enroll_user(@student, 'StudentEnrollment', :enrollment_state => 'active', :limit_privileges_to_course_section => true)
        # we currently force limit_privileges_to_course_section to be false for students; override it in the db
        Enrollment.where(:id => enrollment).update_all(:limit_privileges_to_course_section => true)

        @group.users << @other_section_user
        @this_section_user_enrollment.conclude

        search_messageable_users(@this_section_user, :context => "group_#{@group.id}").map(&:id).sort.should eql [@this_section_user.id, @other_section_user.id]
        @this_section_user.count_messageable_users_in_group(@group).should eql 2
        # student can only see people in his section
        search_messageable_users(@student, :context => "group_#{@group.id}").map(&:id).should eql [@this_section_user.id]
        @student.count_messageable_users_in_group(@group).should eql 1
      end
    end

    context "admin_context" do
      it "should find users in the course" do
        search_messageable_users(@admin, :context => @course.asset_string, :admin_context => @course).map(&:id).sort.should ==
          [@this_section_teacher.id, @this_section_user.id, @other_section_user.id, @other_section_teacher.id]
      end

      it "should find users in the section" do
        search_messageable_users(@admin, :context => "section_#{@course.default_section.id}", :admin_context => @course.default_section).map(&:id).sort.should ==
          [@this_section_teacher.id, @this_section_user.id]
      end

      it "should find users in the group" do
        search_messageable_users(@admin, :context => @group.asset_string, :admin_context => @group).map(&:id).sort.should ==
          [@this_section_user.id]
      end
    end

    context "strict_checks" do
      it "should optionally show invited enrollments" do
        course(:active_all => true)
        student_in_course(:user_state => 'creation_pending')
        search_messageable_users(@teacher, :strict_checks => false).map(&:id).should include @student.id
      end

      it "should optionally show pending enrollments in unpublished courses" do
        course()
        teacher_in_course(:active_user => true)
        student_in_course()
        search_messageable_users(@teacher, :strict_checks => false, :context => @course.asset_string, :admin_context => @course).map(&:id).should include @student.id
      end
    end
  end

  context "tabs_available" do
    before(:once) { Account.default }
    it "should not include unconfigured external tools" do
      tool = Account.default.context_external_tools.new(:consumer_key => 'bob', :shared_secret => 'bob', :name => 'bob', :domain => "example.com")
      tool.course_navigation = {:url => "http://www.example.com", :text => "Example URL"}
      tool.save!
      tool.has_user_navigation.should == false
      user_model
      tabs = @user.profile.tabs_available(@user, :root_account => Account.default)
      tabs.map{|t| t[:id] }.should_not be_include(tool.asset_string)
    end

    it "should include configured external tools" do
      tool = Account.default.context_external_tools.new(:consumer_key => 'bob', :shared_secret => 'bob', :name => 'bob', :domain => "example.com")
      tool.user_navigation = {:url => "http://www.example.com", :text => "Example URL"}
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
    before :once do
      user_model
    end

    it "should find only users with avatars set" do
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
      @user.avatar_image_url = 'http://www.example.com'
      @user.avatar_image = { 'type' => 'twitter' }
      @user.avatar_image_url.should be_nil
    end

    it "should allow external url's to be assigned" do
      @user.avatar_image = { 'type' => 'external', 'url' => 'http://www.example.com/image.jpg' }
      @user.save!
      @user.reload.avatar_image_url.should == 'http://www.example.com/image.jpg'
    end

    it "should return a useful avatar_fallback_url" do
      User.avatar_fallback_url.should ==
        "https://#{HostUrl.default_host}/images/messages/avatar-50.png"
      User.avatar_fallback_url("/somepath").should ==
        "https://#{HostUrl.default_host}/somepath"
      HostUrl.expects(:default_host).returns('somedomain:3000')
      User.avatar_fallback_url("/path").should ==
        "https://somedomain:3000/path"
      User.avatar_fallback_url("//somedomain/path").should ==
        "https://somedomain/path"
      User.avatar_fallback_url("http://somedomain/path").should ==
        "http://somedomain/path"
      User.avatar_fallback_url("http://somedomain:3000/path").should ==
        "http://somedomain:3000/path"
      User.avatar_fallback_url(nil, OpenObject.new(:host => "foo", :protocol => "http://")).should ==
        "http://foo/images/messages/avatar-50.png"
      User.avatar_fallback_url("/somepath", OpenObject.new(:host => "bar", :protocol => "https://")).should ==
        "https://bar/somepath"
      User.avatar_fallback_url("//somedomain/path", OpenObject.new(:host => "bar", :protocol => "https://")).should ==
        "https://somedomain/path"
      User.avatar_fallback_url("http://somedomain/path", OpenObject.new(:host => "bar", :protocol => "https://")).should ==
        "http://somedomain/path"
      User.avatar_fallback_url('%{fallback}').should ==
        '%{fallback}'
    end

    describe "#clear_avatar_image_url_with_uuid" do
      before :once do
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
    before :once do
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

  describe "favorites" do
    before :once do
      @user = User.create!

      @courses = []
      (1..3).each do |x|
        course = course_with_student(:course_name => "Course #{x}", :user => @user, :active_all => true).course
        @courses << course
        @user.favorites.create!(context: course)
      end

      @user.save!
    end

    it "should default favorites to enrolled courses when favorite courses do not exist" do
      @user.favorites.by("Course").destroy_all
      @user.menu_courses.to_set.should == @courses.to_set
    end

    it "should only include favorite courses when set" do
      course = @courses.shift
      @user.favorites.where(context_type: "Course", context_id: course).first.destroy
      @user.menu_courses.to_set.should == @courses.to_set
    end

    context "sharding" do
      specs_require_sharding

      before :each do
        account2 = @shard1.activate { account_model }
        (4..6).each do |x|
          course = course_with_student(:course_name => "Course #{x}", :user => @user, :active_all => true, :account => account2).course
          @courses << course
          @user.favorites.create!(context: course)
        end
      end

      it "should include cross shard favorite courses" do
        @user.favorites.by("Course").where("id % 2 = 0").destroy_all
        @user.menu_courses.size.should eql(@courses.length / 2)
      end
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

    context "sharding" do
      specs_require_sharding

      it "should include enrollments from all shards" do
        user = User.create!
        course1 = Account.default.courses.create!
        course1.offer!
        e1 = course1.enroll_student(user)
        e2 = @shard1.activate do
          account2 = Account.create!
          course2 = account2.courses.create!
          course2.offer!
          course2.enroll_student(user)
        end
        user.cached_current_enrollments.should == [e1, e2]
      end
    end
  end

  describe "pseudonym_for_account" do
    before :once do
      @account1 = Account.create!
      @account2 = Account.create!
      @account3 = Account.create!
    end

    before :each do
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

    describe 'with cross-sharding' do
      specs_require_sharding
      it "should only search trusted shards" do
        @user = user(:active_all => 1, :account => @account1)
        @shard1.activate do
          @account2 = Account.create!
          @pseudonym1 = pseudonym(@user, :account => @account2)
        end

        @shard2.activate do
          @account3 = Account.create!
          @pseudonym2 = pseudonym(@user, :account => @account3)
        end

        @account1.stubs(:trusted_account_ids).returns([@account3.id])

        @shard1.expects(:activate).never
        @shard2.expects(:activate).once

        pseudonym = @user.find_pseudonym_for_account(@account1)
        pseudonym.should == @psuedonym2
      end
    end

    it "should create a copy of an existing pseudonym" do
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
      # no pseudonyms
      user
      @user.find_or_initialize_pseudonym_for_account(@account1).should be_nil

      # auto-generated password
      @user.pseudonyms.create!(:account => @account2, :unique_id => 'bracken@instructure.com')
      @user.find_or_initialize_pseudonym_for_account(@account1).should be_nil

      # delegated auth
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

    context "sharding" do
      specs_require_sharding

      before :once do
        @shard1.activate do
          account = Account.create!
          user_with_pseudonym(:active_all => 1, :account => account, :password => 'qwerty')
        end
      end

      it "should find a pseudonym in another shard" do
        @p2 = Account.site_admin.pseudonyms.create!(:user => @user, :unique_id => 'user')
        @p2.any_instantiation.stubs(:works_for_account?).with(Account.site_admin, false).returns(true)
        @user.find_pseudonym_for_account(Account.site_admin).should == @p2
      end

      it "should copy a pseudonym from another shard" do
        p = @user.find_or_initialize_pseudonym_for_account(Account.site_admin)
        p.should be_new_record
        p.save!
        p.valid_password?('qwerty').should be_true
      end
    end
  end

  describe "can_be_enrolled_in_course?" do
    before :once do
      course active_all: true
    end

    it "should allow a user with a pseudonym in the course's root account" do
      user_with_pseudonym account: @course.root_account, active_all: true
      @user.can_be_enrolled_in_course?(@course).should be_true
    end

    it "should allow a temporary user with an existing enrollment but no pseudonym" do
      @user = User.create! { |u| u.workflow_state = 'creation_pending' }
      @course.enroll_student(@user)
      @user.can_be_enrolled_in_course?(@course).should be_true
    end

    it "should not allow a registered user with an existing enrollment but no pseudonym" do
      user active_all: true
      @course.enroll_student(@user)
      @user.can_be_enrolled_in_course?(@course).should be_false
    end

    it "should not allow a user with neither an enrollment nor a pseudonym" do
      user active_all: true
      @user.can_be_enrolled_in_course?(@course).should be_false
    end
  end

  describe "email_channel" do
    it "should not return retired channels" do
      u = User.create!
      retired = u.communication_channels.create!(:path => 'retired@example.com', :path_type => 'email') { |cc| cc.workflow_state = 'retired'}
      u.email_channel.should be_nil
      active = u.communication_channels.create!(:path => 'active@example.com', :path_type => 'email') { |cc| cc.workflow_state = 'active'}
      u.email_channel.should == active
    end
  end

  describe "sis_pseudonym_for" do
    let_once(:course1) { course :active_all => true, :account => Account.default }
    let_once(:course2) { course :active_all => true, :account => account2 }
    let_once(:account1) { account_model }
    let_once(:account2) { account_model }
    let_once(:u) { User.create! }

    it "should return active pseudonyms only" do
      u.pseudonyms.create!(:account => Account.default, :unique_id => "user2@example.com", :password => "asdfasdf", :password_confirmation => "asdfasdf") {|x| x.workflow_state = 'deleted'; x.sis_user_id = "user2" }
      u.sis_pseudonym_for(course1).should be_nil
      @p = u.pseudonyms.create!(:account => Account.default, :unique_id => "user1@example.com", :password => "asdfasdf", :password_confirmation => "asdfasdf") {|x| x.workflow_state = 'active'; x.sis_user_id = "user1" }
      u.sis_pseudonym_for(course1).should == @p
    end

    it "should return pseudonyms in the right account" do
      other_account = account_model
      u.pseudonyms.create!(:account => other_account, :unique_id => "user1@example.com", :password => "asdfasdf", :password_confirmation => "asdfasdf") {|x| x.workflow_state = 'active'; x.sis_user_id = "user1" }
      u.sis_pseudonym_for(course1).should be_nil
      @p = u.pseudonyms.create!(:account => Account.default, :unique_id => "user2@example.com", :password => "asdfasdf", :password_confirmation => "asdfasdf") {|x| x.workflow_state = 'active'; x.sis_user_id = "user2" }
      u.sis_pseudonym_for(course1).should == @p
    end

    it "should return pseudonyms with a sis id only" do
      u.pseudonyms.create!(:account => Account.default, :unique_id => "user1@example.com", :password => "asdfasdf", :password_confirmation => "asdfasdf") {|x| x.workflow_state = 'active' }
      u.sis_pseudonym_for(course1).should be_nil
      @p = u.pseudonyms.create!(:account => Account.default, :unique_id => "user2@example.com", :password => "asdfasdf", :password_confirmation => "asdfasdf") {|x| x.workflow_state = 'active'; x.sis_user_id = "user2" }
      u.sis_pseudonym_for(course1).should == @p
    end

    it "should find the right root account for a course" do
      p = account2.pseudonyms.create!(:user => u, :unique_id => 'user') { |p| p.sis_user_id = 'abc'}
      u.sis_pseudonym_for(course2).should == p
    end

    it "should find the right root account for a group" do
      @group = group :group_context => course2
      p = account2.pseudonyms.create!(:user => u, :unique_id => 'user') { |p| p.sis_user_id = 'abc'}
      u.sis_pseudonym_for(@group).should == p
    end

    it "should find the right root account for a non-root-account" do
      @root_account = account1
      @account = @root_account.sub_accounts.create!
      p = @root_account.pseudonyms.create!(:user => u, :unique_id => 'user') { |p| p.sis_user_id = 'abc'}
      u.sis_pseudonym_for(@account).should == p
    end

    it "should find the right root account for a root account" do
      p = account1.pseudonyms.create!(:user => u, :unique_id => 'user') { |p| p.sis_user_id = 'abc'}
      u.sis_pseudonym_for(account1).should == p
    end

    it "should bail if it can't find a root account" do
      context = Course.new # some context that doesn't have an account
      (lambda {u.sis_pseudonym_for(context)}).should raise_error("could not resolve root account")
    end

    it "should include a pseudonym from a trusted account" do
      p = account2.pseudonyms.create!(user: u, unique_id: 'user') { |p| p.sis_user_id = 'abc' }
      account1.stubs(:trust_exists?).returns(true)
      account1.stubs(:trusted_account_ids).returns([account2.id])
      u.sis_pseudonym_for(account1).should be_nil
      u.sis_pseudonym_for(account1, true).should == p
    end

    context "sharding" do
      specs_require_sharding

      it "should find a pseudonym on a different shard" do
        @shard1.activate do
          @user = User.create!
        end
        @pseudonym = Account.default.pseudonyms.create!(:user => @user, :unique_id => 'user') { |p| p.sis_user_id = 'abc' }
        @shard2.activate do
          @user.sis_pseudonym_for(Account.default).should == @pseudonym
        end
        @shard1.activate do
          @user.sis_pseudonym_for(Account.default).should == @pseudonym
        end
      end
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
      before(:once) { course_with_student(:active_all => true) }
      it "should include own scheduled appointments" do
        ag = AppointmentGroup.create!(:title => 'test appointment', :contexts => [@course], :new_appointments => [[Time.now, Time.now + 1.hour], [Time.now + 1.hour, Time.now + 2.hour]])
        ag.appointments.first.reserve_for(@user, @user)
        events = @user.calendar_events_for_calendar
        events.size.should eql 1
        events.first.title.should eql 'test appointment'
      end

      it "should include manageable appointments" do
        @user = @course.instructors.first
        ag = AppointmentGroup.create!(:title => 'test appointment', :contexts => [@course], :new_appointments => [[Time.now, Time.now + 1.hour]])
        events = @user.calendar_events_for_calendar
        events.size.should eql 1
        events.first.title.should eql 'test appointment'
      end

      it "should not include unpublished assignments when draft_state is enabled" do
        @course.enable_feature!(:draft_state)
        as = @course.assignments.create!({:title => "Published", :due_at => 2.days.from_now})
        as.publish
        as2 = @course.assignments.create!({:title => "Unpublished", :due_at => 2.days.from_now})
        as2.unpublish
        events = @user.calendar_events_for_calendar(:contexts => [@course])
        events.size.should eql 1
        events.first.title.should eql 'Published'
      end
    end

    describe "upcoming_events" do
      before(:once) { course_with_teacher(:active_all => true) }
      it "handles assignments where the applied due_at is nil" do
        assignment = @course.assignments.create!(:title => "Should not throw",
                                                 :due_at => 1.days.from_now)
        assignment2 = @course.assignments.create!(:title => "Should not throw2",
                                                  :due_at => 1.days.from_now)
        section = @course.course_sections.create!(:name => "VDD Section")
        override = assignment.assignment_overrides.build
        override.set = section
        override.due_at = nil
        override.due_at_overridden = true
        override.save!

        events = []
        # handles comparison of nil due dates if that is what applies to the
        # user instead of failing.
        expect do
          events = @user.upcoming_events(:end_at => 1.week.from_now)
        end.to_not raise_error

        events.first.should == assignment2
        events.second.should == assignment
      end

      it "doesn't show unpublished assignments if draft_state is enabled" do
        @course.enable_feature!(:draft_state)
        assignment = @course.assignments.create!(:title => "not published", :due_at => 1.days.from_now)
        assignment.unpublish
        assignment2 = @course.assignments.create!(:title => "published", :due_at => 1.days.from_now)
        assignment2.publish
        events = []
        events = @user.upcoming_events(:end_at => 1.week.from_now)
        events.first.should == assignment2
      end

    end
  end

  describe "select_upcoming_assignments" do
    it "filters based on assignment date for asignments the user cannot delete" do
      time = Time.now + 1.day
      assignments = [stub, stub, stub]
      user = User.new
      assignments.each do |assignment|
        assignment.stubs(:due_at => time)
        assignment.expects(:grants_right?).with(user, :delete).returns false
      end
      user.select_upcoming_assignments(assignments,{:end_at => time}).should == assignments
    end

    it "returns assignments that have an override between now and end_at opt" do
      assignments = [stub, stub, stub, stub]
      Timecop.freeze(Time.utc(2013,3,13,0,0)) do
        user = User.new
        due_date1 = {:due_at => Time.now + 1.day}
        due_date2 = {:due_at => Time.now + 1.week}
        due_date3 = {:due_at => 2.weeks.from_now }
        due_date4 = {:due_at => nil }
        assignments.each do |assignment|
          assignment.expects(:grants_right?).with(user, :delete).returns true
        end
        assignments.first.expects(:dates_hash_visible_to).with(user).
          returns [due_date1]
        assignments.second.expects(:dates_hash_visible_to).with(user).
          returns [due_date2]
        assignments.third.expects(:dates_hash_visible_to).with(user).
          returns [due_date3]
        assignments[3].expects(:dates_hash_visible_to).with(user).
          returns [due_date4]
        upcoming_assignments = user.select_upcoming_assignments(assignments,{
          :end_at => 1.week.from_now
        })
        upcoming_assignments.should include assignments.first
        upcoming_assignments.should include assignments.second
        upcoming_assignments.should_not include assignments.third
        upcoming_assignments.should_not include assignments[3]
      end
    end
  end

  describe "assignments_visibile_in_course" do
    before do
      @course = course(:active_course => true)
      @course_section = @course.course_sections.create
      @student1 = User.create
      @student2 = User.create
      @student3 = User.create
      @assignment = Assignment.create!(title: "title", context: @course, only_visible_to_overrides: true)
      @course.enroll_student(@student2, :enrollment_state => 'active')
      @section = @course.course_sections.create!(name: "test section")
      student_in_section(@section, user: @student1)
      create_section_override_for_assignment(@assignment, {course_section: @section})
      @course.reload
    end

    context "draft state off" do
      before {@course.disable_feature!(:draft_state)}
      it "should return all active assignments" do
        @student1.assignments_visibile_in_course(@course).include?(@assignment).should be_true
        @student2.assignments_visibile_in_course(@course).include?(@assignment).should be_true
      end
    end

    context "draft state on" do
      before {@course.enable_feature!(:draft_state)}
      context "differentiated_assignment on" do
        before {@course.enable_feature!(:differentiated_assignments)}
        it "should return assignments only when a student has overrides" do
          @student1.assignments_visibile_in_course(@course).include?(@assignment).should be_true
          @student2.assignments_visibile_in_course(@course).include?(@assignment).should be_false
        end

        it "should not return students outside the class" do
          @student3.assignments_visibile_in_course(@course).include?(@assignment).should be_false
        end
      end

      context "differentiated_assignment off" do
        before {@course.disable_feature!(:differentiated_assignments)}
        it "should return all published assignments" do
          @student1.assignments_visibile_in_course(@course).include?(@assignment).should be_true
          @student2.assignments_visibile_in_course(@course).include?(@assignment).should be_true
        end
      end
    end
  end

  describe "assignments_needing_submitting" do
    # NOTE: More thorough testing of the Assignment#not_locked named scope is in assignment_spec.rb
    context "locked assignments" do
      before :once do
        course_with_student(:active_all => true)
        assignment_quiz([], :course => @course, :user => @user)
      end

      before :each do
        user_session(@user)
        # Setup default values for tests (leave unsaved for easy changes)
        @quiz.unlock_at = nil
        @quiz.lock_at = nil
        @quiz.due_at = 2.days.from_now
      end

      it "includes assignments with no due date but have overrides that are due" do
        @quiz.due_at = nil
        @quiz.save!
        section = @course.course_sections.create! :name => "Test"
        @student = student_in_section section
        override = @quiz.assignment.assignment_overrides.build
        override.title = "Shows up in todos"
        override.set_type = 'CourseSection'
        override.set = section
        override.due_at = 1.weeks.from_now - 1.day
        override.due_at_overridden = true
        override.save!
        @student.assignments_needing_submitting(:contexts => [@course]).
          should include @quiz.assignment
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

    it "should not include unpublished assignments when draft_state is enabled" do
      course_with_student_logged_in(:active_all => true)
      @course.enable_feature!(:draft_state)
      assignment_quiz([], :course => @course, :user => @user)
      @assignment.unpublish
      @quiz.unlock_at = 1.hour.ago
      @quiz.lock_at = nil
      @quiz.due_at = 2.days.from_now
      @quiz.save!
      assignment_quiz([], :course => @course, :user => @user)
      @quiz.unlock_at = 1.hour.ago
      @quiz.lock_at = nil
      @quiz.due_at = 2.days.from_now
      @quiz.save!

      @student.assignments_needing_submitting(:contexts => [@course]).count.should == 1
    end

    it "should always have the only_visible_to_overrides attribute" do
      course_with_student_logged_in(:active_all => true)
      assignment_quiz([], :course => @course, :user => @user)
      @quiz.unlock_at = nil
      @quiz.lock_at = nil
      @quiz.due_at = 2.days.from_now
      @quiz.save!
      assignments = @student.assignments_needing_submitting(:contexts => [@course])
      assignments[0].has_attribute?(:only_visible_to_overrides).should be_true
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
    let_once :ids do
      ids = []
      ids << User.create!(:name => "John Johnson")
      ids << User.create!(:name => "John John")
    end

    it "should sort lexicographically" do
      User.order_by_sortable_name.where(id: ids).all.map(&:sortable_name).should == ["John, John", "Johnson, John"]
    end

    it "should sort support direction toggle" do
      User.order_by_sortable_name(:direction => :descending).where(id: ids).all.map(&:sortable_name).should == ["Johnson, John", "John, John"]
    end

    it "should sort support direction toggle with a prior select" do
      User.select([:id, :sortable_name]).order_by_sortable_name(:direction => :descending).where(id: ids).all.map(&:sortable_name).should == ["Johnson, John", "John, John"]
    end

    it "should sort by the current locale with pg_collkey if possible" do
      pending "requires postgres" unless User.connection.adapter_name == 'PostgreSQL'
      pending "requires pg_collkey on the server" if User.connection.select_value("SELECT COUNT(*) FROM pg_proc WHERE proname='collkey'").to_i == 0
      begin
        Bundler.require 'icu'
      rescue LoadError
        pending "requires icu locally"
      end
      I18n.locale = :es
      User.sortable_name_order_by_clause.should match /es/
      User.sortable_name_order_by_clause.should_not match /root/
      # english has no specific sorting rules, so use root
      I18n.locale = :en
      User.sortable_name_order_by_clause.should_not match /es/
      User.sortable_name_order_by_clause.should match /root/
    end
  end

  describe "quota" do
    before(:once) { user }
    it "should default to User.default_storage_quota" do
      @user.quota.should eql User.default_storage_quota
    end

    it "should sum up associated root account quotas" do
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
    before :once do
      user_with_pseudonym
    end
    let_once(:root_acct1) { Account.create! }
    let_once(:root_acct2) { Account.create! }

    it "work for just root accounts" do
      @user.user_account_associations.create!(:account_id => root_acct2.id)
      @user.reload
      @user.common_account_chain(root_acct1).should == []
      @user.common_account_chain(root_acct2).should eql [root_acct2]
    end

    it "should work for one level of sub accounts" do
      root_acct = root_acct1
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
      root_acct = root_acct1
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

  describe "mfa_settings" do
    let_once(:user) { User.create! }

    it "should be :disabled for unassociated users" do
      user = User.new
      user.mfa_settings.should == :disabled
    end

    it "should inherit from the account" do
      user.pseudonyms.create!(:account => Account.default, :unique_id => 'user')
      Account.default.settings[:mfa_settings] = :required
      Account.default.save!

      user.mfa_settings.should == :required

      Account.default.settings[:mfa_settings] = :optional
      Account.default.save!
      user = User.find(user())
      user.mfa_settings.should == :optional
    end

    it "should be the most-restrictive if associated with multiple accounts" do
      disabled_account = Account.create!(:settings => { :mfa_settings => :disabled })
      optional_account = Account.create!(:settings => { :mfa_settings => :optional })
      required_account = Account.create!(:settings => { :mfa_settings => :required })

      p1 = user.pseudonyms.create!(:account => disabled_account, :unique_id => 'user')
      user = User.find(user())
      user.mfa_settings.should == :disabled

      p2 = user.pseudonyms.create!(:account => optional_account, :unique_id => 'user')
      user = User.find(user)
      user.mfa_settings.should == :optional

      p3 = user.pseudonyms.create!(:account => required_account, :unique_id => 'user')
      user = User.find(user)
      user.mfa_settings.should == :required

      p1.destroy
      user = User.find(user)
      user.mfa_settings.should == :required

      p2.destroy
      user = User.find(user)
      user.mfa_settings.should == :required
    end

    it "should be required if admin and required_for_admins" do
      account = Account.create!(:settings => { :mfa_settings => :required_for_admins })
      user.pseudonyms.create!(:account => account, :unique_id => 'user')

      user.mfa_settings.should == :optional
      account.account_users.create!(user: user)
      user.reload
      user.mfa_settings.should == :required
    end

    it "required_for_admins shouldn't get confused by admins in other accounts" do
      account = Account.create!(:settings => { :mfa_settings => :required_for_admins })
      user.pseudonyms.create!(:account => account, :unique_id => 'user')
      user.pseudonyms.create!(:account => Account.default, :unique_id => 'user')

      Account.default.account_users.create!(user: user)

      user.mfa_settings.should == :optional
    end
  end

  context "crocodoc attributes" do
    before :once do
      Setting.set 'crocodoc_counter', 998
      @user = User.create! :short_name => "Bob"
    end

    it "should generate a unique crocodoc_id" do
      @user.crocodoc_id.should be_nil
      @user.crocodoc_id!.should eql 999
      @user.crocodoc_user.should eql '999,Bob'
    end

    it "should scrub commas from the user name" do
      @user.short_name = "Smith, Bob"
      @user.save!
      @user.crocodoc_user.should eql '999,Smith Bob'
    end

    it "should not change a user's crocodoc_id" do
      @user.update_attribute :crocodoc_id, 2
      @user.crocodoc_id!.should eql 2
      Setting.get('crocodoc_counter', 0).to_i.should eql 998
    end
  end

  context "assignments_needing_grading" do
    before :once do
      # create courses and sections
      @course1 = course_with_teacher(:active_all => true).course
      @course2 = course_with_teacher(:active_all => true, :user => @teacher).course
      @section1b = @course1.course_sections.create!(:name => 'section B')
      @section2b = @course2.course_sections.create!(:name => 'section B')

      # put a student in each section
      @studentA = user_with_pseudonym(:active_all => true, :name => 'StudentA', :username => 'studentA@instructure.com')
      @studentB = user_with_pseudonym(:active_all => true, :name => 'StudentB', :username => 'studentB@instructure.com')
      @course1.enroll_student(@studentA).update_attribute(:workflow_state, 'active')
      @section1b.enroll_user(@studentB, 'StudentEnrollment', 'active')
      @course2.enroll_student(@studentA).update_attribute(:workflow_state, 'active')
      @section2b.enroll_user(@studentB, 'StudentEnrollment', 'active')

      # set up a TA, section-limited in one course and not the other
      @ta = user_with_pseudonym(:active_all => true, :name => 'TA', :username => 'ta@instructure.com')
      @course1.enroll_user(@ta, 'TaEnrollment', :enrollment_state => 'active', :limit_privileges_to_course_section => true)
      @course2.enroll_user(@ta, 'TaEnrollment', :enrollment_state => 'active', :limit_privileges_to_course_section => false)

      # make some assignments and submissions
      [@course1, @course2].each do |course|
        assignment = course.assignments.create!(:title => "some assignment", :submission_types => ['online_text_entry'])
        [@studentA, @studentB].each do |student|
          assignment.submit_homework student, body: "submission for #{student.name}"
        end
      end
    end

    it "should count assignments with ungraded submissions across multiple courses" do
      @teacher.assignments_needing_grading.size.should eql(2)
      @teacher.assignments_needing_grading.should be_include(@course1.assignments.first)
      @teacher.assignments_needing_grading.should be_include(@course2.assignments.first)

      # grade one submission for one assignment; these numbers don't change
      @course1.assignments.first.grade_student(@studentA, :grade => "1")
      @teacher.assignments_needing_grading.size.should eql(2)
      @teacher.assignments_needing_grading.should be_include(@course1.assignments.first)
      @teacher.assignments_needing_grading.should be_include(@course2.assignments.first)

      # grade the other submission; now course1's assignment no longer needs grading
      @course1.assignments.first.grade_student(@studentB, :grade => "1")
      @teacher = User.find(@teacher.id)
      @teacher.assignments_needing_grading.size.should eql(1)
      @teacher.assignments_needing_grading.should be_include(@course2.assignments.first)
    end

    it "should only count submissions in accessible course sections" do
      @ta.assignments_needing_grading.size.should eql(2)
      @ta.assignments_needing_grading.should be_include(@course1.assignments.first)
      @ta.assignments_needing_grading.should be_include(@course2.assignments.first)

      # grade student A's submissions in both courses; now course1's assignment
      # should not show up because the TA doesn't have access to studentB's submission
      @course1.assignments.first.grade_student(@studentA, :grade => "1")
      @course2.assignments.first.grade_student(@studentA, :grade => "1")
      @ta = User.find(@ta.id)
      @ta.assignments_needing_grading.size.should eql(1)
      @ta.assignments_needing_grading.should be_include(@course2.assignments.first)

      # but if we enroll the TA in both sections of course1, it should be accessible
      @course1.enroll_user(@ta, 'TaEnrollment', :enrollment_state => 'active', :section => @section1b,
                          :allow_multiple_enrollments => true, :limit_privileges_to_course_section => true)
      @ta = User.find(@ta.id)
      @ta.assignments_needing_grading.size.should eql(2)
      @ta.assignments_needing_grading.should be_include(@course1.assignments.first)
      @ta.assignments_needing_grading.should be_include(@course2.assignments.first)
    end

    it "should limit the number of returned assignments" do
      assignment_ids = create_records(Assignment, 20.times.map{ |x| {title: "excess assignment #{x}", submission_types: 'online_text_entry', workflow_state: "available", context_type: "Course", context_id: @course1.id} })
      create_records(Submission, assignment_ids.map{ |id| {assignment_id: id, user_id: @studentB.id, body: "hello", workflow_state: "submitted", submission_type: 'online_text_entry'} })
      @teacher.assignments_needing_grading.size.should == 15
    end

    it "should always have the only_visible_to_overrides attribute" do
      @teacher.assignments_needing_grading.each {|a| a.has_attribute?(:only_visible_to_overrides).should be_true }
    end

    context "sharding" do
      specs_require_sharding

      before :once do
        @shard1.activate do
          @account = Account.create!
          @course3 = @account.courses.create!
          @course3.offer!
          @course3.enroll_teacher(@teacher).accept!
          @course3.enroll_student(@studentA).accept!
          @course3.enroll_student(@studentB).accept!
          @assignment3 = @course3.assignments.create!(:title => "some assignment", :submission_types => ['online_text_entry'])
          @assignment3.submit_homework @studentA, body: "submission for A"
        end
      end

      it "should find assignments from all shards" do
        @teacher.assignments_needing_grading.sort_by(&:id).should ==
            [@course1.assignments.first, @course2.assignments.first, @assignment3].sort_by(&:id)
      end

      it "should honor ignores for a separate shard" do
        @teacher.ignore_item!(@assignment3, 'grading')
        @teacher.assignments_needing_grading.sort_by(&:id).should ==
            [@course1.assignments.first, @course2.assignments.first].sort_by(&:id)

        @shard1.activate do
          @assignment3.submit_homework @studentB, :submission_type => "online_text_entry", :body => "submission for B"
        end
        @teacher = User.find(@teacher)
        @teacher.assignments_needing_grading.size.should == 3
      end

      it "should apply a global limit" do
        @teacher.assignments_needing_grading(:limit => 1).length.should == 1
      end
    end
  end

  describe ".initial_enrollment_type_from_type" do
    it "should return supported initial_enrollment_type values" do
      User.initial_enrollment_type_from_text('StudentEnrollment').should == 'student'
      User.initial_enrollment_type_from_text('StudentViewEnrollment').should == 'student'
      User.initial_enrollment_type_from_text('TeacherEnrollment').should == 'teacher'
      User.initial_enrollment_type_from_text('TaEnrollment').should == 'ta'
      User.initial_enrollment_type_from_text('ObserverEnrollment').should == 'observer'
      User.initial_enrollment_type_from_text('DesignerEnrollment').should be_nil
      User.initial_enrollment_type_from_text('UnknownThing').should be_nil
      User.initial_enrollment_type_from_text(nil).should be_nil
      # Non-enrollment type strings
      User.initial_enrollment_type_from_text('student').should == 'student'
      User.initial_enrollment_type_from_text('teacher').should == 'teacher'
      User.initial_enrollment_type_from_text('ta').should == 'ta'
      User.initial_enrollment_type_from_text('observer').should == 'observer'
    end
  end

  describe "all_accounts" do
    specs_require_sharding

    it "should include accounts from multiple shards" do
      user
      Account.site_admin.account_users.create!(user: @user)
      @shard1.activate do
        @account2 = Account.create!
        @account2.account_users.create!(user: @user)
      end

      @user.all_accounts.map(&:id).sort.should == [Account.site_admin, @account2].map(&:id).sort
    end
  end

  describe "all_pseudonyms" do
    specs_require_sharding

    it "should include pseudonyms from multiple shards" do
      user_with_pseudonym(:active_all => 1)
      @p1 = @pseudonym
      @shard1.activate do
        account = Account.create!
        @p2 = account.pseudonyms.create!(:user => @user, :unique_id => 'abcd')
      end

      @user.all_pseudonyms.should == [@p1, @p2]
    end
  end

  describe "active_pseudonyms" do
    before :once do
      user_with_pseudonym(:active_all => 1)
    end

    it "should include active pseudonyms" do
      @user.active_pseudonyms.should == [@pseudonym]
    end

    it "should not include deleted pseudonyms" do
      @pseudonym.destroy
      @user.active_pseudonyms.should be_empty
    end
  end

  describe "preferred_gradebook_version" do
    let(:user) { User.new }
    let(:course) { mock('course') }
    subject { user.preferred_gradebook_version }

    context "prefers gb2" do
      before { user.stubs(:preferences => { :gradebook_version => '2' }) }
      it { should == '2' }
    end

    context "prefers srgb" do
      before { user.stubs(:preferences => { :gradebook_version => 'srgb' }) }
      it { should == 'srgb' }
    end

    context "nil preference" do
      before { user.stubs(:preferences => { :gradebook_version => nil }) }
      it { should == '2' }
    end
  end

  describe "manual_mark_as_read" do
    let(:user) { User.new }
    subject { user.manual_mark_as_read? }

    context 'default' do
      it { should be_false }
    end

    context 'after being set to true' do
      before { user.stubs(preferences: { manual_mark_as_read: true }) }
      it     { should be_true }
    end

    context 'after being set to false' do
      before { user.stubs(preferences: { manual_mark_as_read: false }) }
      it     { should be_false }
    end
  end

  describe "things excluded from json serialization" do
    it "excludes collkey" do
      # Ruby 1.9 does not like html that includes the collkey, so
      # don't ship it to the page (even as json).
      user = User.create!
      users = User.order_by_sortable_name
      users.first.as_json['user'].keys.should_not include('collkey')
    end
  end

  describe '#grants_right?' do
    let_once(:subaccount) do
      account = Account.create!
      account.root_account_id = Account.default.id
      account.save!
      account
    end

    let_once(:site_admin) do
      user = User.create!
      Account.site_admin.account_users.create!(user: user)
      Account.default.account_users.create!(user: user)
      user
    end

    let_once(:local_admin) do
      user = User.create!
      Account.default.account_users.create!(user: user)
      subaccount.account_users.create!(user: user)
      user
    end

    let_once(:user) do
      user = User.create!
      subaccount.account_users.create!(user: user)
      user
    end


    it 'allows site admins to manage their own logins' do
      site_admin.grants_right?(site_admin, :manage_logins).should be_true
    end

    it 'allows local admins to manage their own logins' do
      local_admin.grants_right?(local_admin, :manage_logins).should be_true
    end

    it 'allows site admins to manage local admins logins' do
      local_admin.grants_right?(site_admin, :manage_logins).should be_true
    end

    it 'forbids local admins from managing site admins logins' do
      site_admin.grants_right?(local_admin, :manage_logins).should be_false
    end

    it 'only considers root accounts when checking subset permissions' do
      user.grants_right?(local_admin, :manage_logins).should be_true
    end
  end

  describe "#conversation_context_codes" do
    before :once do
      @user = user(:active_all => true)
      course_with_student(:user => @user, :active_all => true)
      group_with_user(:user => @user, :active_all => true)
    end

    it "should include courses" do
      @user.conversation_context_codes.should include(@course.asset_string)
    end

    it "should include concluded courses" do
      @enrollment.workflow_state = 'completed'
      @enrollment.save!
      @user.conversation_context_codes.should include(@course.asset_string)
    end

    it "should optionally not include concluded courses" do
      @enrollment.update_attribute(:workflow_state, 'completed')
      @user.conversation_context_codes(false).should_not include(@course.asset_string)
    end

    it "should include groups" do
      @user.conversation_context_codes.should include(@group.asset_string)
    end

    describe "sharding" do
      specs_require_sharding

      before :once do
        @shard1_account = @shard1.activate{ Account.create! }
      end

      it "should include courses on other shards" do
        course_with_student(:account => @shard1_account, :user => @user, :active_all => true)
        @user.conversation_context_codes.should include(@course.asset_string)
      end

      it "should include concluded courses on other shards" do
        course_with_student(:account => @shard1_account, :user => @user, :active_all => true)
        @enrollment.workflow_state = 'completed'
        @enrollment.save!
        @user.conversation_context_codes.should include(@course.asset_string)
      end

      it "should optionally not include concluded courses on other shards" do
        course_with_student(:account => @shard1_account, :user => @user, :active_all => true)
        @enrollment.update_attribute(:workflow_state, 'completed')
        @user.conversation_context_codes(false).should_not include(@course.asset_string)
      end

      it "should include groups on other shards" do
        # course is just to associate the get shard1 in @user's associated shards
        course_with_student(:account => @shard1_account, :user => @user, :active_all => true)
        @shard1.activate{ group_with_user(:user => @user, :active_all => true) }
        @user.conversation_context_codes.should include(@group.asset_string)
      end

      it "should include the default shard version of the asset string" do
        course_with_student(:account => @shard1_account, :user => @user, :active_all => true)
        default_asset_string = @course.asset_string
        @shard1.activate{ @user.conversation_context_codes.should include(default_asset_string) }
      end
    end
  end

  describe "#stamp_logout_time!" do
    before :once do
      user_model
    end

    it "should update last_logged_out" do
      now = Time.zone.now
      Timecop.freeze(now) { @user.stamp_logout_time! }
      @user.reload.last_logged_out.to_i.should == now.to_i
    end

    context "sharding" do
      specs_require_sharding

      it "should update regardless of current shard" do
        @shard1.activate{ @user.stamp_logout_time! }
        @user.reload.last_logged_out.should_not be_nil
      end
    end
  end

  describe "delete_enrollments" do
    before do
      course
      2.times { @course.course_sections.create! }
      2.times { @course.assignments.create! }
    end

    it "should batch DueDateCacher jobs" do
      DueDateCacher.expects(:recompute).never
      DueDateCacher.expects(:recompute_course).twice # sync_enrollments and destroy_enrollments
      test_student = @course.student_view_student
      test_student.destroy
      test_student.reload.enrollments.each { |e| e.should be_deleted }
    end
  end

  describe "otp remember me cookie" do
    before do
      @user = User.new
      @user.otp_secret_key = ROTP::Base32.random_base32
    end

    it "should add an ip to an existing cookie" do
      cookie1 = @user.otp_secret_key_remember_me_cookie(Time.now.utc, nil, 'ip1')
      cookie2 = @user.otp_secret_key_remember_me_cookie(Time.now.utc, cookie1, 'ip2')
      @user.validate_otp_secret_key_remember_me_cookie(cookie1, 'ip1').should be_true
      @user.validate_otp_secret_key_remember_me_cookie(cookie1, 'ip2').should be_false
      @user.validate_otp_secret_key_remember_me_cookie(cookie2, 'ip1').should be_true
      @user.validate_otp_secret_key_remember_me_cookie(cookie2, 'ip2').should be_true
    end
  end

  it "should reset its conversation counter when told to" do
    user = user_model
    user.stubs(:conversations).returns Struct.new(:unread).new(Array.new(5))
    user.reset_unread_conversations_counter
    user.reload.unread_conversations_count.should == 5
  end
end
