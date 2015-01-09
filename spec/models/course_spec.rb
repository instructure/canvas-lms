# Copyright (C) 2011 - 2012 Instructure, Inc.
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

require 'csv'
require 'socket'

describe Course do
  before :once do
    Account.default
    Account.default.default_enrollment_term
  end

  before :each do
    @course = Account.default.courses.build
    @course.workflow_state = 'claimed'
    @course.root_account = Account.default
    @course.enrollment_term = Account.default.default_enrollment_term
  end

  it "should propery determine if group weights are active" do
    @course.update_attribute(:group_weighting_scheme, nil)
    expect(@course.apply_group_weights?).to eq false
    @course.update_attribute(:group_weighting_scheme, 'equal')
    expect(@course.apply_group_weights?).to eq false
    @course.update_attribute(:group_weighting_scheme, 'percent')
    expect(@course.apply_group_weights?).to eq true
  end

  describe "soft-concluded?" do
    before :once do
      @term = Account.default.enrollment_terms.create!
    end

    before :each do
      @course.enrollment_term = @term
    end

    context "without term end date" do
      it "should know if it has been soft-concluded" do
        @course.update_attributes({:conclude_at => nil, :restrict_enrollments_to_course_dates => true })
        expect(@course).not_to be_soft_concluded

        @course.update_attribute(:conclude_at, 1.week.from_now)
        expect(@course).not_to be_soft_concluded

        @course.update_attribute(:conclude_at, 1.week.ago)
        expect(@course).to be_soft_concluded
      end
    end

    context "with term end date in the past" do
      before do
        @course.enrollment_term.update_attribute(:end_at, 1.week.ago)
      end

      it "should know if it has been soft-concluded" do
        @course.update_attributes({:conclude_at => nil, :restrict_enrollments_to_course_dates => true })
        expect(@course).to be_soft_concluded

        @course.update_attribute(:conclude_at, 1.week.from_now)
        expect(@course).not_to be_soft_concluded

        @course.update_attribute(:conclude_at, 1.week.ago)
        expect(@course).to be_soft_concluded
      end
    end

    context "with term end date in the future" do
      before do
        @course.enrollment_term.update_attribute(:end_at, 1.week.from_now)
      end

      it "should know if it has been soft-concluded" do
        @course.update_attributes({:conclude_at => nil, :restrict_enrollments_to_course_dates => true })
        expect(@course).not_to be_soft_concluded

        @course.update_attribute(:conclude_at, 1.week.from_now)
        expect(@course).not_to be_soft_concluded

        @course.update_attribute(:conclude_at, 1.week.ago)
        expect(@course).to be_soft_concluded
      end
    end

    context "with coures dates not overriding term dates" do
      before do
        @course.update_attribute(:conclude_at, 1.week.from_now)
      end

      it "should ignore course dates if not set to override term dates when calculating soft-concluded state" do
        @course.enrollment_term.update_attribute(:end_at, nil)
        expect(@course).not_to be_soft_concluded

        @course.enrollment_term.update_attribute(:end_at, 1.week.from_now)
        expect(@course).not_to be_soft_concluded

        @course.enrollment_term.update_attribute(:end_at, 1.week.ago)
        expect(@course).to be_soft_concluded
      end
    end
  end

  describe "allow_student_discussion_topics" do

    it "should default true" do
      expect(@course.allow_student_discussion_topics).to eq true
    end

    it "should set and get" do
      @course.allow_student_discussion_topics = false
      @course.save!
      expect(@course.allow_student_discussion_topics).to eq false
    end
  end

  describe "#time_zone" do
    it "should use provided value when set, regardless of root account setting" do
      @root_account = Account.default
      @root_account.default_time_zone = 'America/Chicago'
      @course.time_zone = 'America/New_York'
      expect(@course.time_zone).to eq ActiveSupport::TimeZone['Eastern Time (US & Canada)']
    end

    it "should default to root account value if not set" do
      @root_account = Account.default
      @root_account.default_time_zone = 'America/Chicago'
      expect(@course.time_zone).to eq ActiveSupport::TimeZone['Central Time (US & Canada)']
    end
  end

  context "validation" do
    it "should create a new instance given valid attributes" do
      course_model
    end
  end

  it "should create a unique course." do
    @course = Course.create_unique
    expect(@course.name).to eql("My Course")
    @uuid = @course.uuid
    @course2 = Course.create_unique(@uuid)
    expect(@course).to eql(@course2)
  end

  it "should only change the course code using the course name if the code is nil or empty" do
    @course = Course.create_unique
    code = @course.course_code
    @course.name = 'test123'
    @course.save
    expect(code).to eql(@course.course_code)
    @course.course_code = nil
    @course.save
    expect(code).to_not eql(@course.course_code)
  end

  it "should throw error for long sis id" do
    #should throw rails validation error instead of db invalid statement error
    @course = Course.create_unique
    @course.sis_source_id = 'qwertyuiopasdfghjklzxcvbnmqwertyuiopasdfghjklzxcvbnmqwertyuiopasdfghjklzxcvbnmqwertyuiopasdfghjklzxcvbnmqwertyuiopasdfghjklzxcvbnmqwertyuiopasdfghjklzxcvbnmqwertyuiopasdfghjklzxcvbnmqwertyuiopasdfghjklzxcvbnmqwertyuiopasdfghjklzxcvbnmqwertyuiopasdfghjklzxcvbnm'
    expect(lambda {@course.save!}).to raise_error("Validation failed: Sis source is too long (maximum is 255 characters)")
  end

  it "should always have a uuid, if it was created" do
    @course.save!
    expect(@course.uuid).not_to be_nil
  end

  context "permissions" do
    def clear_permissions_cache
      @course.clear_permissions_cache(@teacher)
      @course.clear_permissions_cache(@designer)
      @course.clear_permissions_cache(@ta)
      @course.clear_permissions_cache(@admin1)
      @course.clear_permissions_cache(@admin2)
    end

    it "should follow account chain when looking for generic permissions from AccountUsers" do
      account = Account.create!
      sub_account = Account.create!(:parent_account => account)
      sub_sub_account = Account.create!(:parent_account => sub_account)
      user = account_admin_user(:account => sub_account)
      course = Course.create!(:account => sub_sub_account)
      expect(course.grants_right?(user, :manage)).to be_truthy
    end

    # we have to reload the users after each course change here to catch the
    # enrollment changes that are applied directly to the db with update_all
    it "should grant delete to the proper individuals" do
      @role1 = custom_account_role('managecourses', :account => Account.default)
      @role2 = custom_account_role('managesis', :account => Account.default)
      account_admin_user_with_role_changes(:role => @role1, :role_changes => {:manage_courses => true})
      @admin1 = @admin
      account_admin_user_with_role_changes(:role => @role2, :role_changes => {:manage_sis => true})
      @admin2 = @admin
      course_with_teacher(:active_all => true)
      @designer = user(:active_all => true)
      @course.enroll_designer(@designer).accept!
      @ta = user(:active_all => true)
      @course.enroll_ta(@ta).accept!

      # active, non-sis course
      expect(@course.grants_right?(@teacher, :delete)).to be_truthy
      expect(@course.grants_right?(@designer, :delete)).to be_truthy
      expect(@course.grants_right?(@ta, :delete)).to be_falsey
      expect(@course.grants_right?(@admin1, :delete)).to be_truthy
      expect(@course.grants_right?(@admin2, :delete)).to be_falsey

      # active, sis course
      @course.sis_source_id = 'sis_id'
      @course.save!
      [@course, @teacher, @designer, @ta, @admin1, @admin2].each(&:reload)

      clear_permissions_cache
      expect(@course.grants_right?(@teacher, :delete)).to be_falsey
      expect(@course.grants_right?(@designer, :delete)).to be_falsey
      expect(@course.grants_right?(@ta, :delete)).to be_falsey
      expect(@course.grants_right?(@admin1, :delete)).to be_truthy
      expect(@course.grants_right?(@admin2, :delete)).to be_truthy

      # completed, non-sis course
      @course.sis_source_id = nil
      @course.complete!
      [@course, @teacher, @designer, @ta, @admin1, @admin2].each(&:reload)

      clear_permissions_cache
      expect(@course.grants_right?(@teacher, :delete)).to be_truthy
      expect(@course.grants_right?(@designer, :delete)).to be_truthy
      expect(@course.grants_right?(@ta, :delete)).to be_falsey
      expect(@course.grants_right?(@admin1, :delete)).to be_truthy
      expect(@course.grants_right?(@admin2, :delete)).to be_falsey
      @course.clear_permissions_cache(@user)

      # completed, sis course
      @course.sis_source_id = 'sis_id'
      @course.save!
      [@course, @teacher, @designer, @ta, @admin1, @admin2].each(&:reload)

      clear_permissions_cache
      expect(@course.grants_right?(@teacher, :delete)).to be_falsey
      expect(@course.grants_right?(@designer, :delete)).to be_falsey
      expect(@course.grants_right?(@ta, :delete)).to be_falsey
      expect(@course.grants_right?(@admin1, :delete)).to be_truthy
      expect(@course.grants_right?(@admin2, :delete)).to be_truthy
    end

    it "should grant reset_content to the proper individuals" do
      @role1 = custom_account_role('managecourses', :account => Account.default)
      @role2 = custom_account_role('managesis', :account => Account.default)
      account_admin_user_with_role_changes(:role => @role1, :role_changes => {:manage_courses => true})
      @admin1 = @admin
      account_admin_user_with_role_changes(:role => @role2, :role_changes => {:manage_sis => true})
      @admin2 = @admin
      course_with_teacher(:active_all => true)
      @designer = user(:active_all => true)
      @course.enroll_designer(@designer).accept!
      @ta = user(:active_all => true)
      @course.enroll_ta(@ta).accept!

      # active, non-sis course
      clear_permissions_cache
      expect(@course.grants_right?(@teacher, :reset_content)).to be_truthy
      expect(@course.grants_right?(@designer, :reset_content)).to be_truthy
      expect(@course.grants_right?(@ta, :reset_content)).to be_falsey
      expect(@course.grants_right?(@admin1, :reset_content)).to be_truthy
      expect(@course.grants_right?(@admin2, :reset_content)).to be_falsey

      # active, sis course
      @course.sis_source_id = 'sis_id'
      @course.save!
      [@course, @teacher, @designer, @ta, @admin1, @admin2].each(&:reload)

      clear_permissions_cache
      expect(@course.grants_right?(@teacher, :reset_content)).to be_truthy
      expect(@course.grants_right?(@designer, :reset_content)).to be_truthy
      expect(@course.grants_right?(@ta, :reset_content)).to be_falsey
      expect(@course.grants_right?(@admin1, :reset_content)).to be_truthy
      expect(@course.grants_right?(@admin2, :reset_content)).to be_falsey

      # completed, non-sis course
      @course.sis_source_id = nil
      @course.complete!
      [@course, @teacher, @designer, @ta, @admin1, @admin2].each(&:reload)

      clear_permissions_cache
      expect(@course.grants_right?(@teacher, :reset_content)).to be_falsey
      expect(@course.grants_right?(@designer, :reset_content)).to be_falsey
      expect(@course.grants_right?(@ta, :reset_content)).to be_falsey
      expect(@course.grants_right?(@admin1, :reset_content)).to be_truthy
      expect(@course.grants_right?(@admin2, :reset_content)).to be_falsey

      # completed, sis course
      @course.sis_source_id = 'sis_id'
      @course.save!
      [@course, @teacher, @designer, @ta, @admin1, @admin2].each(&:reload)

      clear_permissions_cache
      expect(@course.grants_right?(@teacher, :reset_content)).to be_falsey
      expect(@course.grants_right?(@designer, :reset_content)).to be_falsey
      expect(@course.grants_right?(@ta, :reset_content)).to be_falsey
      expect(@course.grants_right?(@admin1, :reset_content)).to be_truthy
      expect(@course.grants_right?(@admin2, :reset_content)).to be_falsey
    end

    def make_date_completed
      @enrollment.start_at = 4.days.ago
      @enrollment.end_at = 2.days.ago
      @enrollment.save!
      @enrollment.reload
      expect(@enrollment.state_based_on_date).to eq :completed
    end

    context "as a teacher" do
      let_once :c do
        course_with_teacher(:active_all => 1)
        @course
      end

      it "should grant read_as_admin and read_forum to date-completed teacher" do
        make_date_completed
        expect(c.prior_enrollments).to eq []
        expect(c.grants_right?(@teacher, :read_as_admin)).to be_truthy
        expect(c.grants_right?(@teacher, :read_forum)).to be_truthy
      end

      it "should grant read_as_admin and read to date-completed teacher of unpublished course" do
        course.update_attribute(:workflow_state, 'claimed')
        make_date_completed
        expect(c.prior_enrollments).to eq []
        expect(c.grants_right?(@teacher, :read_as_admin)).to be_truthy
        expect(c.grants_right?(@teacher, :read)).to be_truthy
      end

      it "should grant :read_outcomes to teachers in the course" do
        expect(c.grants_right?(@teacher, :read_outcomes)).to be_truthy
      end
    end

    context "as a designer" do
      let_once :c do
        course(:active_all => 1)
        @designer = user(:active_all => 1)
        @enrollment = @course.enroll_designer(@designer)
        @enrollment.accept!
        @course
      end

      it "should grant read_as_admin, read, manage, and update to date-active designer" do
        expect(c.grants_right?(@designer, :read_as_admin)).to be_truthy
        expect(c.grants_right?(@designer, :read)).to be_truthy
        expect(c.grants_right?(@designer, :manage)).to be_truthy
        expect(c.grants_right?(@designer, :update)).to be_truthy
      end

      it "should grant read_as_admin, read_roster, and read_prior_roster to date-completed designer" do
        @enrollment.start_at = 4.days.ago
        @enrollment.end_at = 2.days.ago
        @enrollment.save!
        expect(@enrollment.reload.state_based_on_date).to eq :completed
        expect(c.prior_enrollments).to eq []
        expect(c.grants_right?(@designer, :read_as_admin)).to be_truthy
        expect(c.grants_right?(@designer, :read_roster)).to be_truthy
        expect(c.grants_right?(@designer, :read_prior_roster)).to be_truthy
      end

      it "should grant read_as_admin and read to date-completed designer of unpublished course" do
        c.update_attribute(:workflow_state, 'claimed')
        make_date_completed
        expect(c.prior_enrollments).to eq []
        expect(c.grants_right?(@designer, :read_as_admin)).to be_truthy
        expect(c.grants_right?(@designer, :read)).to be_truthy
      end

      it "should not grant read_user_notes or view_all_grades to designer" do
        expect(c.grants_right?(@designer, :read_user_notes)).to be_falsey
        expect(c.grants_right?(@designer, :view_all_grades)).to be_falsey
      end
    end

    context "as a student" do
      let_once :c do
        course_with_student(:active_user => 1)
        @course
      end

      it "should grant read_grades read_forum to date-completed student" do
        c.offer!
        make_date_completed
        expect(c.prior_enrollments).to eq []
        expect(c.grants_right?(@student, :read_grades)).to be_truthy
        expect(c.grants_right?(@student, :read_forum)).to be_truthy
      end

      it "should not grant read to completed students of an unpublished course" do
        expect(c).to be_created
        @enrollment.update_attribute(:workflow_state, 'completed')
        expect(@enrollment).to be_completed
        expect(c.grants_right?(:read, @student)).to be_falsey
      end

      it "should not grant read to soft-completed students of an unpublished course" do
        c.restrict_enrollments_to_course_dates = true
        c.start_at = 4.days.ago
        c.conclude_at = 2.days.ago
        c.save!
        expect(c).to be_created
        @enrollment.update_attribute(:workflow_state, 'active')
        expect(@enrollment.state_based_on_date).to eq :completed
        expect(c.grants_right?(:read, @student)).to be_falsey
      end

      it "should grant :read_outcomes to students in the course" do
        c.offer!
        expect(c.grants_right?(@student, :read_outcomes)).to be_truthy
      end
    end

    context "as an admin" do
      it "should grant :read_outcomes to account admins" do
        course(:active_all => 1)
        account_admin_user(:account => @course.account)
        expect(@course.grants_right?(@admin, :read_outcomes)).to be_truthy
      end
    end
  end

  describe "#reset_content" do
    before do :once
      course_with_student
    end

    it "should clear content" do
      @course.root_account.allow_self_enrollment!

      @course.discussion_topics.create!
      @course.quizzes.create!
      @course.assignments.create!
      @course.wiki.set_front_page_url!('front-page')
      @course.wiki.front_page.save!
      @course.self_enrollment = true
      @course.sis_source_id = 'sis_id'
      @course.lti_context_id = 'lti_context_id'
      @course.stuck_sis_fields = [].to_set
      profile = @course.profile
      profile.description = "description"
      profile.save!
      @course.save!
      @course.reload

      expect(@course.course_sections).not_to be_empty
      expect(@course.students).to eq [@student]
      expect(@course.stuck_sis_fields).to eq [].to_set
      self_enrollment_code = @course.self_enrollment_code
      expect(self_enrollment_code).not_to be_nil

      @new_course = @course.reset_content

      @course.reload
      expect(@course.stuck_sis_fields).to eq [:workflow_state].to_set
      expect(@course.course_sections).to be_empty
      expect(@course.students).to be_empty
      expect(@course.sis_source_id).to be_nil
      expect(@course.self_enrollment_code).to be_nil
      expect(@course.lti_context_id).not_to be_nil

      @new_course.reload
      expect(@new_course.course_sections).not_to be_empty
      expect(@new_course.students).to eq [@student]
      expect(@new_course.discussion_topics).to be_empty
      expect(@new_course.quizzes).to be_empty
      expect(@new_course.assignments).to be_empty
      expect(@new_course.sis_source_id).to eq 'sis_id'
      expect(@new_course.syllabus_body).to be_blank
      expect(@new_course.stuck_sis_fields).to eq [].to_set
      expect(@new_course.self_enrollment_code).to eq self_enrollment_code
      expect(@new_course.lti_context_id).to be_nil

      expect(@course.uuid).not_to eq @new_course.uuid
      expect(@course.wiki_id).not_to eq @new_course.wiki_id
      expect(@course.replacement_course_id).to eq @new_course.id
    end

    it "should not have self enrollment enabled if account setting disables it" do
      @course.self_enrollment = true
      @course.save!
      expect(@course.self_enrollment_enabled?).to eq false

      account = @course.root_account
      account.allow_self_enrollment!
      @course.self_enrollment = true
      @course.save!
      expect(@course.reload.self_enrollment_enabled?).to eq true

      account.settings.delete(:self_enrollment)
      account.save!
      expect(@course.reload.self_enrollment_enabled?).to eq false
    end

    it "should retain original course profile" do
      data = {:something => 'special here'}
      description = 'simple story'
      expect(@course.profile).not_to be_nil
      @course.profile.tap do |p|
        p.description = description
        p.data = data
        p.save!
      end
      @course.reload

      @new_course = @course.reset_content

      expect(@new_course.profile.data).to eq data
      expect(@new_course.profile.description).to eq description
    end

    it "should preserve sticky fields" do
      @course.sis_source_id = 'sis_id'
      @course.course_code = "cid"
      @course.save!
      @course.stuck_sis_fields = [].to_set
      @course.name = "course_name"
      expect(@course.stuck_sis_fields).to eq [:name].to_set
      profile = @course.profile
      profile.description = "description"
      profile.save!
      @course.save!
      expect(@course.stuck_sis_fields).to eq [:name].to_set

      @course.reload

      @new_course = @course.reset_content

      @course.reload
      expect(@course.stuck_sis_fields).to eq [:workflow_state, :name].to_set
      expect(@course.sis_source_id).to be_nil

      @new_course.reload
      expect(@new_course.sis_source_id).to eq 'sis_id'
      expect(@new_course.stuck_sis_fields).to eq [:name].to_set

      expect(@course.uuid).not_to eq @new_course.uuid
      expect(@course.replacement_course_id).to eq @new_course.id
    end

  end

  context "group_categories" do
    let_once(:course) { course_model }

    it "group_categories should not include deleted categories" do
      expect(course.group_categories.count).to eq 0
      category1 = course.group_categories.create(:name => 'category 1')
      category2 = course.group_categories.create(:name => 'category 2')
      expect(course.group_categories.count).to eq 2
      category1.destroy
      course.reload
      expect(course.group_categories.count).to eq 1
      expect(course.group_categories.to_a).to eq [category2]
    end

    it "all_group_categories should include deleted categories" do
      expect(course.all_group_categories.count).to eq 0
      category1 = course.group_categories.create(:name => 'category 1')
      category2 = course.group_categories.create(:name => 'category 2')
      expect(course.all_group_categories.count).to eq 2
      category1.destroy
      course.reload
      expect(course.all_group_categories.count).to eq 2
    end
  end
end

describe Course do
  context "users_not_in_groups" do
    before :once do
      @course = course(:active_all => true)
      @user1 = user_model
      @user2 = user_model
      @user3 = user_model
      @enrollment1 = @course.enroll_user(@user1)
      @enrollment2 = @course.enroll_user(@user2)
      @enrollment3 = @course.enroll_user(@user3)
    end

    it "should not include users through deleted/rejected/completed enrollments" do
      @enrollment1.destroy
      expect(@course.users_not_in_groups([]).size).to eq 2
    end

    it "should not include users in one of the groups" do
      group = @course.groups.create
      group.add_user(@user1)
      users = @course.users_not_in_groups([group])
      expect(users.size).to eq 2
      expect(users).not_to be_include(@user1)
    end

    it "should include users otherwise" do
      group = @course.groups.create
      group.add_user(@user1)
      users = @course.users_not_in_groups([group])
      expect(users).to be_include(@user2)
      expect(users).to be_include(@user3)
    end

    it "should allow ordering by user's sortable name" do
      @user1.sortable_name = 'jonny'; @user1.save
      @user2.sortable_name = 'bob'; @user2.save
      @user3.sortable_name = 'richard'; @user3.save
      users = @course.users_not_in_groups([], order: User.sortable_name_order_by_clause('users'))
      expect(users.map{ |u| u.id }).to eq [@user2.id, @user1.id, @user3.id]
    end
  end

  context "events_for" do
    before :once do
      course_with_teacher(:active_all => true)
      @event1 = @course.calendar_events.create
      @event2 = @course.calendar_events.build :child_event_data => [{:start_at => "2012-01-01", :end_at => "2012-01-02", :context_code => @course.default_section.asset_string}]
      @event2.updating_user = @teacher
      @event2.save!
      @event3 = @event2.child_events.first
      @appointment_group = AppointmentGroup.create! :title => "ag", :contexts => [@course]
      @appointment_group.publish!
      @assignment = @course.assignments.create!
    end

    it "should return appropriate events" do
      events = @course.events_for(@teacher)
      expect(events).to include @event1
      expect(events).not_to include @event2
      expect(events).to include @event3
      expect(events).to include @appointment_group
      expect(events).to include @assignment
    end

    it "should return appropriate events when no user is supplied" do
      events = @course.events_for(nil)
      expect(events).to include @event1
      expect(events).not_to include @event2
      expect(events).not_to include @event3
      expect(events).not_to include @appointment_group
      expect(events).to include @assignment
    end
  end

  context "migrate_content_links" do
    it "should ignore types not in the supported_types arg" do
      c1 = course_model
      c2 = course_model
      orig = <<-HTML
      We aren't translating <a href="/courses/#{c1.id}/assignments/5">links to assignments</a>
      HTML
      html = Course.migrate_content_links(orig, c1, c2, ['files'])
      expect(html).to eq orig
    end
  end

  it "should be marshal-able" do
    c = Course.new(:name => 'c1')
    Marshal.dump(c)
    c.save!
    Marshal.dump(c)
  end
end


describe Course, "participants" do
  before :once do
    @course = Course.create(:name => "some_name")
    se = @course.enroll_student(user_with_pseudonym,:enrollment_state => 'active')
    tae = @course.enroll_ta(user_with_pseudonym,:enrollment_state => 'active')
    te = @course.enroll_teacher(user_with_pseudonym,:enrollment_state => 'active')
    @student, @ta, @teach = [se, tae, te].map(&:user)
  end

  context "vanilla usage" do
    it "should return participating_admins and participating_students" do
      [@student, @ta, @teach].each { |usr| expect(@course.participants).to be_include(usr) }
    end
  end

  context "including obervers" do
    before :once  do
      oe = @course.enroll_user(user_with_pseudonym, 'ObserverEnrollment',:enrollment_state => 'active')
      @course_level_observer = oe.user

      oe = @course.enroll_user(user_with_pseudonym, 'ObserverEnrollment',:enrollment_state => 'active')
      oe.associated_user_id = @student.id
      oe.save!
      @student_following_observer = oe.user
    end

    it "should return participating_admins, participating_students, and observers" do
      participants = @course.participants(true)
      [@student, @ta, @teach, @course_level_observer, @student_following_observer].each do |usr|
        expect(participants).to be_include(usr)
      end
    end

    context "excluding specific students" do
      it "should reject observers only following one of the excluded students" do
        partic = @course.participants(true, excluded_user_ids: [@student.id, @student_following_observer.id])
        [@student, @student_following_observer].each { |usr| expect(partic).to_not be_include(usr) }
      end
      it "should include admins and course level observers" do
        partic = @course.participants(true, excluded_user_ids: [@student.id, @student_following_observer.id])
        [@ta, @teach, @course_level_observer].each { |usr| expect(partic).to be_include(usr) }
      end
    end
  end

  it "should exclude some student when passed their id" do
    partic = @course.participants(false, excluded_user_ids: [@student.id])
    [@ta, @teach].each { |usr| expect(partic).to be_include(usr) }
    expect(partic).to_not be_include(@student)
  end
end

describe Course, "enroll" do

  before :once do
    @course = Course.create(:name => "some_name")
    @user = user_with_pseudonym
  end

  context "students" do
    before :once do
      @se = @course.enroll_student(@user)
    end

    it "should be able to enroll a student" do
      expect(@se.user_id).to eql(@user.id)
      expect(@se.course_id).to eql(@course.id)
    end

    it "should enroll a student as creation_pending if the course isn't published" do
      expect(@se).to be_creation_pending
    end
  end

  context "tas" do
    before :once do
      Notification.create(:name => "Enrollment Registration", :category => "registration")
      @tae = @course.enroll_ta(@user)
    end

    it "should be able to enroll a TA" do
      expect(@tae.user_id).to eql(@user.id)
      expect(@tae.course_id).to eql(@course.id)
    end

    it "should enroll a ta as invited if the course isn't published" do
      expect(@tae).to be_invited
      expect(@tae.messages_sent).to be_include("Enrollment Registration")
    end
  end

  context "teachers" do
    before :once do
      Notification.create(:name => "Enrollment Registration", :category => "registration")
      @te = @course.enroll_teacher(@user)
    end

    it "should be able to enroll a teacher" do
      expect(@te.user_id).to eql(@user.id)
      expect(@te.course_id).to eql(@course.id)
    end

    it "should enroll a teacher as invited if the course isn't published" do
      expect(@te).to be_invited
      expect(@te.messages_sent).to be_include("Enrollment Registration")
    end
  end

  it "should be able to enroll a designer" do
    @course.enroll_designer(@user)
    @de = @course.designer_enrollments.first
    expect(@de.user_id).to eql(@user.id)
    expect(@de.course_id).to eql(@course.id)
  end


  it "should scope correctly when including teachers from course" do
    account = @course.account
    @course.enroll_student(@user)
    scope = account.associated_courses.active.select([:id, :name]).joins(:teachers).includes(:teachers).where(:enrollments => { :workflow_state => 'active' })
    sql = scope.to_sql
    expect(sql).to match(/enrollments.type = 'TeacherEnrollment'/)
  end
end

describe Course, "score_to_grade" do
  it "should correctly map scores to grades" do
    default = GradingStandard.default_grading_standard
    expect(default.to_json).to eq([["A", 0.94], ["A-", 0.90], ["B+", 0.87], ["B", 0.84], ["B-", 0.80], ["C+", 0.77], ["C", 0.74], ["C-", 0.70], ["D+", 0.67], ["D", 0.64], ["D-", 0.61], ["F", 0.0]].to_json)
    course_model
    expect(@course.score_to_grade(95)).to eql(nil)
    @course.grading_standard_id = 0
    expect(@course.score_to_grade(1005)).to eql("A")
    expect(@course.score_to_grade(105)).to eql("A")
    expect(@course.score_to_grade(100)).to eql("A")
    expect(@course.score_to_grade(99)).to eql("A")
    expect(@course.score_to_grade(94)).to eql("A")
    expect(@course.score_to_grade(93.999)).to eql("A-")
    expect(@course.score_to_grade(93.001)).to eql("A-")
    expect(@course.score_to_grade(93)).to eql("A-")
    expect(@course.score_to_grade(92.999)).to eql("A-")
    expect(@course.score_to_grade(90)).to eql("A-")
    expect(@course.score_to_grade(89)).to eql("B+")
    expect(@course.score_to_grade(87)).to eql("B+")
    expect(@course.score_to_grade(86)).to eql("B")
    expect(@course.score_to_grade(85)).to eql("B")
    expect(@course.score_to_grade(83)).to eql("B-")
    expect(@course.score_to_grade(80)).to eql("B-")
    expect(@course.score_to_grade(79)).to eql("C+")
    expect(@course.score_to_grade(76)).to eql("C")
    expect(@course.score_to_grade(73)).to eql("C-")
    expect(@course.score_to_grade(71)).to eql("C-")
    expect(@course.score_to_grade(69)).to eql("D+")
    expect(@course.score_to_grade(67)).to eql("D+")
    expect(@course.score_to_grade(66)).to eql("D")
    expect(@course.score_to_grade(65)).to eql("D")
    expect(@course.score_to_grade(62)).to eql("D-")
    expect(@course.score_to_grade(60)).to eql("F")
    expect(@course.score_to_grade(59)).to eql("F")
    expect(@course.score_to_grade(0)).to eql("F")
    expect(@course.score_to_grade(-100)).to eql("F")
  end
end

describe Course, "gradebook_to_csv" do
  it "should generate gradebook csv" do
    course_with_student(:active_all => true)
    @group = @course.assignment_groups.create!(:name => "Some Assignment Group", :group_weight => 100)
    @assignment = @course.assignments.create!(:title => "Some Assignment", :points_possible => 10, :assignment_group => @group)
    @assignment.grade_student(@user, :grade => "10")
    @assignment2 = @course.assignments.create!(:title => "Some Assignment 2", :points_possible => 10, :assignment_group => @group)
    @course.recompute_student_scores
    @user.reload
    @course.reload

    csv = @course.gradebook_to_csv
    expect(csv).not_to be_nil
    rows = CSV.parse(csv)
    expect(rows.length).to equal(3)
    expect(rows[0][-1]).to eq "Final Score"
    expect(rows[1][-1]).to eq "(read only)"
    expect(rows[2][-1]).to eq "50"
    expect(rows[0][-2]).to eq "Current Score"
    expect(rows[1][-2]).to eq "(read only)"
    expect(rows[2][-2]).to eq "100"
  end

  it "should order assignments and groups by position" do
    course_with_student(:active_all => true)

    @assignment_group_1, @assignment_group_2 = [@course.assignment_groups.create!(:name => "Some Assignment Group 1", :group_weight => 100), @course.assignment_groups.create!(:name => "Some Assignment Group 2", :group_weight => 100)].sort_by{|a| a.id}

    now = Time.now

    g1a1 = @course.assignments.create!(:title => "Assignment 01", :due_at => now + 1.days, :position => 3, :assignment_group => @assignment_group_1, :points_possible => 10)
    @course.assignments.create!(:title => "Assignment 02", :due_at => now + 1.days, :position => 1, :assignment_group => @assignment_group_1, :points_possible => 10)
    @course.assignments.create!(:title => "Assignment 03", :due_at => now + 1.days, :position => 2, :assignment_group => @assignment_group_1)
    @course.assignments.create!(:title => "Assignment 05", :due_at => now + 4.days, :position => 4, :assignment_group => @assignment_group_1)
    @course.assignments.create!(:title => "Assignment 04", :due_at => now + 5.days, :position => 5, :assignment_group => @assignment_group_1)
    @course.assignments.create!(:title => "Assignment 06", :due_at => now + 7.days, :position => 6, :assignment_group => @assignment_group_1)
    @course.assignments.create!(:title => "Assignment 07", :due_at => now + 6.days, :position => 7, :assignment_group => @assignment_group_1)
    g2a1 = @course.assignments.create!(:title => "Assignment 08", :due_at => now + 8.days, :position => 1, :assignment_group => @assignment_group_2, :points_possible => 10)
    @course.assignments.create!(:title => "Assignment 09", :due_at => now + 8.days, :position => 9, :assignment_group => @assignment_group_1)
    @course.assignments.create!(:title => "Assignment 10", :due_at => now + 8.days, :position => 10, :assignment_group => @assignment_group_2, :points_possible => 10)
    @course.assignments.create!(:title => "Assignment 12", :due_at => now + 11.days, :position => 11, :assignment_group => @assignment_group_1)
    @course.assignments.create!(:title => "Assignment 14", :due_at => nil, :position => 14, :assignment_group => @assignment_group_1)
    @course.assignments.create!(:title => "Assignment 11", :due_at => now + 11.days, :position => 11, :assignment_group => @assignment_group_1)
    @course.assignments.create!(:title => "Assignment 13", :due_at => now + 11.days, :position => 11, :assignment_group => @assignment_group_1)
    @course.assignments.create!(:title => "Assignment 99", :position => 1, :assignment_group => @assignment_group_1, :submission_types => 'not_graded')
    @course.recompute_student_scores
    @user.reload
    @course.reload

    g1a1.grade_student(@user, grade: 10)
    g2a1.grade_student(@user, grade: 5)

    csv = @course.gradebook_to_csv
    expect(csv).not_to be_nil
    rows = CSV.parse(csv)
    expect(rows.length).to equal(3)
    assignments, groups = [], []
    rows[0].each do |column|
      assignments << column.sub(/ \([0-9]+\)/, '') if column =~ /Assignment \d+/
      groups << column if column =~ /Some Assignment Group/
    end
    expect(assignments).to eq ["Assignment 02", "Assignment 03", "Assignment 01", "Assignment 05",  "Assignment 04", "Assignment 06", "Assignment 07", "Assignment 09", "Assignment 11", "Assignment 12", "Assignment 13", "Assignment 14", "Assignment 08", "Assignment 10"]
    expect(groups).to eq ["Some Assignment Group 1 Current Points",
                      "Some Assignment Group 1 Final Points",
                      "Some Assignment Group 1 Current Score",
                      "Some Assignment Group 1 Final Score",
                      "Some Assignment Group 2 Current Points",
                      "Some Assignment Group 2 Final Points",
                      "Some Assignment Group 2 Current Score",
                      "Some Assignment Group 2 Final Score"]

    expect(rows[2][-10]).to eq "100"    # ag1 current score
    expect(rows[2][-9]).to  eq "50"     # ag1 final score
    expect(rows[2][-6]).to  eq "50"     # ag2 current score
    expect(rows[2][-5]).to  eq "25"     # ag2 final score
  end

  it "should alphabetize by sortable name with the test student at the end" do
    course
    ["Ned Ned", "Zed Zed", "Aardvark Aardvark"].each{|name| student_in_course(:name => name)}
    test_student_enrollment = student_in_course(:name => "Test Student")
    test_student_enrollment.type = "StudentViewEnrollment"
    test_student_enrollment.save!

    csv = @course.gradebook_to_csv
    rows = CSV.parse(csv)
    expect([rows[2][0],
     rows[3][0],
     rows[4][0],
     rows[5][0]]).to eq ["Aardvark, Aardvark", "Ned, Ned", "Zed, Zed", "Student, Test"]
  end

  it "should include all section names in alphabetical order" do
    course
    sections = []
    students = []
    ['COMPSCI 123 LEC 001', 'COMPSCI 123 DIS 101', 'COMPSCI 123 DIS 102'].each do |section_name|
      add_section(section_name)
      sections << @course_section
    end
    3.times {|i| students << student_in_section(sections[0], :user => user(:name => "Student #{i}")) }

    @course.enroll_user(students[0], 'StudentEnrollment', :section => sections[1], :enrollment_state => 'active', :allow_multiple_enrollments => true)
    @course.enroll_user(students[2], 'StudentEnrollment', :section => sections[1], :enrollment_state => 'active', :allow_multiple_enrollments => true)
    @course.enroll_user(students[2], 'StudentEnrollment', :section => sections[2], :enrollment_state => 'active', :allow_multiple_enrollments => true)

    csv = @course.gradebook_to_csv
    expect(csv).not_to be_nil
    rows = CSV.parse(csv)
    expect(rows.length).to equal(5)
    expect(rows[2][2]).to eq "COMPSCI 123 DIS 101 and COMPSCI 123 LEC 001"
    expect(rows[3][2]).to eq "COMPSCI 123 LEC 001"
    expect(rows[4][2]).to eq "COMPSCI 123 DIS 101, COMPSCI 123 DIS 102, and COMPSCI 123 LEC 001"
  end

  it "should generate csv with final grade if enabled" do
    course_with_student(:active_all => true)
    @course.grading_standard_id = 0
    @course.save!
    @group = @course.assignment_groups.create!(:name => "Some Assignment Group", :group_weight => 100)
    @assignment = @course.assignments.create!(:title => "Some Assignment", :points_possible => 10, :assignment_group => @group)
    @assignment.grade_student(@user, :grade => "10")
    @assignment2 = @course.assignments.create!(:title => "Some Assignment 2", :points_possible => 10, :assignment_group => @group)
    @assignment2.grade_student(@user, :grade => "8")
    @course.recompute_student_scores
    @user.reload
    @course.reload

    csv = @course.gradebook_to_csv
    expect(csv).not_to be_nil
    rows = CSV.parse(csv)
    expect(rows.length).to equal(3)
    expect(rows[0][-1]).to eq "Final Grade"
    expect(rows[1][-1]).to eq "(read only)"
    expect(rows[2][-1]).to eq "A-"
    expect(rows[0][-2]).to eq "Current Grade"
    expect(rows[1][-2]).to eq "(read only)"
    expect(rows[2][-2]).to eq "A-"
    expect(rows[0][-3]).to eq "Final Score"
    expect(rows[1][-3]).to eq "(read only)"
    expect(rows[2][-3]).to eq "90"
    expect(rows[0][-4]).to eq "Current Score"
    expect(rows[1][-4]).to eq "(read only)"
    expect(rows[2][-4]).to eq "90"
  end

  it "should include sis ids if enabled" do
    course(:active_all => true)
    @user1 = user_with_pseudonym(:active_all => true, :name => 'Brian', :username => 'brianp@instructure.com')
    student_in_course(:user => @user1)
    @user2 = user_with_pseudonym(:active_all => true, :name => 'Cody', :username => 'cody@instructure.com')
    student_in_course(:user => @user2)
    @user3 = user(:active_all => true, :name => 'JT')
    student_in_course(:user => @user3)
    @user1.pseudonym.sis_user_id = "SISUSERID"
    @user1.pseudonym.save!
    @group = @course.assignment_groups.create!(:name => "Some Assignment Group", :group_weight => 100)
    @assignment = @course.assignments.create!(:title => "Some Assignment", :points_possible => 10, :assignment_group => @group)
    @assignment.grade_student(@user1, :grade => "10")
    @assignment.grade_student(@user2, :grade => "9")
    @assignment.grade_student(@user3, :grade => "9")
    @assignment2 = @course.assignments.create!(:title => "Some Assignment 2", :points_possible => 10, :assignment_group => @group)
    @course.recompute_student_scores
    @course.reload

    csv = @course.gradebook_to_csv(:include_sis_id => true)
    expect(csv).not_to be_nil
    rows = CSV.parse(csv)
    expect(rows.length).to eq 5
    expect(rows[0][1]).to eq 'ID'
    expect(rows[0][2]).to eq 'SIS User ID'
    expect(rows[0][3]).to eq 'SIS Login ID'
    expect(rows[0][4]).to eq 'Section'
    expect(rows[1][2]).to eq nil
    expect(rows[1][3]).to eq nil
    expect(rows[1][4]).to eq nil
    expect(rows[1][-1]).to eq '(read only)'
    expect(rows[2][1]).to eq @user1.id.to_s
    expect(rows[2][2]).to eq 'SISUSERID'
    expect(rows[2][3]).to eq @user1.pseudonym.unique_id
    expect(rows[3][1]).to eq @user2.id.to_s
    expect(rows[3][2]).to be_nil
    expect(rows[3][3]).to eq @user2.pseudonym.unique_id
    expect(rows[4][1]).to eq @user3.id.to_s
    expect(rows[4][2]).to be_nil
    expect(rows[4][3]).to be_nil
  end

  it "should include primary domain if a trust exists" do
    course(:active_all => true)
    @user1 = user_with_pseudonym(:active_all => true, :name => 'Brian', :username => 'brianp@instructure.com')
    student_in_course(:user => @user1)
    account2 = account_model
    @user2 = user_with_pseudonym(:active_all => true, :name => 'Cody', :username => 'cody@instructure.com', :account => account2)
    student_in_course(:user => @user2)
    @user3 = user(:active_all => true, :name => 'JT')
    student_in_course(:user => @user3)
    @user1.pseudonym.sis_user_id = "SISUSERID"
    @user1.pseudonym.save!
    @user2.pseudonym.sis_user_id = "SISUSERID"
    @user2.pseudonym.save!
    @course.reload
    @course.root_account.stubs(:trust_exists?).returns(true)
    @course.root_account.any_instantiation.stubs(:trusted_account_ids).returns([account2.id])
    HostUrl.expects(:context_host).with(@course.root_account).returns('school1')
    HostUrl.expects(:context_host).with(account2).returns('school2')

    csv = @course.gradebook_to_csv(:include_sis_id => true)
    expect(csv).not_to be_nil
    rows = CSV.parse(csv)
    expect(rows.length).to eq 5
    expect(rows[0][1]).to eq 'ID'
    expect(rows[0][2]).to eq 'SIS User ID'
    expect(rows[0][3]).to eq 'SIS Login ID'
    expect(rows[0][4]).to eq 'Root Account'
    expect(rows[0][5]).to eq 'Section'
    expect(rows[1][2]).to eq nil
    expect(rows[1][3]).to eq nil
    expect(rows[1][4]).to eq nil
    expect(rows[1][5]).to eq nil
    expect(rows[2][1]).to eq @user1.id.to_s
    expect(rows[2][2]).to eq 'SISUSERID'
    expect(rows[2][3]).to eq @user1.pseudonym.unique_id
    expect(rows[2][4]).to eq 'school1'
    expect(rows[3][1]).to eq @user2.id.to_s
    expect(rows[3][2]).to eq 'SISUSERID'
    expect(rows[3][3]).to eq @user2.pseudonym.unique_id
    expect(rows[3][4]).to eq 'school2'
    expect(rows[4][1]).to eq @user3.id.to_s
    expect(rows[4][2]).to be_nil
    expect(rows[4][3]).to be_nil
    expect(rows[4][4]).to be_nil
  end

  it "can include concluded enrollments" do
    e = course_with_student active_all: true
    e.update_attribute :workflow_state, 'completed'

    expect(@course.gradebook_to_csv).not_to include @student.name
    expect(@course.gradebook_to_csv(include_priors: true)).to include @student.name
  end

  context "accumulated points" do
    before :once do
      student_in_course(:active_all => true)
      a = @course.assignments.create! :title => "Blah", :points_possible => 10
      a.grade_student @student, :grade => 8
    end

    it "includes points for unweighted courses" do
      csv = CSV.parse(@course.gradebook_to_csv)
      expect(csv[0][-8]).to eq "Assignments Current Points"
      expect(csv[0][-7]).to eq "Assignments Final Points"
      expect(csv[1][-8]).to eq "(read only)"
      expect(csv[1][-7]).to eq "(read only)"
      expect(csv[2][-8]).to eq "8"
      expect(csv[2][-7]).to eq "8"
      expect(csv[0][-4]).to eq "Current Points"
      expect(csv[0][-3]).to eq "Final Points"
      expect(csv[1][-4]).to eq "(read only)"
      expect(csv[1][-3]).to eq "(read only)"
      expect(csv[2][-4]).to eq "8"
      expect(csv[2][-3]).to eq "8"
    end

    it "doesn't include points for weighted courses" do
      @course.update_attribute(:group_weighting_scheme, 'percent')
      csv = CSV.parse(@course.gradebook_to_csv)
      expect(csv[0][-8]).not_to eq "Assignments Current Points"
      expect(csv[0][-7]).not_to eq "Assignments Final Points"
      expect(csv[0][-4]).not_to eq "Current Points"
      expect(csv[0][-3]).not_to eq "Final Points"
    end
  end

  it "should only include students once" do
    # students might have multiple enrollments in a course
    course(:active_all => true)
    @user1 = user_with_pseudonym(:active_all => true, :name => 'Brian', :username => 'brianp@instructure.com')
    student_in_course(:user => @user1)
    @user2 = user_with_pseudonym(:active_all => true, :name => 'Cody', :username => 'cody@instructure.com')
    student_in_course(:user => @user2)
    @s2 = @course.course_sections.create!(:name => 'section2')
    StudentEnrollment.create!(:user => @user1, :course => @course, :course_section => @s2)
    @course.reload
    csv = @course.gradebook_to_csv(:include_sis_id => true)
    rows = CSV.parse(csv)
    expect(rows.length).to eq 4
  end

  it "should include muted if any assignments are muted" do
      course(:active_all => true)
      @user1 = user_with_pseudonym(:active_all => true, :name => 'Brian', :username => 'brianp@instructure.com')
      student_in_course(:user => @user1)
      @user2 = user_with_pseudonym(:active_all => true, :name => 'Cody', :username => 'cody@instructure.com')
      student_in_course(:user => @user2)
      @user3 = user(:active_all => true, :name => 'JT')
      student_in_course(:user => @user3)
      @user1.pseudonym.sis_user_id = "SISUSERID"
      @user1.pseudonym.save!
      @group = @course.assignment_groups.create!(:name => "Some Assignment Group", :group_weight => 100)
      @assignment = @course.assignments.create!(:title => "Some Assignment", :points_possible => 10, :assignment_group => @group)
      @assignment.muted = true
      @assignment.save!
      @assignment.grade_student(@user1, :grade => "10")
      @assignment.grade_student(@user2, :grade => "9")
      @assignment.grade_student(@user3, :grade => "9")
      @assignment2 = @course.assignments.create!(:title => "Some Assignment 2", :points_possible => 10, :assignment_group => @group)
      @course.recompute_student_scores
      @course.reload

      csv = @course.gradebook_to_csv(:include_sis_id => true)
      expect(csv).not_to be_nil
      rows = CSV.parse(csv)
      expect(rows.length).to eq 6
      expect(rows[0][1]).to eq 'ID'
      expect(rows[0][2]).to eq 'SIS User ID'
      expect(rows[0][3]).to eq 'SIS Login ID'
      expect(rows[0][4]).to eq 'Section'
      expect(rows[1][0]).to eq nil
      expect(rows[1][5]).to eq 'Muted'
      expect(rows[1][6]).to eq nil
      expect(rows[2][2]).to eq nil
      expect(rows[2][3]).to eq nil
      expect(rows[2][4]).to eq nil
      expect(rows[2][-1]).to eq '(read only)'
      expect(rows[3][1]).to eq @user1.id.to_s
      expect(rows[3][2]).to eq 'SISUSERID'
      expect(rows[3][3]).to eq @user1.pseudonym.unique_id
      expect(rows[4][1]).to eq @user2.id.to_s
      expect(rows[4][2]).to be_nil
      expect(rows[4][3]).to eq @user2.pseudonym.unique_id
      expect(rows[5][1]).to eq @user3.id.to_s
      expect(rows[5][2]).to be_nil
      expect(rows[5][3]).to be_nil
  end

  it "should only include students from the appropriate section for a section limited teacher" do
    course(:active_all => 1)
    @teacher.enrollments.first.update_attribute(:limit_privileges_to_course_section, true)
    @section = @course.course_sections.create!(:name => 'section 2')
    @user1 = user_with_pseudonym(:active_all => true, :name => 'Brian', :username => 'brianp@instructure.com')
    @section.enroll_user(@user1, 'StudentEnrollment', 'active')
    @user2 = user_with_pseudonym(:active_all => true, :name => 'Jeremy', :username => 'jeremy@instructure.com')
    @course.enroll_student(@user2)

    csv = @course.gradebook_to_csv(:user => @teacher)
    expect(csv).not_to be_nil
    rows = CSV.parse(csv)
    # two header rows, and one student row
    expect(rows.length).to eq 3
    expect(rows[2][1]).to eq @user2.id.to_s
  end

  context "differentiated assignments" do
    def setup_DA
      @course_section = @course.course_sections.create
      user_attrs = [{name: 'student1'}, {name: 'student2'}, {name: 'student3'}]
      @student1, @student2, @student3 = create_users(user_attrs, return_type: :record)
      @assignment = @course.assignments.create!(title: "a1", only_visible_to_overrides: true)
      @course.enroll_student(@student3, :enrollment_state => 'active')
      @section = @course.course_sections.create!(name: "section1")
      @section2 = @course.course_sections.create!(name: "section2")
      student_in_section(@section, user: @student1)
      student_in_section(@section2, user: @student2)
      create_section_override_for_assignment(@assignment, {course_section: @section})
      @assignment2 = @course.assignments.create!(title: "a2", only_visible_to_overrides: true)
      create_section_override_for_assignment(@assignment2, {course_section: @section2})
      @course.reload
    end

    before :once do
      course_with_teacher(:active_all => true)
      @course.enable_feature!(:differentiated_assignments)
      setup_DA
      @assignment.grade_student(@student1, :grade => "3")
      @assignment2.grade_student(@student2, :grade => "3")
    end

    it "should insert N/A for non-visible assignments" do
      csv = @course.gradebook_to_csv(:user => @teacher)
      expect(csv).not_to be_nil
      rows = CSV.parse(csv)
      expect(rows[2][3]).to eq "3"
      expect(rows[2][4]).to eq "N/A"

      expect(rows[3][3]).to eq "N/A"
      expect(rows[3][4]).to eq "3"

      expect(rows[4][3]).to eq "N/A"
      expect(rows[4][4]).to eq "N/A"
    end
  end
end

describe Course, "update_account_associations" do
  it "should update account associations correctly" do
    account1 = Account.create!(:name => 'first')
    account2 = Account.create!(:name => 'second')

    @c = Course.create!(:account => account1)
    expect(@c.associated_accounts.length).to eql(1)
    expect(@c.associated_accounts.first).to eql(account1)

    @c.account = account2
    @c.save!
    @c.reload
    expect(@c.associated_accounts.length).to eql(1)
    expect(@c.associated_accounts.first).to eql(account2)
  end

  it "should act like it's associated to its account and root account, even if associations are busted" do
    account1 = Account.default.sub_accounts.create!
    c = account1.courses.create!
    c.course_account_associations.scoped.delete_all
    expect(c.associated_accounts).to eq [account1, Account.default]
  end
end

describe Course, "tabs_available" do
  context "teachers" do
    before :once do
      course_with_teacher(:active_all => true)
    end

    it "should return the defaults if nothing specified" do
      length = Course.default_tabs.length
      tab_ids = @course.tabs_available(@user).map{|t| t[:id] }
      expect(tab_ids).to eql(Course.default_tabs.map{|t| t[:id] })
      expect(tab_ids.length).to eql(length)
    end

    it "should overwrite the order of tabs if configured" do
      @course.tab_configuration = [{ id: Course::TAB_COLLABORATIONS }]
      available_tabs = @course.tabs_available(@user).map { |tab| tab[:id] }
      default_tabs   = Course.default_tabs.map           { |tab| tab[:id] }
      custom_tabs    = @course.tab_configuration.map     { |tab| tab[:id] }

      expect(available_tabs).to        eq (custom_tabs + default_tabs).uniq
      expect(available_tabs.length).to eq default_tabs.length
    end

    it "should remove ids for tabs not in the default list" do
      @course.tab_configuration = [{'id' => 912}]
      expect(@course.tabs_available(@user).map{|t| t[:id] }).not_to be_include(912)
      tab_ids = @course.tabs_available(@user).map{|t| t[:id] }
      expect(tab_ids).to eql(Course.default_tabs.map{|t| t[:id] })
      expect(tab_ids.length).to be > 0
      expect(@course.tabs_available(@user).map{|t| t[:label] }.compact.length).to eql(tab_ids.length)
    end
  end

  context "students" do
    before :once do
      course_with_student(:active_all => true)
    end

    it "should hide unused tabs if not an admin" do
      tab_ids = @course.tabs_available(@user).map{|t| t[:id] }
      expect(tab_ids).not_to be_include(Course::TAB_SETTINGS)
      expect(tab_ids.length).to be > 0
    end

    it "should show grades tab for students" do
      tab_ids = @course.tabs_available(@user).map{|t| t[:id] }
      expect(tab_ids).to be_include(Course::TAB_GRADES)
    end

    it "should include tabs for active external tools" do
      tools = []
      2.times do |n|
        tools << @course.context_external_tools.create!(
          :url => "http://example.com/ims/lti",
          :consumer_key => "asdf",
          :shared_secret => "hjkl",
          :name => "external tool #{n+1}",
          :course_navigation => {
            :text => "blah",
            :url =>  "http://example.com/ims/lti",
            :default => false,
          }
        )
      end
      t1, t2 = tools

      t2.workflow_state = "deleted"
      t2.save!

      tabs = @course.tabs_available.map { |tab| tab[:id] }

      expect(tabs).to be_include(t1.asset_string)
      expect(tabs).not_to be_include(t2.asset_string)
    end

    it "should not include tabs for external tools if opt[:include_external] is false" do
      t1 = @course.context_external_tools.create!(
             :url => "http://example.com/ims/lti",
             :consumer_key => "asdf",
             :shared_secret => "hjkl",
             :name => "external tool 1",
             :course_navigation => {
               :text => "blah",
               :url =>  "http://example.com/ims/lti",
               :default => false,
             }
           )

      tabs = @course.tabs_available(nil, :include_external => false).map { |tab| tab[:id] }

      expect(tabs).not_to be_include(t1.asset_string)
    end

    it 'includes message handlers if opt[:include_external] is true' do
      mock_tab = {
        :id => '1234',
        :label => 'my_label',
        :css_class => '1234',
        :href => :launch_path_helper,
        :visibility => nil,
        :external => true,
        :hidden => false,
        :args => [1, 2]
      }
      Lti::MessageHandler.stubs(:lti_apps_tabs).returns([mock_tab])
      expect(@course.tabs_available(nil, :include_external => true)).to include(mock_tab)
    end

  end

  context "observers" do
    before :once do
      course_with_student(:active_all => true)
      @student = @user
      user(:active_all => true)
      @oe = @course.enroll_user(@user, 'ObserverEnrollment')
      @oe.accept
      @oe.associated_user_id = @student.id
      @oe.save!
      @user.reload
    end

    it "should not show grades tab for observers" do
      @oe.associated_user_id = nil
      @oe.save!
      @user.reload
      tab_ids = @course.tabs_available(@user).map{|t| t[:id] }
      expect(tab_ids).not_to be_include(Course::TAB_GRADES)
    end

    it "should show grades tab for observers if they are linked to a student" do
      tab_ids = @course.tabs_available(@user).map{|t| t[:id] }
      expect(tab_ids).to be_include(Course::TAB_GRADES)
    end

    it "should show discussion tab for observers by default" do
      tab_ids = @course.tabs_available(@user).map{|t| t[:id] }
      expect(tab_ids).to be_include(Course::TAB_DISCUSSIONS)
    end

    it "should not show discussion tab for observers without read_forum" do
      RoleOverride.create!(:context => @course.account, :permission => 'read_forum',
                           :role => observer_role, :enabled => false)
      tab_ids = @course.tabs_available(@user).map{|t| t[:id] }
      expect(tab_ids).not_to be_include(Course::TAB_DISCUSSIONS)
    end

    it "should recognize active_course_level_observers" do
      user = user_with_pseudonym
      observer_enrollment = @course.enroll_user(user, 'ObserverEnrollment',:enrollment_state => 'active')
      @course_level_observer = observer_enrollment.user

      course_observers = @course.active_course_level_observers
      expect(course_observers).to be_include(@course_level_observer)
      expect(course_observers).to_not be_include(@oe.user)
    end
  end

  context "a public course" do
    before :once do
      course(:active_all => true).update_attributes(:is_public => true, :indexed => true)
      @course.announcements.create!(:title => 'Title', :message => 'Message')
      default_group = @course.root_outcome_group
      outcome = @course.created_learning_outcomes.create!(:title => 'outcome')
      default_group.add_outcome(outcome)
    end

    it "should not show announcements tabs without a current user" do
      tab_ids = @course.tabs_available(nil).map{|t| t[:id] }
      expect(tab_ids).not_to include(Course::TAB_ANNOUNCEMENTS)
    end

    it "should not show announcements to a user not enrolled in the class" do
      user
      tab_ids = @course.tabs_available(@user).map{|t| t[:id] }
      expect(tab_ids).not_to include(Course::TAB_ANNOUNCEMENTS)
    end

    it "should show the announcements tab to an enrolled user" do
      @course.enroll_student(user).accept!
      tab_ids = @course.tabs_available(@user).map{|t| t[:id] }
      expect(tab_ids).to include(Course::TAB_ANNOUNCEMENTS)
    end

    it "should not show outcomes tabs without a current user" do
      tab_ids = @course.tabs_available(nil).map{|t| t[:id] }
      expect(tab_ids).not_to include(Course::TAB_OUTCOMES)
   end

    it "should not show outcomes to a user not enrolled in the class" do
      user
      tab_ids = @course.tabs_available(@user).map{|t| t[:id] }
      expect(tab_ids).not_to include(Course::TAB_OUTCOMES)
    end

    it "should show the outcomes tab to an enrolled user" do
      @course.enroll_student(user).accept!
      tab_ids = @course.tabs_available(@user).map{|t| t[:id] }
      expect(tab_ids).to include(Course::TAB_OUTCOMES)
    end
  end
end

describe Course, "backup" do
  let_once :course_to_backup do
    @course = course
    group = @course.assignment_groups.create!(:name => "Some Assignment Group")
    @course.assignments.create!(:title => "Some Assignment", :assignment_group => group)
    @course.calendar_events.create!(:title => "Some Event", :start_at => Time.now, :end_at => Time.now)
    @course.wiki.wiki_pages.create!(:title => "Some Page")
    topic = @course.discussion_topics.create!(:title => "Some Discussion")
    topic.discussion_entries.create!(:message => "just a test")
    @course
  end

  it "should backup to a valid data structure" do
    data = course_to_backup.backup
    expect(data).not_to be_nil
    expect(data.length).to be > 0
    expect(data.any?{|i| i.is_a?(Assignment)}).to eql(true)
    expect(data.any?{|i| i.is_a?(WikiPage)}).to eql(true)
    expect(data.any?{|i| i.is_a?(DiscussionTopic)}).to eql(true)
    expect(data.any?{|i| i.is_a?(CalendarEvent)}).to eql(true)
  end

  it "should backup to a valid json string" do
    data = course_to_backup.backup_to_json
    expect(data).not_to be_nil
    expect(data.length).to be > 0
    parse = JSON.parse(data) rescue nil
    expect(parse).not_to be_nil
    expect(parse).to be_is_a(Array)
    expect(parse.length).to be > 0
  end

  it "should not cross learning outcomes with learning outcome groups in the association" do
    skip('fails when being run in the single thread rake task')
    # set up two courses with two outcomes
    course = course_model
    default_group = course.root_outcome_group
    outcome = course.created_learning_outcomes.create!
    default_group.add_outcome(outcome)

    other_course = course_model
    other_default_group = other_course.root_outcome_group
    other_outcome = other_course.created_learning_outcomes.create!
    other_default_group.add_outcome(other_outcome)

    # add another group to the first course, which "coincidentally" has the
    # same id as the second course's outcome
    other_group = course.learning_outcome_groups.build
    other_group.id = other_outcome.id
    other_group.save!
    default_group.adopt_outcome_group(other_group)

    # reload and check
    course.reload
    other_course.reload
    expect(course.learning_outcomes).to be_include(outcome)
    expect(course.learning_outcomes).not_to be_include(other_outcome)
    expect(other_course.learning_outcomes).to be_include(other_outcome)
  end

  it "should not count learning outcome groups as having outcomes" do
    course = course_model
    default_group = course.root_outcome_group
    other_group = course.learning_outcome_groups.create!(:title => 'other group')
    default_group.adopt_outcome_group(other_group)

    expect(course).not_to have_outcomes
  end

end

describe Course, 'grade_publishing' do
  before :once do
    @course = Course.new
    @course.root_account_id = Account.default.id
    @course.save!
    @course_section = @course.default_section
  end

  after(:each) do
    Course.valid_grade_export_types.delete("test_export")
  end

  context 'mocked plugin settings' do

    before(:each) do
      @plugin_settings = Canvas::Plugin.find!("grade_export").default_settings.clone
      @plugin = mock()
      Canvas::Plugin.stubs("find!".to_sym).with('grade_export').returns(@plugin)
      @plugin.stubs(:settings).returns{@plugin_settings}
    end

    context 'grade_publishing_status_translation' do
      it 'should work with nil statuses and messages' do
        expect(@course.grade_publishing_status_translation(nil, nil)).to eq "Unpublished"
        expect(@course.grade_publishing_status_translation(nil, "hi")).to eq "Unpublished: hi"
        expect(@course.grade_publishing_status_translation("published", nil)).to eq "Published"
        expect(@course.grade_publishing_status_translation("published", "hi")).to eq "Published: hi"
      end

      it 'should work with invalid statuses' do
        expect(@course.grade_publishing_status_translation("invalid_status", nil)).to eq "Unknown status, invalid_status"
        expect(@course.grade_publishing_status_translation("invalid_status", "what what")).to eq "Unknown status, invalid_status: what what"
      end

      it "should work with empty string statuses and messages" do
        expect(@course.grade_publishing_status_translation("", "")).to eq "Unpublished"
        expect(@course.grade_publishing_status_translation("", "hi")).to eq "Unpublished: hi"
        expect(@course.grade_publishing_status_translation("published", "")).to eq "Published"
        expect(@course.grade_publishing_status_translation("published", "hi")).to eq "Published: hi"
      end

      it 'should work with all known statuses' do
        expect(@course.grade_publishing_status_translation("error", nil)).to eq "Error"
        expect(@course.grade_publishing_status_translation("error", "hi")).to eq "Error: hi"
        expect(@course.grade_publishing_status_translation("unpublished", nil)).to eq "Unpublished"
        expect(@course.grade_publishing_status_translation("unpublished", "hi")).to eq "Unpublished: hi"
        expect(@course.grade_publishing_status_translation("pending", nil)).to eq "Pending"
        expect(@course.grade_publishing_status_translation("pending", "hi")).to eq "Pending: hi"
        expect(@course.grade_publishing_status_translation("publishing", nil)).to eq "Publishing"
        expect(@course.grade_publishing_status_translation("publishing", "hi")).to eq "Publishing: hi"
        expect(@course.grade_publishing_status_translation("published", nil)).to eq "Published"
        expect(@course.grade_publishing_status_translation("published", "hi")).to eq "Published: hi"
        expect(@course.grade_publishing_status_translation("unpublishable", nil)).to eq "Unpublishable"
        expect(@course.grade_publishing_status_translation("unpublishable", "hi")).to eq "Unpublishable: hi"
      end
    end

    def make_student_enrollments
      @student_enrollments = create_enrollments(@course, create_users(9), return_type: :record)
      @student_enrollments[0].tap do |enrollment|
        enrollment.grade_publishing_status = "published"
        enrollment.save!
      end
      @student_enrollments[2].tap do |enrollment|
        enrollment.grade_publishing_status = "unpublishable"
        enrollment.save!
      end
      @student_enrollments[1].tap do |enrollment|
        enrollment.grade_publishing_status = "error"
        enrollment.grade_publishing_message = "cause of this reason"
        enrollment.save!
      end
      @student_enrollments[3].tap do |enrollment|
        enrollment.grade_publishing_status = "error"
        enrollment.grade_publishing_message = "cause of that reason"
        enrollment.save!
      end
      @student_enrollments[4].tap do |enrollment|
        enrollment.grade_publishing_status = "unpublishable"
        enrollment.save!
      end
      @student_enrollments[5].tap do |enrollment|
        enrollment.grade_publishing_status = "unpublishable"
        enrollment.save!
      end
      @student_enrollments[6].tap do |enrollment|
        enrollment.workflow_state = "inactive"
        enrollment.save!
      end
      @student_enrollments
    end

    def grade_publishing_user(sis_user_id = "U1")
      @user = user_with_pseudonym
      @pseudonym.account_id = @course.root_account_id
      @pseudonym.sis_user_id = sis_user_id
      @pseudonym.save!
      @user
    end

    context 'grade_publishing_statuses' do
      before :once do
        make_student_enrollments
      end

      it 'should generate enrollments categorized by grade publishing message' do
        messages, overall_status = @course.grade_publishing_statuses
        expect(overall_status).to eq "error"
        expect(messages.count).to eq 5
        expect(messages["Unpublished"].sort_by(&:id)).to eq [
            @student_enrollments[7],
            @student_enrollments[8]
          ].sort_by(&:id)
        expect(messages["Published"]).to eq [
            @student_enrollments[0]
          ]
        expect(messages["Error: cause of this reason"]).to eq [
            @student_enrollments[1]
          ]
        expect(messages["Error: cause of that reason"]).to eq [
            @student_enrollments[3]
          ]
        expect(messages["Unpublishable"].sort_by(&:id)).to eq [
            @student_enrollments[2],
            @student_enrollments[4],
            @student_enrollments[5]
          ].sort_by(&:id)
      end

      it 'should correctly figure out the overall status with no enrollments' do
        @course = course
        expect(@course.grade_publishing_statuses).to eq [{}, "unpublished"]
      end

      it 'should correctly figure out the overall status with invalid enrollment statuses' do
        @student_enrollments.each do |e|
          e.grade_publishing_status = "invalid status"
          e.save!
        end
        messages, overall_status = @course.grade_publishing_statuses
        expect(overall_status).to eq "error"
        expect(messages.count).to eq 3
        expect(messages["Unknown status, invalid status: cause of this reason"]).to eq [@student_enrollments[1]]
        expect(messages["Unknown status, invalid status: cause of that reason"]).to eq [@student_enrollments[3]]
        expect(messages["Unknown status, invalid status"].sort_by(&:id)).to eq [
            @student_enrollments[0],
            @student_enrollments[2],
            @student_enrollments[4],
            @student_enrollments[5],
            @student_enrollments[7],
            @student_enrollments[8]].sort_by(&:id)
      end

      it 'should fall back to the right overall status' do
        @student_enrollments.each do |e|
          e.grade_publishing_status = "unpublishable"
          e.grade_publishing_message = nil
          e.save!
        end
        expect(@course.reload.grade_publishing_statuses[1]).to eq "unpublishable"
        @student_enrollments[0].tap do |e|
          e.grade_publishing_status = "published"
          e.save!
        end
        expect(@course.reload.grade_publishing_statuses[1]).to eq "published"
        @student_enrollments[1].tap do |e|
          e.grade_publishing_status = "publishing"
          e.save!
        end
        expect(@course.reload.grade_publishing_statuses[1]).to eq "publishing"
        @student_enrollments[2].tap do |e|
          e.grade_publishing_status = "pending"
          e.save!
        end
        expect(@course.reload.grade_publishing_statuses[1]).to eq "pending"
        @student_enrollments[3].tap do |e|
          e.grade_publishing_status = "unpublished"
          e.save!
        end
        expect(@course.reload.grade_publishing_statuses[1]).to eq "unpublished"
        @student_enrollments[4].tap do |e|
          e.grade_publishing_status = "error"
          e.save!
        end
        expect(@course.reload.grade_publishing_statuses[1]).to eq "error"
      end
    end

    context 'publish_final_grades' do
      before :once do
        @grade_publishing_user = grade_publishing_user
      end

      it 'should check whether or not grade export is enabled - success' do
        @course.expects(:send_final_grades_to_endpoint).with(@user, nil).returns(nil)
        @plugin.stubs(:enabled?).returns(true)
        @plugin_settings[:publish_endpoint] = "http://localhost/endpoint"
        @course.publish_final_grades(@user)
      end

      it 'should check whether or not grade export is enabled - failure' do
        @plugin.stubs(:enabled?).returns(false)
        @plugin_settings[:publish_endpoint] = "http://localhost/endpoint"
        expect(lambda {@course.publish_final_grades(@user)}).to raise_error("final grade publishing disabled")
      end

      it 'should update all student enrollments with pending and a last update status' do
        @course = course
        make_student_enrollments
        expect(@student_enrollments.map(&:reload).map(&:grade_publishing_status)).to eq ["published", "error", "unpublishable", "error", "unpublishable", "unpublishable", "unpublished", "unpublished", "unpublished"]
        expect(@student_enrollments.map(&:grade_publishing_message)).to eq [nil, "cause of this reason", nil, "cause of that reason", nil, nil, nil, nil, nil]
        expect(@student_enrollments.map(&:workflow_state)).to eq ["active"] * 6 + ["inactive"] + ["active"] * 2
        expect(@student_enrollments.map(&:last_publish_attempt_at)).to eq [nil] * 9
        grade_publishing_user("U2")
        @course.expects(:send_final_grades_to_endpoint).with(@user, nil).returns(nil)
        @plugin.stubs(:enabled?).returns(true)
        @plugin_settings[:publish_endpoint] = "http://localhost/endpoint"
        @course.publish_final_grades(@user)
        expect(@student_enrollments.map(&:reload).map(&:grade_publishing_status)).to eq ["pending"] * 6 + ["unpublished"] + ["pending"] * 2
        expect(@student_enrollments.map(&:grade_publishing_message)).to eq [nil] * 9
        expect(@student_enrollments.map(&:workflow_state)).to eq ["active"] * 6 + ["inactive"] + ["active"] * 2
        @student_enrollments.map(&:last_publish_attempt_at).each_with_index do |time, i|
          if i == 6
            expect(time).to be_nil
          else
            expect(time).to be >= @course.created_at
          end
        end
      end

      it 'should kick off the actual grade send' do
        @course.expects(:send_later_if_production).with(:send_final_grades_to_endpoint, @user, nil).returns(nil)
        @plugin.stubs(:enabled?).returns(true)
        @plugin_settings[:publish_endpoint] = "http://localhost/endpoint"
        @course.publish_final_grades(@user)
      end

      it 'should kick off the actual grade send for a specific user' do
        make_student_enrollments
        @course.expects(:send_later_if_production).with(:send_final_grades_to_endpoint, @user, @student_enrollments.first.user_id).returns(nil)
        @plugin.stubs(:enabled?).returns(true)
        @plugin_settings[:publish_endpoint] = "http://localhost/endpoint"
        @course.publish_final_grades(@user, @student_enrollments.first.user_id)
        expect(@student_enrollments.first.reload.grade_publishing_status).to eq "pending"
      end

      it 'should kick off the timeout when a success timeout is defined and waiting is configured' do
        @course.expects(:send_later_if_production).with(:send_final_grades_to_endpoint, @user, nil).returns(nil)
        current_time = Time.now.utc
        Time.stubs(:now).returns(current_time)
        current_time.stubs(:utc).returns(current_time)
        @course.expects(:send_at).with(current_time + 1.seconds, :expire_pending_grade_publishing_statuses, current_time).returns(nil)
        @plugin.stubs(:enabled?).returns(true)
        @plugin_settings.merge!({
            :publish_endpoint => "http://localhost/endpoint",
            :success_timeout => "1",
            :wait_for_success => "yes"
          })
        @course.publish_final_grades(@user)
      end

      it 'should not kick off the timeout when a success timeout is defined and waiting is not configured' do
        @course.expects(:send_later_if_production).with(:send_final_grades_to_endpoint, @user, nil).returns(nil)
        current_time = Time.now.utc
        Time.stubs(:now).returns(current_time)
        current_time.stubs(:utc).returns(current_time)
        @course.expects(:send_at).times(0)
        @plugin.stubs(:enabled?).returns(true)
        @plugin_settings.merge!({
            :publish_endpoint => "http://localhost/endpoint",
            :success_timeout => "1",
            :wait_for_success => "no"
          })
        @course.publish_final_grades(@user)
      end

      it 'should not kick off the timeout when a success timeout is not defined and waiting is not configured' do
        @course.expects(:send_later_if_production).with(:send_final_grades_to_endpoint, @user, nil).returns(nil)
        current_time = Time.now.utc
        Time.stubs(:now).returns(current_time)
        current_time.stubs(:utc).returns(current_time)
        @course.expects(:send_at).times(0)
        @plugin.stubs(:enabled?).returns(true)
        @plugin_settings.merge!({
            :publish_endpoint => "http://localhost/endpoint",
            :success_timeout => "",
            :wait_for_success => "no"
          })
        @course.publish_final_grades(@user)
      end

      it 'should not kick off the timeout when a success timeout is not defined and waiting is configured' do
        @course.expects(:send_later_if_production).with(:send_final_grades_to_endpoint, @user, nil).returns(nil)
        current_time = Time.now.utc
        Time.stubs(:now).returns(current_time)
        current_time.stubs(:utc).returns(current_time)
        @course.expects(:send_at).times(0)
        @plugin.stubs(:enabled?).returns(true)
        @plugin_settings.merge!({
            :publish_endpoint => "http://localhost/endpoint",
            :success_timeout => "no",
            :wait_for_success => "yes"
          })
        @course.publish_final_grades(@user)
      end
    end

    context 'should_kick_off_grade_publishing_timeout?' do
      it 'should cover all the necessary cases' do
        @plugin_settings.merge! :success_timeout => "no", :wait_for_success => "yes"
        expect(@course.should_kick_off_grade_publishing_timeout?).to be_falsey
        @plugin_settings.merge! :success_timeout => "", :wait_for_success => "no"
        expect(@course.should_kick_off_grade_publishing_timeout?).to be_falsey
        @plugin_settings.merge! :success_timeout => "1", :wait_for_success => "no"
        expect(@course.should_kick_off_grade_publishing_timeout?).to be_falsey
        @plugin_settings.merge! :success_timeout => "1", :wait_for_success => "yes"
        expect(@course.should_kick_off_grade_publishing_timeout?).to be_truthy
      end
    end

    context 'valid_grade_export_types' do
      it "should support instructure_csv" do
        expect(Course.valid_grade_export_types["instructure_csv"][:name]).to eq "Instructure formatted CSV"
        course = mock()
        enrollments = [mock(), mock()]
        publishing_pseudonym = mock()
        publishing_user = mock()
        course.expects(:generate_grade_publishing_csv_output).with(enrollments, publishing_user, publishing_pseudonym).returns 42
        expect(Course.valid_grade_export_types["instructure_csv"][:callback].call(course,
            enrollments, publishing_user, publishing_pseudonym)).to eq 42
        expect(Course.valid_grade_export_types["instructure_csv"][:requires_grading_standard]).to be_falsey
        expect(Course.valid_grade_export_types["instructure_csv"][:requires_publishing_pseudonym]).to be_falsey
      end
    end

    context 'send_final_grades_to_endpoint' do
      before(:once) do
        make_student_enrollments
        grade_publishing_user
      end

      it "should clear the grade publishing message of unpublishable enrollments" do
        @plugin.stubs(:enabled?).returns(true)
        @plugin_settings.merge! :publish_endpoint => "http://localhost/endpoint", :format_type => "test_format"
        @ase = @student_enrollments.find_all{|e| e.workflow_state == 'active'}
        Course.stubs(:valid_grade_export_types).returns({
            "test_format" => {
                :callback => lambda {|course, enrollments, publishing_user, publishing_pseudonym|
                  expect(course).to eq @course
                  expect(enrollments.sort_by(&:id)).to eq @ase.sort_by(&:id)
                  expect(publishing_pseudonym).to eq @pseudonym
                  expect(publishing_user).to eq @user
                  return [
                      [[@ase[2].id, @ase[5].id],
                       "post1",
                       "test/mime1"],
                      [[@ase[4].id, @ase[7].id],
                       "post2",
                       "test/mime2"]]
                }
              }
          })
        SSLCommon.expects(:post_data).with("http://localhost/endpoint", "post1", "test/mime1", {})
        SSLCommon.expects(:post_data).with("http://localhost/endpoint", "post2", "test/mime2", {})
        @course.send_final_grades_to_endpoint @user
        expect(@student_enrollments.map(&:reload).map(&:grade_publishing_status)).to eq ["unpublishable", "unpublishable", "published", "unpublishable", "published", "published", "unpublished", "unpublishable", "published"]
        expect(@student_enrollments.map(&:grade_publishing_message)).to eq [nil] * 9
      end

      it "should try to publish appropriate enrollments" do
        plugin_settings = Course.valid_grade_export_types["instructure_csv"]
        Course.stubs(:valid_grade_export_types).returns(plugin_settings.merge({
          "instructure_csv" => { :requires_grading_standard => true, :requires_publishing_pseudonym => true }}))
        @course.grading_standard_enabled = true
        @course.save!
        @plugin.stubs(:enabled?).returns(true)
        @plugin_settings.merge!({
            :publish_endpoint => "http://localhost/endpoint",
            :format_type => "instructure_csv"
        })
        @checked = false
        Course.stubs(:valid_grade_export_types).returns({
            "instructure_csv" => {
                :callback => lambda {|course, enrollments, publishing_user, publishing_pseudonym|
                  expect(course).to eq @course
                  expect(enrollments.sort_by(&:id)).to eq @student_enrollments.sort_by(&:id).find_all{|e| e.workflow_state == 'active'}
                  expect(publishing_pseudonym).to eq @pseudonym
                  expect(publishing_user).to eq @user
                  @checked = true
                  return []
                }
              }
          })
        @course.send_final_grades_to_endpoint @user
        expect(@checked).to be_truthy
      end

      it "should try to publish appropriate enrollments (limited users)" do
        plugin_settings = Course.valid_grade_export_types["instructure_csv"]
        Course.stubs(:valid_grade_export_types).returns(plugin_settings.merge({
                "instructure_csv" => { :requires_grading_standard => true, :requires_publishing_pseudonym => true }}))
        @course.grading_standard_enabled = true
        @course.save!
        @plugin.stubs(:enabled?).returns(true)
        @plugin_settings.merge!({
                                    :publish_endpoint => "http://localhost/endpoint",
                                    :format_type => "instructure_csv"
                                })
        @checked = false
        Course.stubs(:valid_grade_export_types).returns({
                                                            "instructure_csv" => {
                                                                :callback => lambda {|course, enrollments, publishing_user, publishing_pseudonym|
                                                                  expect(course).to eq @course
                                                                  expect(enrollments).to eq [@student_enrollments.first]
                                                                  expect(publishing_pseudonym).to eq @pseudonym
                                                                  expect(publishing_user).to eq @user
                                                                  @checked = true
                                                                  return []
                                                                }
                                                            }
                                                        })
        @course.send_final_grades_to_endpoint @user, @student_enrollments.first.user_id
        expect(@checked).to be_truthy
      end

      it "should make sure grade publishing is enabled" do
        @plugin.stubs(:enabled?).returns(false)
        expect(lambda {@course.send_final_grades_to_endpoint nil}).to raise_error("final grade publishing disabled")
        expect(@student_enrollments.map(&:reload).map(&:grade_publishing_status)).to eq ["error"] * 6 + ["unpublished"] + ["error"] * 2
        expect(@student_enrollments.map(&:grade_publishing_message)).to eq ["final grade publishing disabled"] * 6 + [nil] + ["final grade publishing disabled"] * 2
      end

      it "should make sure an endpoint is defined" do
        @plugin.stubs(:enabled?).returns(true)
        @plugin_settings.merge! :publish_endpoint => ""
        expect(lambda {@course.send_final_grades_to_endpoint nil}).to raise_error("endpoint undefined")
        expect(@student_enrollments.map(&:reload).map(&:grade_publishing_status)).to eq ["error"] * 6 + ["unpublished"] + ["error"] * 2
        expect(@student_enrollments.map(&:grade_publishing_message)).to eq ["endpoint undefined"] * 6 + [nil] + ["endpoint undefined"] * 2
      end

      it "should make sure the publishing user can publish" do
        plugin_settings = Course.valid_grade_export_types["instructure_csv"]
        Course.stubs(:valid_grade_export_types).returns(plugin_settings.merge({
          "instructure_csv" => { :requires_grading_standard => false, :requires_publishing_pseudonym => true }}))
        @user = user
        @plugin.stubs(:enabled?).returns(true)
        @plugin_settings.merge! :publish_endpoint => "http://localhost/endpoint"
        expect(lambda {@course.send_final_grades_to_endpoint @user}).to raise_error("publishing disallowed for this publishing user")
        expect(@student_enrollments.map(&:reload).map(&:grade_publishing_status)).to eq ["error"] * 6 + ["unpublished"] + ["error"] * 2
        expect(@student_enrollments.map(&:grade_publishing_message)).to eq ["publishing disallowed for this publishing user"] * 6 + [nil] + ["publishing disallowed for this publishing user"] * 2
      end

      it "should make sure there's a grading standard" do
        plugin_settings = Course.valid_grade_export_types["instructure_csv"]
        Course.stubs(:valid_grade_export_types).returns(plugin_settings.merge({
          "instructure_csv" => { :requires_grading_standard => true, :requires_publishing_pseudonym => false }}))
        @user = user
        @plugin.stubs(:enabled?).returns(true)
        @plugin_settings.merge! :publish_endpoint => "http://localhost/endpoint"
        expect(lambda {@course.send_final_grades_to_endpoint @user}).to raise_error("grade publishing requires a grading standard")
        expect(@student_enrollments.map(&:reload).map(&:grade_publishing_status)).to eq ["error"] * 6 + ["unpublished"] + ["error"] * 2
        expect(@student_enrollments.map(&:grade_publishing_message)).to eq ["grade publishing requires a grading standard"] * 6 + [nil] + ["grade publishing requires a grading standard"] * 2
      end

      it "should make sure the format type is supported" do
        @plugin.stubs(:enabled?).returns(true)
        @plugin_settings.merge! :publish_endpoint => "http://localhost/endpoint", :format_type => "invalid_Format"
        expect(lambda {@course.send_final_grades_to_endpoint @user}).to raise_error("unknown format type: invalid_Format")
        expect(@student_enrollments.map(&:reload).map(&:grade_publishing_status)).to eq ["error"] * 6 + ["unpublished"] + ["error"] * 2
        expect(@student_enrollments.map(&:grade_publishing_message)).to eq ["unknown format type: invalid_Format"] * 6 + [nil] + ["unknown format type: invalid_Format"] * 2
      end

      def sample_grade_publishing_request(published_status)
        @plugin.stubs(:enabled?).returns(true)
        @plugin_settings.merge! :publish_endpoint => "http://localhost/endpoint", :format_type => "test_format"
        @ase = @student_enrollments.find_all{|e| e.workflow_state == 'active'}
        Course.stubs(:valid_grade_export_types).returns({
            "test_format" => {
                :callback => lambda {|course, enrollments, publishing_user, publishing_pseudonym|
                  expect(course).to eq @course
                  expect(enrollments.sort_by(&:id)).to eq @ase.sort_by(&:id)
                  expect(publishing_pseudonym).to eq @pseudonym
                  expect(publishing_user).to eq @user
                  return [
                      [[@ase[1].id, @ase[3].id],
                       "post1",
                       "test/mime1"],
                      [[@ase[4].id, @ase[7].id],
                       "post2",
                       "test/mime2"]]
                }
              }
          })
        SSLCommon.expects(:post_data).with("http://localhost/endpoint", "post1", "test/mime1", {})
        SSLCommon.expects(:post_data).with("http://localhost/endpoint", "post2", "test/mime2", {})
        @course.send_final_grades_to_endpoint @user
        expect(@student_enrollments.map(&:reload).map(&:grade_publishing_status)).to eq ["unpublishable", published_status, "unpublishable", published_status, published_status, "unpublishable", "unpublished", "unpublishable", published_status]
        expect(@student_enrollments.map(&:grade_publishing_message)).to eq [nil] * 9
      end

      it "should make callback's requested posts and mark requested enrollment ids ignored" do
        sample_grade_publishing_request("published")
      end

      it "should recompute final grades" do
        @course.expects(:recompute_student_scores_without_send_later)
        sample_grade_publishing_request("published")
      end

      it "should not set the status to publishing if a timeout didn't kick off - timeout, wait" do
        @plugin_settings.merge! :success_timeout => "1", :wait_for_success => "yes"
        sample_grade_publishing_request("publishing")
      end

      it "should not set the status to publishing if a timeout didn't kick off - timeout, no wait" do
        @plugin_settings.merge! :success_timeout => "2", :wait_for_success => "false"
        sample_grade_publishing_request("published")
      end

      it "should not set the status to publishing if a timeout didn't kick off - no timeout, wait" do
        @plugin_settings.merge! :success_timeout => "no", :wait_for_success => "yes"
        sample_grade_publishing_request("published")
      end

      it "should not set the status to publishing if a timeout didn't kick off - no timeout, no wait" do
        @plugin_settings.merge! :success_timeout => "false", :wait_for_success => "no"
        sample_grade_publishing_request("published")
      end

      it "should try and make all posts even if one of the postings fails" do
        @plugin.stubs(:enabled?).returns(true)
        @plugin_settings.merge! :publish_endpoint => "http://localhost/endpoint", :format_type => "test_format"
        @ase = @student_enrollments.find_all{|e| e.workflow_state == 'active'}
        Course.stubs(:valid_grade_export_types).returns({
            "test_format" => {
                :callback => lambda {|course, enrollments, publishing_user, publishing_pseudonym|
                  expect(course).to eq @course
                  expect(enrollments.sort_by(&:id)).to eq @ase.sort_by(&:id)
                  expect(publishing_pseudonym).to eq @pseudonym
                  expect(publishing_user).to eq @user
                  return [
                      [[@ase[1].id, @ase[3].id],
                       "post1",
                       "test/mime1"],
                      [[@ase[4].id, @ase[7].id],
                       "post2",
                       "test/mime2"],
                      [[@ase[2].id, @ase[0].id],
                       "post3",
                       "test/mime3"]]
                }
              }
          })
        SSLCommon.expects(:post_data).with("http://localhost/endpoint", "post1", "test/mime1", {})
        SSLCommon.expects(:post_data).with("http://localhost/endpoint", "post2", "test/mime2", {}).raises("waaah fail")
        SSLCommon.expects(:post_data).with("http://localhost/endpoint", "post3", "test/mime3", {})
        expect(lambda {@course.send_final_grades_to_endpoint(@user)}).to raise_error("waaah fail")
        expect(@student_enrollments.map(&:reload).map(&:grade_publishing_status)).to eq ["published", "published", "published", "published", "error", "unpublishable", "unpublished", "unpublishable", "error"]
        expect(@student_enrollments.map(&:grade_publishing_message)).to eq [nil] * 4 + ["waaah fail"] + [nil] * 3 + ["waaah fail"]
      end

      it "should try and make all posts even if two of the postings fail" do
        @plugin.stubs(:enabled?).returns(true)
        @plugin_settings.merge! :publish_endpoint => "http://localhost/endpoint", :format_type => "test_format"
        @ase = @student_enrollments.find_all{|e| e.workflow_state == 'active'}
        Course.stubs(:valid_grade_export_types).returns({
            "test_format" => {
                :callback => lambda {|course, enrollments, publishing_user, publishing_pseudonym|
                  expect(course).to eq @course
                  expect(enrollments.sort_by(&:id)).to eq @ase.sort_by(&:id)
                  expect(publishing_pseudonym).to eq @pseudonym
                  expect(publishing_user).to eq @user
                  return [
                      [[@ase[1].id, @ase[3].id],
                       "post1",
                       "test/mime1"],
                      [[@ase[4].id, @ase[7].id],
                       "post2",
                       "test/mime2"],
                      [[@ase[2].id, @ase[0].id],
                       "post3",
                       "test/mime3"]]
                }
              }
          })
        SSLCommon.expects(:post_data).with("http://localhost/endpoint", "post1", "test/mime1", {}).raises("waaah fail")
        SSLCommon.expects(:post_data).with("http://localhost/endpoint", "post2", "test/mime2", {}).raises("waaah fail")
        SSLCommon.expects(:post_data).with("http://localhost/endpoint", "post3", "test/mime3", {})
        expect(lambda {@course.send_final_grades_to_endpoint(@user)}).to raise_error("waaah fail")
        expect(@student_enrollments.map(&:reload).map(&:grade_publishing_status)).to eq ["published", "error", "published", "error", "error", "unpublishable", "unpublished", "unpublishable", "error"]
        expect(@student_enrollments.map(&:grade_publishing_message)).to eq [nil, "waaah fail", nil, "waaah fail", "waaah fail", nil, nil, nil, "waaah fail"]
      end

      it "should fail gracefully when the posting generator fails" do
        @plugin.stubs(:enabled?).returns(true)
        @plugin_settings.merge! :publish_endpoint => "http://localhost/endpoint", :format_type => "test_format"
        @ase = @student_enrollments.find_all{|e| e.workflow_state == 'active'}
        Course.stubs(:valid_grade_export_types).returns({
            "test_format" => {
                :callback => lambda {|course, enrollments, publishiing_user, publishing_pseudonym|
                  raise "waaah fail"
                }
              }
          })
        expect(lambda {@course.send_final_grades_to_endpoint(@user)}).to raise_error("waaah fail")
        expect(@student_enrollments.map(&:reload).map(&:grade_publishing_status)).to eq ["error", "error", "error", "error", "error", "error", "unpublished", "error", "error"]
        expect(@student_enrollments.map(&:grade_publishing_message)).to eq ["waaah fail"] * 6 + [nil] + ["waaah fail"] * 2
      end

      it "should pass header parameters to post" do
        @plugin.stubs(:enabled?).returns(true)
        @plugin_settings.merge! :publish_endpoint => "http://localhost/endpoint", :format_type => "test_format"
        @ase = @student_enrollments.find_all{|e| e.workflow_state == 'active'}
        Course.stubs(:valid_grade_export_types).returns({
                                                            "test_format" => {
                                                                :callback => lambda {|course, enrollments, publishing_user, publishing_pseudonym|
                                                                  expect(course).to eq @course
                                                                  expect(enrollments.sort_by(&:id)).to eq @ase.sort_by(&:id)
                                                                  expect(publishing_pseudonym).to eq @pseudonym
                                                                  expect(publishing_user).to eq @user
                                                                  return [
                                                                      [[@ase[1].id, @ase[3].id],
                                                                       "post1",
                                                                       "test/mime1",{"header_param" => "header_value"}],
                                                                      [[@ase[4].id, @ase[5].id],
                                                                       "post2",
                                                                       "test/mime2"]]
                                                                }
                                                            }
                                                        })
        SSLCommon.expects(:post_data).with("http://localhost/endpoint", "post1", "test/mime1", {"header_param" => "header_value"})
        SSLCommon.expects(:post_data).with("http://localhost/endpoint", "post2", "test/mime2", {})
        @course.send_final_grades_to_endpoint(@user)
        expect(@student_enrollments.map(&:reload).map(&:grade_publishing_status)).to eq ["unpublishable", "published", "unpublishable", "published", "published", "published", "unpublished", "unpublishable", "unpublishable"]
      end

      it 'should update enrollment status if no resource provided' do
        @plugin.stubs(:enabled?).returns(true)
        @plugin_settings.merge! :publish_endpoint => "http://localhost/endpoint", :format_type => "test_format"
        @ase = @student_enrollments.find_all{|e| e.workflow_state == 'active'}
        Course.stubs(:valid_grade_export_types).returns({
                                                            "test_format" => {
                                                                :callback => lambda {|course, enrollments, publishing_user, publishing_pseudonym|
                                                                  expect(course).to eq @course
                                                                  expect(enrollments.sort_by(&:id)).to eq @ase.sort_by(&:id)
                                                                  expect(publishing_pseudonym).to eq @pseudonym
                                                                  expect(publishing_user).to eq @user
                                                                  return [
                                                                      [[@ase[1].id, @ase[3].id],
                                                                       nil,
                                                                       nil],
                                                                      [[@ase[4].id, @ase[7].id],
                                                                       nil,
                                                                       nil]]
                                                                }
                                                            }
                                                        })
        SSLCommon.expects(:post_data).never
        @course.send_final_grades_to_endpoint @user
        expect(@student_enrollments.map(&:reload).map(&:grade_publishing_status)).to eq ["unpublishable", "published", "unpublishable", "published", "published", "unpublishable", "unpublished", "unpublishable", "published"]
        expect(@student_enrollments.map(&:grade_publishing_message)).to eq [nil] * 9
      end

    end

    context 'generate_grade_publishing_csv_output' do

      before :once do
        make_student_enrollments
        grade_publishing_user
        @course.assignment_groups.create(:name => "Assignments")
        a1 = @course.assignments.create!(:title => "A1", :points_possible => 10)
        a2 = @course.assignments.create!(:title => "A2", :points_possible => 10)
        @course.enroll_teacher(@user).tap{|e| e.workflow_state = 'active'; e.save!}
        @ase = @student_enrollments.find_all(&:active?)

        add_pseudonym(@ase[2], Account.default, "student2", nil)
        add_pseudonym(@ase[3], Account.default, "student3", "student3")
        add_pseudonym(@ase[4], Account.default, "student4a", "student4a")
        add_pseudonym(@ase[4], Account.default, "student4b", "student4b")
        another_account = account_model
        add_pseudonym(@ase[5], another_account, "student5", nil)
        add_pseudonym(@ase[6], another_account, "student6", "student6")
        add_pseudonym(@ase[7], Account.default, "student7a", "student7a")
        add_pseudonym(@ase[7], Account.default, "student7b", "student7b")

        a1.grade_student(@ase[0].user, { :grade => "9", :grader => @user })
        a2.grade_student(@ase[0].user, { :grade => "10", :grader => @user })
        a1.grade_student(@ase[1].user, { :grade => "6", :grader => @user })
        a2.grade_student(@ase[1].user, { :grade => "7", :grader => @user })
        a1.grade_student(@ase[7].user, { :grade => "8", :grader => @user })
        a2.grade_student(@ase[7].user, { :grade => "9", :grader => @user })
      end

      def add_pseudonym(enrollment, account, unique_id, sis_user_id)
        pseudonym = account.pseudonyms.build
        pseudonym.user = enrollment.user
        pseudonym.unique_id = unique_id
        pseudonym.sis_user_id = sis_user_id
        pseudonym.save!
      end

      it 'should generate valid csv without a grading standard' do
        @course.recompute_student_scores_without_send_later
        expect(@course.generate_grade_publishing_csv_output(@ase.map(&:reload), @user, @pseudonym)).to eq [
          [@ase.map(&:id),
               ("publisher_id,publisher_sis_id,course_id,course_sis_id,section_id,section_sis_id," +
                "student_id,student_sis_id,enrollment_id,enrollment_status," +
                "score\n" +
                "#{@user.id},U1,#{@course.id},,#{@ase[0].course_section_id},,#{@ase[0].user.id},,#{@ase[0].id},active,95\n" +
                "#{@user.id},U1,#{@course.id},,#{@ase[1].course_section_id},,#{@ase[1].user.id},,#{@ase[1].id},active,65\n" +
                "#{@user.id},U1,#{@course.id},,#{@ase[2].course_section_id},,#{@ase[2].user.id},,#{@ase[2].id},active,0\n" +
                "#{@user.id},U1,#{@course.id},,#{@ase[3].course_section_id},,#{@ase[3].user.id},student3,#{@ase[3].id},active,0\n" +
                "#{@user.id},U1,#{@course.id},,#{@ase[4].course_section_id},,#{@ase[4].user.id},student4a,#{@ase[4].id},active,0\n" +
                "#{@user.id},U1,#{@course.id},,#{@ase[4].course_section_id},,#{@ase[4].user.id},student4b,#{@ase[4].id},active,0\n" +
                "#{@user.id},U1,#{@course.id},,#{@ase[5].course_section_id},,#{@ase[5].user.id},,#{@ase[5].id},active,0\n" +
                "#{@user.id},U1,#{@course.id},,#{@ase[6].course_section_id},,#{@ase[6].user.id},,#{@ase[6].id},active,0\n" +
                "#{@user.id},U1,#{@course.id},,#{@ase[7].course_section_id},,#{@ase[7].user.id},student7a,#{@ase[7].id},active,85\n" +
                "#{@user.id},U1,#{@course.id},,#{@ase[7].course_section_id},,#{@ase[7].user.id},student7b,#{@ase[7].id},active,85\n"),
           "text/csv"]
        ]
      end

      it 'should generate valid csv without a publishing pseudonym' do
        @course.recompute_student_scores_without_send_later
        expect(@course.generate_grade_publishing_csv_output(@ase.map(&:reload), @user, nil)).to eq [
          [@ase.map(&:id),
               ("publisher_id,publisher_sis_id,course_id,course_sis_id,section_id,section_sis_id," +
                "student_id,student_sis_id,enrollment_id,enrollment_status," +
                "score\n" +
                "#{@user.id},,#{@course.id},,#{@ase[0].course_section_id},,#{@ase[0].user.id},,#{@ase[0].id},active,95\n" +
                "#{@user.id},,#{@course.id},,#{@ase[1].course_section_id},,#{@ase[1].user.id},,#{@ase[1].id},active,65\n" +
                "#{@user.id},,#{@course.id},,#{@ase[2].course_section_id},,#{@ase[2].user.id},,#{@ase[2].id},active,0\n" +
                "#{@user.id},,#{@course.id},,#{@ase[3].course_section_id},,#{@ase[3].user.id},student3,#{@ase[3].id},active,0\n" +
                "#{@user.id},,#{@course.id},,#{@ase[4].course_section_id},,#{@ase[4].user.id},student4a,#{@ase[4].id},active,0\n" +
                "#{@user.id},,#{@course.id},,#{@ase[4].course_section_id},,#{@ase[4].user.id},student4b,#{@ase[4].id},active,0\n" +
                "#{@user.id},,#{@course.id},,#{@ase[5].course_section_id},,#{@ase[5].user.id},,#{@ase[5].id},active,0\n" +
                "#{@user.id},,#{@course.id},,#{@ase[6].course_section_id},,#{@ase[6].user.id},,#{@ase[6].id},active,0\n" +
                "#{@user.id},,#{@course.id},,#{@ase[7].course_section_id},,#{@ase[7].user.id},student7a,#{@ase[7].id},active,85\n" +
                "#{@user.id},,#{@course.id},,#{@ase[7].course_section_id},,#{@ase[7].user.id},student7b,#{@ase[7].id},active,85\n"),
           "text/csv"]
        ]
      end

      it 'should generate valid csv with a section id' do
        @course_section.sis_source_id = "section1"
        @course_section.save!
        @course.recompute_student_scores_without_send_later
        expect(@course.generate_grade_publishing_csv_output(@ase.map(&:reload), @user, @pseudonym)).to eq [
          [@ase.map(&:id),
               ("publisher_id,publisher_sis_id,course_id,course_sis_id,section_id,section_sis_id," +
                "student_id,student_sis_id,enrollment_id,enrollment_status," +
                "score\n" +
                "#{@user.id},U1,#{@course.id},,#{@ase[0].course_section_id},section1,#{@ase[0].user.id},,#{@ase[0].id},active,95\n" +
                "#{@user.id},U1,#{@course.id},,#{@ase[1].course_section_id},section1,#{@ase[1].user.id},,#{@ase[1].id},active,65\n" +
                "#{@user.id},U1,#{@course.id},,#{@ase[2].course_section_id},section1,#{@ase[2].user.id},,#{@ase[2].id},active,0\n" +
                "#{@user.id},U1,#{@course.id},,#{@ase[3].course_section_id},section1,#{@ase[3].user.id},student3,#{@ase[3].id},active,0\n" +
                "#{@user.id},U1,#{@course.id},,#{@ase[4].course_section_id},section1,#{@ase[4].user.id},student4a,#{@ase[4].id},active,0\n" +
                "#{@user.id},U1,#{@course.id},,#{@ase[4].course_section_id},section1,#{@ase[4].user.id},student4b,#{@ase[4].id},active,0\n" +
                "#{@user.id},U1,#{@course.id},,#{@ase[5].course_section_id},section1,#{@ase[5].user.id},,#{@ase[5].id},active,0\n" +
                "#{@user.id},U1,#{@course.id},,#{@ase[6].course_section_id},section1,#{@ase[6].user.id},,#{@ase[6].id},active,0\n" +
                "#{@user.id},U1,#{@course.id},,#{@ase[7].course_section_id},section1,#{@ase[7].user.id},student7a,#{@ase[7].id},active,85\n" +
                "#{@user.id},U1,#{@course.id},,#{@ase[7].course_section_id},section1,#{@ase[7].user.id},student7b,#{@ase[7].id},active,85\n"),
           "text/csv"]
        ]
      end

      it 'should generate valid csv with a grading standard' do
        @course.grading_standard_id = 0
        @course.save!
        @course.recompute_student_scores_without_send_later
        expect(@course.generate_grade_publishing_csv_output(@ase.map(&:reload), @user, @pseudonym)).to eq [
          [@ase.map(&:id),
               ("publisher_id,publisher_sis_id,course_id,course_sis_id,section_id,section_sis_id," +
                "student_id,student_sis_id,enrollment_id,enrollment_status," +
                "score,grade\n" +
                "#{@user.id},U1,#{@course.id},,#{@ase[0].course_section_id},,#{@ase[0].user.id},,#{@ase[0].id},active,95,A\n" +
                "#{@user.id},U1,#{@course.id},,#{@ase[1].course_section_id},,#{@ase[1].user.id},,#{@ase[1].id},active,65,D\n" +
                "#{@user.id},U1,#{@course.id},,#{@ase[2].course_section_id},,#{@ase[2].user.id},,#{@ase[2].id},active,0,F\n" +
                "#{@user.id},U1,#{@course.id},,#{@ase[3].course_section_id},,#{@ase[3].user.id},student3,#{@ase[3].id},active,0,F\n" +
                "#{@user.id},U1,#{@course.id},,#{@ase[4].course_section_id},,#{@ase[4].user.id},student4a,#{@ase[4].id},active,0,F\n" +
                "#{@user.id},U1,#{@course.id},,#{@ase[4].course_section_id},,#{@ase[4].user.id},student4b,#{@ase[4].id},active,0,F\n" +
                "#{@user.id},U1,#{@course.id},,#{@ase[5].course_section_id},,#{@ase[5].user.id},,#{@ase[5].id},active,0,F\n" +
                "#{@user.id},U1,#{@course.id},,#{@ase[6].course_section_id},,#{@ase[6].user.id},,#{@ase[6].id},active,0,F\n" +
                "#{@user.id},U1,#{@course.id},,#{@ase[7].course_section_id},,#{@ase[7].user.id},student7a,#{@ase[7].id},active,85,B\n" +
                "#{@user.id},U1,#{@course.id},,#{@ase[7].course_section_id},,#{@ase[7].user.id},student7b,#{@ase[7].id},active,85,B\n"),
           "text/csv"]
        ]
      end

      it 'should generate valid csv and skip users with no computed final score' do
        @course.grading_standard_id = 0
        @course.save!
        @course.recompute_student_scores_without_send_later
        @ase.map(&:reload)

        @ase[1].computed_final_score = nil
        @ase[3].computed_final_score = nil
        @ase[4].computed_final_score = nil

        expect(@course.generate_grade_publishing_csv_output(@ase, @user, @pseudonym)).to eq [
          [@ase.map(&:id) - [@ase[1].id, @ase[3].id, @ase[4].id],
               ("publisher_id,publisher_sis_id,course_id,course_sis_id,section_id,section_sis_id," +
                "student_id,student_sis_id,enrollment_id,enrollment_status," +
                "score,grade\n" +
                "#{@user.id},U1,#{@course.id},,#{@ase[0].course_section_id},,#{@ase[0].user.id},,#{@ase[0].id},active,95,A\n" +
                "#{@user.id},U1,#{@course.id},,#{@ase[2].course_section_id},,#{@ase[2].user.id},,#{@ase[2].id},active,0,F\n" +
                "#{@user.id},U1,#{@course.id},,#{@ase[5].course_section_id},,#{@ase[5].user.id},,#{@ase[5].id},active,0,F\n" +
                "#{@user.id},U1,#{@course.id},,#{@ase[6].course_section_id},,#{@ase[6].user.id},,#{@ase[6].id},active,0,F\n" +
                "#{@user.id},U1,#{@course.id},,#{@ase[7].course_section_id},,#{@ase[7].user.id},student7a,#{@ase[7].id},active,85,B\n" +
                "#{@user.id},U1,#{@course.id},,#{@ase[7].course_section_id},,#{@ase[7].user.id},student7b,#{@ase[7].id},active,85,B\n"),
           "text/csv"]
        ]
      end
    end

    context 'expire_pending_grade_publishing_statuses' do
      it 'should update the right enrollments' do
        make_student_enrollments
        first_time = Time.now.utc
        second_time = first_time + 2.seconds
        expect(@student_enrollments.map(&:reload).map(&:grade_publishing_status)).to eq ["published", "error", "unpublishable", "error", "unpublishable", "unpublishable", "unpublished", "unpublished", "unpublished"]
        @student_enrollments[0].grade_publishing_status = "pending"
        @student_enrollments[0].last_publish_attempt_at = first_time
        @student_enrollments[1].grade_publishing_status = "publishing"
        @student_enrollments[1].last_publish_attempt_at = first_time
        @student_enrollments[2].grade_publishing_status = "pending"
        @student_enrollments[2].last_publish_attempt_at = second_time
        @student_enrollments[3].grade_publishing_status = "publishing"
        @student_enrollments[3].last_publish_attempt_at = second_time
        @student_enrollments[4].grade_publishing_status = "published"
        @student_enrollments[4].last_publish_attempt_at = first_time
        @student_enrollments[5].grade_publishing_status = "unpublished"
        @student_enrollments[5].last_publish_attempt_at = first_time
        @student_enrollments.map(&:save)
        expect(@student_enrollments.map(&:reload).map(&:grade_publishing_status)).to eq ["pending", "publishing", "pending", "publishing", "published", "unpublished", "unpublished", "unpublished", "unpublished"]
        @course.expire_pending_grade_publishing_statuses(first_time)
        expect(@student_enrollments.map(&:reload).map(&:grade_publishing_status)).to eq ["error", "error", "pending", "publishing", "published", "unpublished", "unpublished", "unpublished", "unpublished"]
      end
    end

    context 'grading_standard_enabled' do
      it 'should work for a number of boolean representations' do
        expect(@course.grading_standard_enabled?).to be_falsey
        expect(@course.grading_standard_enabled).to be_falsey
        [[false, false], [true, true], ["false", false], ["true", true],
            ["0", false], [0, false], ["1", true], [1, true], ["off", false],
            ["on", true], ["yes", true], ["no", false]].each do |val, enabled|
          @course.grading_standard_enabled = val
          expect(@course.grading_standard_enabled?).to eq enabled
          expect(@course.grading_standard_enabled).to eq enabled
          expect(@course.grading_standard_id).to be_nil unless enabled
          expect(@course.grading_standard_id).not_to be_nil if enabled
          expect(@course.bool_res(val)).to eq enabled
        end
      end
    end
  end

  context 'integration suite' do
    def quick_sanity_check(user, expect_success = true)
      Course.valid_grade_export_types["test_export"] = {
          :name => "test export",
          :callback => lambda {|course, enrollments, publishing_user, publishing_pseudonym|
            expect(course).to eq @course
            expect(publishing_pseudonym).to eq @pseudonym
            expect(publishing_user).to eq @user
            return [[[], "test-jt-data", "application/jtmimetype"]]
          },
          :requires_grading_standard => false, :requires_publishing_pseudonym => true}

      @plugin = Canvas::Plugin.find!('grade_export')
      @ps = PluginSetting.new(:name => @plugin.id, :settings => @plugin.default_settings)
      @ps.posted_settings = @plugin.default_settings.merge({
          :format_type => "test_export",
          :wait_for_success => "no",
          :publish_endpoint => "http://localhost/endpoint"
        })
      @ps.save!

      @course.grading_standard_id = 0
      if expect_success
        SSLCommon.expects(:post_data).with("http://localhost/endpoint", "test-jt-data", "application/jtmimetype", {})
      else
        SSLCommon.expects(:post_data).never
      end
      @course.publish_final_grades(user)
    end

    it 'should pass a quick sanity check' do
      @user = user_with_pseudonym
      @pseudonym.account_id = @course.root_account_id
      @pseudonym.sis_user_id = "U1"
      @pseudonym.save!
      quick_sanity_check(@user)
    end

    it 'should not allow grade publishing for a user that is disallowed' do
      @user = User.new
      expect(lambda { quick_sanity_check(@user, false) }).to raise_error("publishing disallowed for this publishing user")
    end

    it 'should not allow grade publishing for a user with a pseudonym in the wrong account' do
      @user = user_with_pseudonym
      @pseudonym.account = account_model
      @pseudonym.sis_user_id = "U1"
      @pseudonym.save!
      expect(lambda { quick_sanity_check(@user, false) }).to raise_error("publishing disallowed for this publishing user")
    end

    it 'should not allow grade publishing for a user with a pseudonym without a sis id' do
      @user = user_with_pseudonym
      @pseudonym.account_id = @course.root_account_id
      @pseudonym.sis_user_id = nil
      @pseudonym.save!
      expect(lambda { quick_sanity_check(@user, false) }).to raise_error("publishing disallowed for this publishing user")
    end

    it 'should publish csv' do
      @user = user_with_pseudonym
      @pseudonym.sis_user_id = "U1"
      @pseudonym.account_id = @course.root_account_id
      @pseudonym.save!

      @plugin = Canvas::Plugin.find!('grade_export')
      @ps = PluginSetting.new(:name => @plugin.id, :settings => @plugin.default_settings)
      @ps.posted_settings = @plugin.default_settings.merge({
          :format_type => "instructure_csv",
          :wait_for_success => "no",
          :publish_endpoint => "http://localhost/endpoint"
        })
      @ps.save!

      @course.grading_standard_id = 0
      csv = "publisher_id,publisher_sis_id,course_id,course_sis_id,section_id,section_sis_id,student_id," +
          "student_sis_id,enrollment_id,enrollment_status,score,grade\n"
      SSLCommon.expects(:post_data).with("http://localhost/endpoint", csv, "text/csv", {})
      @course.publish_final_grades(@user)
    end

    it 'should publish grades' do
      process_csv_data_cleanly(
        "user_id,login_id,password,first_name,last_name,email,status",
        "T1,Teacher1,,T,1,t1@example.com,active",
        "S1,Student1,,S,1,s1@example.com,active",
        "S2,Student2,,S,2,s2@example.com,active",
        "S3,Student3,,S,3,s3@example.com,active",
        "S4,Student4,,S,4,s4@example.com,active",
        "S5,Student5,,S,5,s5@example.com,active",
        "S6,Student6,,S,6,s6@example.com,active")
      process_csv_data_cleanly(
        "course_id,short_name,long_name,account_id,term_id,status",
        "C1,C1,C1,,,active")
      @course = Course.where(sis_source_id: "C1").first
      @course.assignment_groups.create(:name => "Assignments")
      process_csv_data_cleanly(
        "section_id,course_id,name,status,start_date,end_date",
        "S1,C1,S1,active,,",
        "S2,C1,S2,active,,",
        "S3,C1,S3,active,,",
        "S4,C1,S4,active,,")
      process_csv_data_cleanly(
        "course_id,user_id,role,section_id,status",
        ",T1,teacher,S1,active",
        ",S1,student,S1,active",
        ",S2,student,S2,active",
        ",S3,student,S2,active",
        ",S4,student,S1,active",
        ",S5,student,S3,active",
        ",S6,student,S4,active")
      a1 = @course.assignments.create!(:title => "A1", :points_possible => 10)
      a2 = @course.assignments.create!(:title => "A2", :points_possible => 10)

      def getpseudonym(user_sis_id)
        pseudo = Pseudonym.where(sis_user_id: user_sis_id).first
        expect(pseudo).not_to be_nil
        pseudo
      end

      def getuser(user_sis_id)
        user = getpseudonym(user_sis_id).user
        expect(user).not_to be_nil
        user
      end

      def getsection(section_sis_id)
        section = CourseSection.where(sis_source_id: section_sis_id).first
        expect(section).not_to be_nil
        section
      end

      def getenroll(user_sis_id, section_sis_id)
        e = Enrollment.where(user_id: getuser(user_sis_id), course_section_id: getsection(section_sis_id)).first
        expect(e).not_to be_nil
        e
      end

      a1.grade_student(getuser("S1"), { :grade => "6", :grader => getuser("T1") })
      a1.grade_student(getuser("S2"), { :grade => "6", :grader => getuser("T1") })
      a1.grade_student(getuser("S3"), { :grade => "7", :grader => getuser("T1") })
      a1.grade_student(getuser("S5"), { :grade => "7", :grader => getuser("T1") })
      a1.grade_student(getuser("S6"), { :grade => "8", :grader => getuser("T1") })
      a2.grade_student(getuser("S1"), { :grade => "8", :grader => getuser("T1") })
      a2.grade_student(getuser("S2"), { :grade => "9", :grader => getuser("T1") })
      a2.grade_student(getuser("S3"), { :grade => "9", :grader => getuser("T1") })
      a2.grade_student(getuser("S5"), { :grade => "10", :grader => getuser("T1") })
      a2.grade_student(getuser("S6"), { :grade => "10", :grader => getuser("T1") })

      stud5, stud6, sec4 = nil, nil, nil
      Pseudonym.where(sis_user_id: "S5").first.tap do |p|
        stud5 = p
        p.sis_user_id = nil
        p.save
      end

      Pseudonym.where(sis_user_id: "S6").first.tap do |p|
        stud6 = p
        p.sis_user_id = nil
        p.save
      end

      getsection("S4").tap do |s|
        sec4 = s
        sec4id = s.sis_source_id
        s.save
      end

      GradeCalculator.recompute_final_score(["S1", "S2", "S3", "S4"].map{|x|getuser(x).id}, @course.id)
      @course.reload

      teacher = Pseudonym.where(sis_user_id: "T1").first
      expect(teacher).not_to be_nil

      @plugin = Canvas::Plugin.find!('grade_export')
      @ps = PluginSetting.new(:name => @plugin.id, :settings => @plugin.default_settings)
      @ps.posted_settings = @plugin.default_settings.merge({
          :format_type => "instructure_csv",
          :wait_for_success => "no",
          :publish_endpoint => "http://localhost/endpoint"
        })
      @ps.save!

      csv =
          "publisher_id,publisher_sis_id,course_id,course_sis_id,section_id,section_sis_id,student_id," +
          "student_sis_id,enrollment_id,enrollment_status,score\n" +
          "#{teacher.user.id},T1,#{@course.id},C1,#{getsection("S1").id},S1,#{getpseudonym("S1").user.id},S1,#{getenroll("S1", "S1").id},active,70\n" +
          "#{teacher.user.id},T1,#{@course.id},C1,#{getsection("S2").id},S2,#{getpseudonym("S2").user.id},S2,#{getenroll("S2", "S2").id},active,75\n" +
          "#{teacher.user.id},T1,#{@course.id},C1,#{getsection("S2").id},S2,#{getpseudonym("S3").user.id},S3,#{getenroll("S3", "S2").id},active,80\n" +
          "#{teacher.user.id},T1,#{@course.id},C1,#{getsection("S1").id},S1,#{getpseudonym("S4").user.id},S4,#{getenroll("S4", "S1").id},active,0\n" +
          "#{teacher.user.id},T1,#{@course.id},C1,#{getsection("S3").id},S3,#{stud5.user.id},,#{Enrollment.where(user_id: stud5.user, course_section_id: getsection("S3")).first.id},active,85\n" +
          "#{teacher.user.id},T1,#{@course.id},C1,#{sec4.id},S4,#{stud6.user.id},,#{Enrollment.where(user_id: stud6.user, course_section_id: sec4.id).first.id},active,90\n"
      SSLCommon.expects(:post_data).with("http://localhost/endpoint", csv, "text/csv", {})
      @course.publish_final_grades(teacher.user)

      @course.grading_standard_id = 0
      @course.save

      csv =
          "publisher_id,publisher_sis_id,course_id,course_sis_id,section_id,section_sis_id,student_id," +
          "student_sis_id,enrollment_id,enrollment_status,score,grade\n" +
          "#{teacher.user.id},T1,#{@course.id},C1,#{getsection("S1").id},S1,#{getpseudonym("S1").user.id},S1,#{getenroll("S1", "S1").id},active,70,C-\n" +
          "#{teacher.user.id},T1,#{@course.id},C1,#{getsection("S2").id},S2,#{getpseudonym("S2").user.id},S2,#{getenroll("S2", "S2").id},active,75,C\n" +
          "#{teacher.user.id},T1,#{@course.id},C1,#{getsection("S2").id},S2,#{getpseudonym("S3").user.id},S3,#{getenroll("S3", "S2").id},active,80,B-\n" +
          "#{teacher.user.id},T1,#{@course.id},C1,#{getsection("S1").id},S1,#{getpseudonym("S4").user.id},S4,#{getenroll("S4", "S1").id},active,0,F\n" +
          "#{teacher.user.id},T1,#{@course.id},C1,#{getsection("S3").id},S3,#{stud5.user.id},,#{Enrollment.where(user_id: stud5.user, course_section_id: getsection("S3")).first.id},active,85,B\n" +
          "#{teacher.user.id},T1,#{@course.id},C1,#{sec4.id},S4,#{stud6.user.id},,#{Enrollment.where(user_id: stud6.user, course_section_id: sec4.id).first.id},active,90,A-\n"
      SSLCommon.expects(:post_data).with("http://localhost/endpoint", csv, "text/csv", {})
      @course.publish_final_grades(teacher.user)

      admin = user_model

      csv =
          "publisher_id,publisher_sis_id,course_id,course_sis_id,section_id,section_sis_id,student_id," +
          "student_sis_id,enrollment_id,enrollment_status,score,grade\n" +
          "#{admin.id},,#{@course.id},C1,#{getsection("S1").id},S1,#{getpseudonym("S1").user.id},S1,#{getenroll("S1", "S1").id},active,70,C-\n" +
          "#{admin.id},,#{@course.id},C1,#{getsection("S2").id},S2,#{getpseudonym("S2").user.id},S2,#{getenroll("S2", "S2").id},active,75,C\n" +
          "#{admin.id},,#{@course.id},C1,#{getsection("S2").id},S2,#{getpseudonym("S3").user.id},S3,#{getenroll("S3", "S2").id},active,80,B-\n" +
          "#{admin.id},,#{@course.id},C1,#{getsection("S1").id},S1,#{getpseudonym("S4").user.id},S4,#{getenroll("S4", "S1").id},active,0,F\n" +
          "#{admin.id},,#{@course.id},C1,#{getsection("S3").id},S3,#{stud5.user.id},,#{Enrollment.where(user_id: stud5.user, course_section_id: getsection("S3")).first.id},active,85,B\n" +
          "#{admin.id},,#{@course.id},C1,#{sec4.id},S4,#{stud6.user.id},,#{Enrollment.where(user_id: stud6.user, course_section_id: sec4.id).first.id},active,90,A-\n"
      SSLCommon.expects(:post_data).with("http://localhost/endpoint", csv, "text/csv", {})
      @course.publish_final_grades(admin)
    end
  end

end

describe Course, 'tabs_available' do

  before :once do
    course_model
  end

  def new_external_tool(context)
    context.context_external_tools.new(:name => "bob", :consumer_key => "bob", :shared_secret => "bob", :domain => "example.com")
  end

  it "should not include external tools if not configured for course navigation" do
    tool = new_external_tool @course
    tool.user_navigation = {:url => "http://www.example.com", :text => "Example URL"}
    tool.save!
    expect(tool.has_placement?(:course_navigation)).to eq false
    @teacher = user_model
    @course.enroll_teacher(@teacher).accept
    tabs = @course.tabs_available(@teacher)
    expect(tabs.map{|t| t[:id] }).not_to be_include(tool.asset_string)
  end

  it "should include external tools if configured on the course" do
    tool = new_external_tool @course
    tool.course_navigation = {:url => "http://www.example.com", :text => "Example URL"}
    tool.save!
    expect(tool.has_placement?(:course_navigation)).to eq true
    @teacher = user_model
    @course.enroll_teacher(@teacher).accept
    tabs = @course.tabs_available(@teacher)
    expect(tabs.map{|t| t[:id] }).to be_include(tool.asset_string)
    tab = tabs.detect{|t| t[:id] == tool.asset_string }
    expect(tab[:label]).to eq tool.settings[:course_navigation][:text]
    expect(tab[:href]).to eq :course_external_tool_path
    expect(tab[:args]).to eq [@course.id, tool.id]
  end

  it "should include external tools if configured on the account" do
    @account = @course.root_account.sub_accounts.create!(:name => "sub-account")
    @course.move_to_account(@account.root_account, @account)
    tool = new_external_tool @account
    tool.course_navigation = {:url => "http://www.example.com", :text => "Example URL"}
    tool.save!
    expect(tool.has_placement?(:course_navigation)).to eq true
    @teacher = user_model
    @course.enroll_teacher(@teacher).accept
    tabs = @course.tabs_available(@teacher)
    expect(tabs.map{|t| t[:id] }).to be_include(tool.asset_string)
    tab = tabs.detect{|t| t[:id] == tool.asset_string }
    expect(tab[:label]).to eq tool.settings[:course_navigation][:text]
    expect(tab[:href]).to eq :course_external_tool_path
    expect(tab[:args]).to eq [@course.id, tool.id]
  end

  it "should include external tools if configured on the root account" do
    @account = @course.root_account.sub_accounts.create!(:name => "sub-account")
    @course.move_to_account(@account.root_account, @account)
    tool = new_external_tool @account.root_account
    tool.course_navigation = {:url => "http://www.example.com", :text => "Example URL"}
    tool.save!
    expect(tool.has_placement?(:course_navigation)).to eq true
    @teacher = user_model
    @course.enroll_teacher(@teacher).accept
    tabs = @course.tabs_available(@teacher)
    expect(tabs.map{|t| t[:id] }).to be_include(tool.asset_string)
    tab = tabs.detect{|t| t[:id] == tool.asset_string }
    expect(tab[:label]).to eq tool.settings[:course_navigation][:text]
    expect(tab[:href]).to eq :course_external_tool_path
    expect(tab[:args]).to eq [@course.id, tool.id]
  end

  it "should only include admin-only external tools for course admins" do
    @course.offer
    @course.is_public = true
    @course.save!
    tool = new_external_tool @course
    tool.course_navigation = {:url => "http://www.example.com", :text => "Example URL", :visibility => 'admins'}
    tool.save!
    expect(tool.has_placement?(:course_navigation)).to eq true
    @teacher = user_model
    @course.enroll_teacher(@teacher).accept
    @student = user_model
    @student.register!
    @course.enroll_student(@student).accept
    tabs = @course.tabs_available(nil)
    expect(tabs.map{|t| t[:id] }).not_to be_include(tool.asset_string)
    tabs = @course.tabs_available(@student)
    expect(tabs.map{|t| t[:id] }).not_to be_include(tool.asset_string)
    tabs = @course.tabs_available(@teacher)
    expect(tabs.map{|t| t[:id] }).to be_include(tool.asset_string)
    tab = tabs.detect{|t| t[:id] == tool.asset_string }
    expect(tab[:label]).to eq tool.settings[:course_navigation][:text]
    expect(tab[:href]).to eq :course_external_tool_path
    expect(tab[:args]).to eq [@course.id, tool.id]
  end

  it "should not include member-only external tools for unauthenticated users" do
    @course.offer
    @course.is_public = true
    @course.save!
    tool = new_external_tool @course
    tool.course_navigation = {:url => "http://www.example.com", :text => "Example URL", :visibility => 'members'}
    tool.save!
    expect(tool.has_placement?(:course_navigation)).to eq true
    @teacher = user_model
    @course.enroll_teacher(@teacher).accept
    @student = user_model
    @student.register!
    @course.enroll_student(@student).accept
    tabs = @course.tabs_available(nil)
    expect(tabs.map{|t| t[:id] }).not_to be_include(tool.asset_string)
    tabs = @course.tabs_available(@student)
    expect(tabs.map{|t| t[:id] }).to be_include(tool.asset_string)
    tabs = @course.tabs_available(@teacher)
    expect(tabs.map{|t| t[:id] }).to be_include(tool.asset_string)
    tab = tabs.detect{|t| t[:id] == tool.asset_string }
    expect(tab[:label]).to eq tool.settings[:course_navigation][:text]
    expect(tab[:href]).to eq :course_external_tool_path
    expect(tab[:args]).to eq [@course.id, tool.id]
  end

  it "should allow reordering external tool position in course navigation" do
    tool = new_external_tool @course
    tool.course_navigation = {:url => "http://www.example.com", :text => "Example URL"}
    tool.save!
    expect(tool.has_placement?(:course_navigation)).to eq true
    @teacher = user_model
    @course.enroll_teacher(@teacher).accept
    @course.tab_configuration = Course.default_tabs.map{|t| {:id => t[:id] } }.insert(1, {:id => tool.asset_string})
    @course.save!
    tabs = @course.tabs_available(@teacher)
    expect(tabs[1][:id]).to eq tool.asset_string
  end

  it "should not show external tools that are hidden in course navigation" do
    tool = new_external_tool @course
    tool.course_navigation = {:url => "http://www.example.com", :text => "Example URL"}
    tool.save!
    expect(tool.has_placement?(:course_navigation)).to eq true
    @teacher = user_model
    @course.enroll_teacher(@teacher).accept
    tabs = @course.tabs_available(@teacher)
    expect(tabs.map{|t| t[:id] }).to be_include(tool.asset_string)

    @course.tab_configuration = Course.default_tabs.map{|t| {:id => t[:id] } }.insert(1, {:id => tool.asset_string, :hidden => true})
    @course.save!
    @course = Course.find(@course.id)
    tabs = @course.tabs_available(@teacher)
    expect(tabs.map{|t| t[:id] }).not_to be_include(tool.asset_string)

    tabs = @course.tabs_available(@teacher, :for_reordering => true)
    expect(tabs.map{|t| t[:id] }).to be_include(tool.asset_string)
  end

  it "uses extension default values" do
    tool = new_external_tool @course
    tool.course_navigation = {}
    tool.settings[:url] = "http://www.example.com"
    tool.settings[:visibility] = "members"
    tool.settings[:default] = "disabled"
    tool.save!

    expect(tool.course_navigation(:url)).to eq "http://www.example.com"
    expect(tool.has_placement?(:course_navigation)).to eq true

    settings = @course.external_tool_tabs({}).first
    expect(settings).to include(:visibility=>"members")
    expect(settings).to include(:hidden=>true)
  end

  it "prefers extension settings over default values" do
    tool = new_external_tool @course
    tool.course_navigation = {:url => "http://www.example.com", :visibility => "admins", :default => "active" }
    tool.settings[:visibility] = "members"
    tool.settings[:default] = "disabled"
    tool.save!

    expect(tool.course_navigation(:url)).to eq "http://www.example.com"
    expect(tool.has_placement?(:course_navigation)).to eq true

    settings = @course.external_tool_tabs({}).first
    expect(settings).to include(:visibility=>"admins")
    expect(settings).to include(:hidden=>false)
  end

end

describe Course, 'scoping' do
  it 'should search by multiple fields' do
    c1 = Course.new
    c1.root_account = Account.create
    c1.name = "name1"
    c1.sis_source_id = "sisid1"
    c1.course_code = "code1"
    c1.save
    c2 = Course.new
    c2.root_account = Account.create
    c2.name = "name2"
    c2.course_code = "code2"
    c2.sis_source_id = "sisid2"
    c2.save
    expect(Course.name_like("name1").map(&:id)).to eq [c1.id]
    expect(Course.name_like("sisid2").map(&:id)).to eq [c2.id]
    expect(Course.name_like("code1").map(&:id)).to eq [c1.id]
  end
end

describe Course, "manageable_by_user" do
  it "should include courses associated with the user's active accounts" do
    account = Account.create!
    sub_account = Account.create!(:parent_account => account)
    sub_sub_account = Account.create!(:parent_account => sub_account)
    user = account_admin_user(:account => sub_account)
    course = Course.create!(:account => sub_sub_account)

    expect(Course.manageable_by_user(user.id).map{ |c| c.id }).to be_include(course.id)
  end

  it "should include courses the user is actively enrolled in as a teacher" do
    course = Course.create
    user = user_with_pseudonym
    course.enroll_teacher(user)
    e = course.teacher_enrollments.first
    e.accept

    expect(Course.manageable_by_user(user.id).map{ |c| c.id }).to be_include(course.id)
  end

  it "should include courses the user is actively enrolled in as a ta" do
    course = Course.create
    user = user_with_pseudonym
    course.enroll_ta(user)
    e = course.ta_enrollments.first
    e.accept

    expect(Course.manageable_by_user(user.id).map{ |c| c.id }).to be_include(course.id)
  end

  it "should include courses the user is actively enrolled in as a designer" do
    course = Course.create
    user = user_with_pseudonym
    course.enroll_designer(user).accept

    expect(Course.manageable_by_user(user.id).map{ |c| c.id }).to be_include(course.id)
  end

  it "should not include courses the user is enrolled in when the enrollment is non-active" do
    course = Course.create
    user = user_with_pseudonym
    course.enroll_teacher(user)
    e = course.teacher_enrollments.first

    # it's only invited at this point
    expect(Course.manageable_by_user(user.id)).to be_empty

    e.destroy
    expect(Course.manageable_by_user(user.id)).to be_empty
  end

  it "should not include deleted courses the user was enrolled in" do
    course = Course.create
    user = user_with_pseudonym
    course.enroll_teacher(user)
    e = course.teacher_enrollments.first
    e.accept

    course.destroy
    expect(Course.manageable_by_user(user.id)).to be_empty
  end
end

describe Course, "conclusions" do
  it "should grant concluded users read but not participate" do
    enrollment = course_with_student(:active_all => 1)
    @course.reload

    # active
    expect(@course.rights_status(@user, :read, :participate_as_student)).to eq({:read => true, :participate_as_student => true})
    @course.clear_permissions_cache(@user)

    # soft conclusion
    enrollment.start_at = 4.days.ago
    enrollment.end_at = 2.days.ago
    enrollment.save!
    @course.reload
    @user.reload
    @user.cached_current_enrollments

    expect(enrollment.reload.state).to eq :active
    expect(enrollment.state_based_on_date).to eq :completed
    expect(enrollment).not_to be_participating_student

    expect(@course.rights_status(@user, :read, :participate_as_student)).to eq({:read => true, :participate_as_student => false})
    @course.clear_permissions_cache(@user)

    # hard enrollment conclusion
    enrollment.start_at = enrollment.end_at = nil
    enrollment.workflow_state = 'completed'
    enrollment.save!
    @course.reload
    @user.reload
    @user.cached_current_enrollments
    expect(enrollment.state).to eq :completed
    expect(enrollment.state_based_on_date).to eq :completed

    expect(@course.rights_status(@user, :read, :participate_as_student)).to eq({:read => true, :participate_as_student => false})
    @course.clear_permissions_cache(@user)

    # course conclusion
    enrollment.workflow_state = 'active'
    enrollment.save!
    @course.reload
    @course.complete!
    @user.reload
    @user.cached_current_enrollments
    enrollment.reload
    expect(enrollment.state).to eq :completed
    expect(enrollment.state_based_on_date).to eq :completed

    expect(@course.rights_status(@user, :read, :participate_as_student)).to eq({:read => true, :participate_as_student => false})
  end

  context "appointment cancelation" do
    before :once do
      course_with_student(:active_all => true)
      @ag = AppointmentGroup.create!(:title => "test", :contexts => [@course], :new_appointments => [['2010-01-01 13:00:00', '2010-01-01 14:00:00'], ["#{Time.now.year + 1}-01-01 13:00:00", "#{Time.now.year + 1}-01-01 14:00:00"]])
      @ag.appointments.each do |a|
        a.reserve_for(@user, @user)
      end
    end

    it "should cancel all future appointments when concluding an enrollment" do
      @enrollment.conclude
      expect(@ag.appointments_participants.size).to eql 1
      expect(@ag.appointments_participants.current.size).to eql 0
    end

    it "should cancel all future appointments when concluding all enrollments" do
      @course.complete!
      expect(@ag.appointments_participants.size).to eql 1
      expect(@ag.appointments_participants.current.size).to eql 0
    end
  end
end

describe Course, "inherited_assessment_question_banks" do
  it "should include the course's banks if include_self is true" do
    @account = Account.create
    @course = Course.create(:account => @account)
    expect(@course.inherited_assessment_question_banks(true)).to be_empty

    bank = @course.assessment_question_banks.create
    expect(@course.inherited_assessment_question_banks(true)).to eq [bank]
  end

  it "should include all banks in the account hierarchy" do
    @root_account = Account.create
    root_bank = @root_account.assessment_question_banks.create

    @account = Account.new
    @account.root_account = @root_account
    @account.save
    account_bank = @account.assessment_question_banks.create

    @course = Course.create(:account => @account)
    expect(@course.inherited_assessment_question_banks.sort_by(&:id)).to eq [root_bank, account_bank]
  end

  it "should return a useful scope" do
    @root_account = Account.create
    root_bank = @root_account.assessment_question_banks.create

    @account = Account.new
    @account.root_account = @root_account
    @account.save
    account_bank = @account.assessment_question_banks.create

    @course = Course.create(:account => @account)
    bank = @course.assessment_question_banks.create

    banks = @course.inherited_assessment_question_banks(true)
    expect(banks.order(:id)).to eq [root_bank, account_bank, bank]
    expect(banks.where(id: bank).first).to eql bank
    expect(banks.where(id: account_bank).first).to eql account_bank
    expect(banks.where(id: root_bank).first).to eql root_bank
  end
end

describe Course, "section_visibility" do
  before :once do
    @course = course(:active_course => true)
    @course.default_section
    @other_section = @course.course_sections.create

    @teacher = User.create
    @course.enroll_teacher(@teacher)

    @ta = User.create
    @course.enroll_user(@ta, "TaEnrollment", :limit_privileges_to_course_section => true)

    @student1 = User.create
    @course.enroll_user(@student1, "StudentEnrollment", :enrollment_state => 'active')

    @student2 = User.create
    @course.enroll_user(@student2, "StudentEnrollment", :section => @other_section, :enrollment_state => 'active')

    @observer = User.create
    @course.enroll_user(@observer, "ObserverEnrollment").update_attribute(:associated_user_id, @student1.id)
  end

  it "should return a scope from sections_visible_to" do
    # can't use "should respond_to", because that delegates to the instantiated Array
    expect{ @course.sections_visible_to(@teacher).scoped }.not_to raise_exception
  end

  context "full" do
    it "should return students from all sections" do
      expect(@course.students_visible_to(@teacher).sort_by(&:id)).to eql [@student1, @student2]
      expect(@course.students_visible_to(@student1).sort_by(&:id)).to eql [@student1, @student2]
    end

    it "should return all sections if a teacher" do
      expect(@course.sections_visible_to(@teacher).sort_by(&:id)).to eql [@course.default_section, @other_section]
    end

    it "should return user's sections if a student" do
      expect(@course.sections_visible_to(@student1)).to eq [@course.default_section]
    end

    it "should return users from all sections" do
      expect(@course.users_visible_to(@teacher).sort_by(&:id)).to eql [@teacher, @ta, @student1, @student2, @observer]
      expect(@course.users_visible_to(@ta).sort_by(&:id)).to      eql [@teacher, @ta, @student1, @observer]
    end

    it "should return student view students to account admins" do
      @course.student_view_student
      @admin = account_admin_user
      expect(@course.enrollments_visible_to(@admin).map(&:user)).to be_include(@course.student_view_student)
    end

    it "should return student view students to student view students" do
      expect(@course.enrollments_visible_to(@course.student_view_student).map(&:user)).to be_include(@course.student_view_student)
    end
  end

  context "sections" do
    it "should return students from user's sections" do
      expect(@course.students_visible_to(@ta)).to eq [@student1]
    end

    it "should return user's sections" do
      expect(@course.sections_visible_to(@ta)).to eq [@course.default_section]
    end

    it "should return non-limited admins from other sections" do
      expect(@course.enrollments_visible_to(@ta, :type => :teacher, :return_users => true)).to eq [@teacher]
    end
  end

  context "restricted" do
    it "should return no students except self and the observed" do
      expect(@course.students_visible_to(@observer)).to eq [@student1]
      RoleOverride.create!(:context => @course.account, :permission => 'read_roster',
                           :role => student_role, :enabled => false)
      expect(@course.students_visible_to(@student1)).to eq [@student1]
    end

    it "should return student's sections" do
      expect(@course.sections_visible_to(@observer)).to eq [@course.default_section]
      RoleOverride.create!(:context => @course.account, :permission => 'read_roster',
                           :role => student_role, :enabled => false)
      expect(@course.sections_visible_to(@student1)).to eq [@course.default_section]
    end
  end

  context "require_message_permission" do
    it "should check the message permission" do
      expect(@course.enrollment_visibility_level_for(@teacher, @course.section_visibilities_for(@teacher), true)).to eql :full
      expect(@course.enrollment_visibility_level_for(@observer, @course.section_visibilities_for(@observer), true)).to eql :restricted
      RoleOverride.create!(:context => @course.account, :permission => 'send_messages',
                           :role => student_role, :enabled => false)
      expect(@course.enrollment_visibility_level_for(@student1, @course.section_visibilities_for(@student1), true)).to eql :restricted
    end
  end
end

describe Course, ".import_from_migration" do
  before :once do
    course_with_teacher
  end

  before :each do
    attachment_model(:uploaded_data => stub_file_data('test.m4v', 'asdf', 'video/mp4'))
  end

  it "should know when it has open course imports" do
    # no course imports
    expect(@course).not_to have_open_course_imports

    course2 = @course.account.courses.create!
    # created course import
    @course.course_imports.create!(source: course2, import_type: 'test')
    expect(@course).to have_open_course_imports

    # started course import
    @course.course_imports.first.update_attribute(:workflow_state, 'started')
    expect(@course).to have_open_course_imports

    # completed course import
    @course.course_imports.first.update_attribute(:workflow_state, 'completed')
    expect(@course).not_to have_open_course_imports

    # failed course import
    @course.course_imports.first.update_attribute(:workflow_state, 'failed')
    expect(@course).not_to have_open_course_imports
  end
end

describe Course, "enrollments" do
  it "should update enrollments' root_account_id when necessary" do
    a1 = Account.create!
    a2 = Account.create!

    course_with_student
    @course.root_account = a1
    @course.save!

    expect(@course.student_enrollments.map(&:root_account_id)).to eq [a1.id]
    expect(@course.course_sections.reload.map(&:root_account_id)).to eq [a1.id]

    @course.root_account = a2
    @course.save!
    expect(@course.student_enrollments(true).map(&:root_account_id)).to eq [a2.id]
    expect(@course.course_sections.reload.map(&:root_account_id)).to eq [a2.id]
  end
end

describe Course, "user_is_instructor?" do
  before :once do
    @course = Course.create
    user_with_pseudonym
  end

  it "should be true for teachers" do
    course = @course
    teacher = @user
    course.enroll_teacher(teacher).accept
    expect(course.user_is_instructor?(teacher)).to be_truthy
  end

  it "should be true for tas" do
    course = @course
    ta = @user
    course.enroll_ta(ta).accept
    expect(course.user_is_instructor?(ta)).to be_truthy
  end

  it "should be false for designers" do
    course = @course
    designer = @user
    course.enroll_designer(designer).accept
    expect(course.user_is_instructor?(designer)).to be_falsey
  end
end

describe Course, "user_has_been_instructor?" do
  it "should be true for teachers, past or present" do
    e = course_with_teacher(:active_all => true)
    expect(@course.user_has_been_instructor?(@teacher)).to be_truthy

    e.conclude
    expect(e.reload.workflow_state).to eq "completed"
    expect(@course.user_has_been_instructor?(@teacher)).to be_truthy

    @course.complete
    expect(@course.user_has_been_instructor?(@teacher)).to be_truthy
  end

  it "should be true for tas" do
    e = course_with_ta(:active_all => true)
    expect(@course.user_has_been_instructor?(@ta)).to be_truthy
  end
end

describe Course, "user_has_been_admin?" do
  it "should be true for teachers, past or present" do
    e = course_with_teacher(:active_all => true)
    expect(@course.user_has_been_admin?(@teacher)).to be_truthy

    e.conclude
    expect(e.reload.workflow_state).to eq "completed"
    expect(@course.user_has_been_admin?(@teacher)).to be_truthy

    @course.complete
    expect(@course.user_has_been_admin?(@teacher)).to be_truthy
  end

  it "should be true for tas" do
    e = course_with_ta(:active_all => true)
    expect(@course.user_has_been_admin?(@ta)).to be_truthy
  end

  it "should be true for designers" do
    e = course_with_designer(:active_all => true)
    expect(@course.user_has_been_admin?(@designer)).to be_truthy
  end
end

describe Course, "user_has_been_student?" do
  it "should be true for students, past or present" do
    e = course_with_student(:active_all => true)
    expect(@course.user_has_been_student?(@student)).to be_truthy

    e.conclude
    expect(e.reload.workflow_state).to eq "completed"
    expect(@course.user_has_been_student?(@student)).to be_truthy

    @course.complete
    expect(@course.user_has_been_student?(@student)).to be_truthy
  end
end

describe Course, "user_has_been_observer?" do
  it "should be false for teachers" do
    e = course_with_teacher(:active_all => true)
    expect(@course.user_has_been_observer?(@teacher)).to be_falsey
  end

  it "should be false for tas" do
    e = course_with_ta(:active_all => true)
    expect(@course.user_has_been_observer?(@ta)).to be_falsey
  end

  it "should be true for observers" do
    course_with_observer(:active_all => true)
    expect(@course.user_has_been_observer?(@observer)).to be_truthy
  end
end

describe Course, "student_view_student" do
  before :once do
    course_with_teacher(:active_all => true)
  end

  it "should create a default section when enrolling for student view student" do
    student_view_course = Course.create!
    expect(student_view_course.course_sections).to be_empty

    student_view_student = student_view_course.student_view_student

    expect(student_view_course.enrollments.map(&:user_id)).to be_include(student_view_student.id)
  end

  it "should not create a section if a section already exists" do
    student_view_course = Course.create!
    not_default_section = student_view_course.course_sections.create! name: 'not default section'
    expect(not_default_section).not_to be_default_section
    student_view_student = student_view_course.student_view_student
    expect(student_view_course.reload.course_sections.active.count).to eql 1
    expect(not_default_section.enrollments.map(&:user_id)).to be_include(student_view_student.id)
  end

  it "should create and return the student view student for a course" do
    expect { @course.student_view_student }.to change(User, :count).by(1)
  end

  it "should find and return the student view student on successive calls" do
    @course.student_view_student
    expect { @course.student_view_student }.to change(User, :count).by(0)
  end

  it "should create enrollments for each section" do
    @section2 = @course.course_sections.create!
    expect { @fake_student = @course.student_view_student }.to change(Enrollment, :count).by(2)
    expect(@fake_student.enrollments.all?{|e| e.fake_student?}).to be_truthy
  end

  it "should sync enrollments after being created" do
    @course.student_view_student
    @section2 = @course.course_sections.create!
    expect { @course.student_view_student }.to change(Enrollment, :count).by(1)
  end

  it "should create a pseudonym for the fake student" do
    expect { @fake_student = @course.student_view_student }.to change(Pseudonym, :count).by(1)
    expect(@fake_student.pseudonyms).not_to be_empty
  end

  it "should allow two different student view users for two different courses" do
    @course1 = @course
    @teacher1 = @teacher
    course_with_teacher(:active_all => true)
    @course2 = @course
    @teacher2 = @teacher

    @fake_student1 = @course1.student_view_student
    @fake_student2 = @course2.student_view_student

    expect(@fake_student1.id).not_to eql @fake_student2.id
    expect(@fake_student1.pseudonym.id).not_to eql @fake_student2.pseudonym.id
  end

  it "should give fake student active student permissions even if enrollment wouldn't otherwise be active" do
    @course.enrollment_term.update_attributes(:start_at => 2.days.from_now, :end_at => 4.days.from_now)
    @fake_student = @course.student_view_student
    expect(@course.grants_right?(@fake_student, nil, :read_forum)).to be_truthy
  end

  it "should not update the fake student's enrollment state to 'invited' in a concluded course" do
    @course.student_view_student
    @course.enrollment_term.update_attributes(:start_at => 4.days.ago, :end_at => 2.days.ago)
    @fake_student = @course.student_view_student
    expect(@fake_student.enrollments.where(course_id: @course).map(&:workflow_state)).to eql(['active'])
  end
end

describe Course do
  describe "user_list_search_mode_for" do
    it "should be open for anyone if open registration is turned on" do
      account = Account.default
      account.settings = { :open_registration => true }
      account.save!
      course
      expect(@course.user_list_search_mode_for(nil)).to eq :open
      expect(@course.user_list_search_mode_for(user)).to eq :open
    end

    it "should be preferred for account admins" do
      account = Account.default
      course
      expect(@course.user_list_search_mode_for(nil)).to eq :closed
      expect(@course.user_list_search_mode_for(user)).to eq :closed
      user
      account.account_users.create!(user: @user)
      expect(@course.user_list_search_mode_for(@user)).to eq :preferred
    end

    it "should be preferred if delegated authentication is configured" do
      account = Account.default
      account.settings = { :open_registration => true }
      account.account_authorization_configs.create!(:auth_type => 'cas')
      account.save!
      course
      expect(@course.user_list_search_mode_for(nil)).to eq :preferred
      expect(@course.user_list_search_mode_for(user)).to eq :preferred
    end
  end
end

describe Course do
  describe "self_enrollment" do
    let_once(:c1) do
      Account.default.allow_self_enrollment!
      course
    end
    it "should generate a unique code" do
      expect(c1.self_enrollment_code).to be_nil # normally only set when self_enrollment is enabled
      c1.update_attribute(:self_enrollment, true)
      expect(c1.self_enrollment_code).not_to be_nil
      expect(c1.self_enrollment_code).to match /\A[A-Z0-9]{6}\z/

      c2 = course()
      c2.update_attribute(:self_enrollment, true)
      expect(c2.self_enrollment_code).to match /\A[A-Z0-9]{6}\z/
      expect(c1.self_enrollment_code).not_to eq c2.self_enrollment_code
    end

    it "should generate a code on demand for existing self enrollment courses" do
      Course.where(:id => @course).update_all(:self_enrollment => true)
      c1.reload
      expect(c1.read_attribute(:self_enrollment_code)).to be_nil
      expect(c1.self_enrollment_code).not_to be_nil
      expect(c1.self_enrollment_code).to match /\A[A-Z0-9]{6}\z/
    end
  end

  describe "groups_visible_to" do
    before :once do
      @course = course_model
      @user = user_model
      @group = @course.groups.create!
    end

    it "should restrict to groups the user is in without course-wide permissions" do
      expect(@course.groups_visible_to(@user)).to be_empty
      @group.add_user(@user)
      expect(@course.groups_visible_to(@user)).to eq [@group]
    end

    it "should allow course-wide visibility regardless of membership given :manage_groups permission" do
      expect(@course.groups_visible_to(@user)).to be_empty
      @course.expects(:grants_any_right?).returns(true)
      expect(@course.groups_visible_to(@user)).to eq [@group]
    end

    it "should allow course-wide visibility regardless of membership given :view_group_pages permission" do
      expect(@course.groups_visible_to(@user)).to be_empty
      @course.expects(:grants_any_right?).returns(true)
      expect(@course.groups_visible_to(@user)).to eq [@group]
    end

    it "should default to active groups only" do
      @course.expects(:grants_any_right?).returns(true).at_least_once
      expect(@course.groups_visible_to(@user)).to eq [@group]
      @group.destroy
      expect(@course.reload.groups_visible_to(@user)).to be_empty
    end

    it "should allow overriding the scope" do
      @course.expects(:grants_any_right?).returns(true).at_least_once
      @group.destroy
      expect(@course.groups_visible_to(@user)).to be_empty
      expect(@course.groups_visible_to(@user, @course.groups)).to eq [@group]
    end

    it "should return a scope" do
      # can't use "should respond_to", because that delegates to the instantiated Array
      expect{ @course.groups_visible_to(@user).scoped }.not_to raise_exception
    end
  end

  describe 'permission policies' do
    before :once do
      @course = course_model
    end

    before :each do
      @course.write_attribute(:workflow_state, 'available')
      @course.write_attribute(:is_public, true)
    end

    it 'can be read by a nil user if public and available' do
      expect(@course.check_policy(nil)).to eq [:read, :read_outcomes, :read_syllabus]
    end

    it 'cannot be read by a nil user if public but not available' do
      @course.write_attribute(:workflow_state, 'created')
      expect(@course.check_policy(nil)).to eq []
    end

    describe 'when course is not public' do
      before do
        @course.write_attribute(:is_public, false)
      end

      let_once(:user) { user_model }


      it 'cannot be read by a nil user' do
        expect(@course.check_policy(nil)).to eq []
      end

      it 'cannot be read by an unaffiliated user' do
        expect(@course.check_policy(user)).to eq []
      end

      it 'can be read by a prior user' do
        user.student_enrollments.create!(:workflow_state => 'completed', :course => @course)
        expect(@course.check_policy(user).sort).to eq [:read, :read_forum, :read_grades, :read_outcomes]
      end

      it 'can have its forum read by an observer' do
        enrollment = user.observer_enrollments.create!(:workflow_state => 'completed', :course => @course)
        enrollment.update_attribute(:associated_user_id, user.id)
        expect(@course.check_policy(user)).to include :read_forum
      end

      describe 'an instructor policy' do

        let(:instructor) do
          user.teacher_enrollments.create!(:workflow_state => 'completed', :course => @course)
          user
        end

        subject{ @course.check_policy(instructor) }

        it{ is_expected.to include :read_prior_roster }
        it{ is_expected.to include :view_all_grades }
        it{ is_expected.to include :delete }
      end

    end
  end

  context "sharding" do
    specs_require_sharding

    it "should properly return site admin permissions from another shard" do
      enable_cache do
        @shard1.activate do
          acct = Account.create!
          course_with_student(:active_all => 1, :account => acct)
        end
        @site_admin = user
        site_admin = Account.site_admin
        site_admin.account_users.create!(user: @user)

        @shard1.activate do
          expect(@course.grants_right?(@site_admin, :manage_content)).to be_truthy
          expect(@course.grants_right?(@teacher, :manage_content)).to be_truthy
          expect(@course.grants_right?(@student, :manage_content)).to be_falsey
        end

        expect(@course.grants_right?(@site_admin, :manage_content)).to be_truthy
      end

      enable_cache do
        # do it in a different order
        @shard1.activate do
          expect(@course.grants_right?(@student, :manage_content)).to be_falsey
          expect(@course.grants_right?(@teacher, :manage_content)).to be_truthy
          expect(@course.grants_right?(@site_admin, :manage_content)).to be_truthy
        end

        expect(@course.grants_right?(@site_admin, :manage_content)).to be_truthy
      end
    end

    it "should grant enrollment-based permissions regardless of shard" do
      @shard1.activate do
        account = Account.create!
        course(:active_course => true, :account => account)
      end

      @shard2.activate do
        user(:active_user => true)
      end

      student_in_course(:user => @user, :active_all => true)

      @shard1.activate do
        expect(@course.grants_right?(@user, :send_messages)).to be_truthy
      end

      @shard2.activate do
        expect(@course.grants_right?(@user, :send_messages)).to be_truthy
      end
    end
  end

  context "named scopes" do
    context "enrollments" do
      before :once do
        account_model
        # has enrollments
        @course1a = course_with_student(:account => @account, :course_name => 'A').course
        @course1b = course_with_student(:account => @account, :course_name => 'B').course

        # has no enrollments
        @course2a = Course.create!(:account => @account, :name => 'A')
        @course2b = Course.create!(:account => @account, :name => 'B')
      end

      describe "#with_enrollments" do
        it "should include courses with enrollments" do
          expect(@account.courses.with_enrollments.sort_by(&:id)).to eq [@course1a, @course1b]
        end

        it "should play nice with other scopes" do
          expect(@account.courses.with_enrollments.where(:name => 'A')).to eq [@course1a]
        end

        it "should be disjoint with #without_enrollments" do
          expect(@account.courses.with_enrollments.without_enrollments).to be_empty
        end
      end

      describe "#without_enrollments" do
        it "should include courses without enrollments" do
          expect(@account.courses.without_enrollments.sort_by(&:id)).to eq [@course2a, @course2b]
        end

        it "should play nice with other scopes" do
          expect(@account.courses.without_enrollments.where(:name => 'A')).to eq [@course2a]
        end
      end
    end

    context "completion" do
      before :once do
        account_model
        # non-concluded
        @c1 = Course.create!(:account => @account)
        @c2 = Course.create!(:account => @account, :conclude_at => 1.week.from_now)

        # concluded in various ways
        @c3 = Course.create!(:account => @account, :conclude_at => 1.week.ago)
        @c4 = Course.create!(:account => @account)
        term = @c4.account.enrollment_terms.create! :end_at => 2.weeks.ago
        @c4.enrollment_term = term
        @c4.save!
        @c5 = Course.create!(:account => @account)
        @c5.complete!
      end

      describe "#completed" do
        it "should include completed courses" do
          expect(@account.courses.completed.sort_by(&:id)).to eq [@c3, @c4, @c5]
        end

        it "should play nice with other scopes" do
          expect(@account.courses.completed.where(:conclude_at => nil)).to eq [@c4]
        end

        it "should be disjoint with #not_completed" do
          expect(@account.courses.completed.not_completed).to be_empty
        end
      end

      describe "#not_completed" do
        it "should include non-completed courses" do
          expect(@account.courses.not_completed.sort_by(&:id)).to eq [@c1, @c2]
        end

        it "should play nice with other scopes" do
          expect(@account.courses.not_completed.where(:conclude_at => nil)).to eq [@c1]
        end
      end
    end

    describe "#by_teachers" do
      before :once do
        account_model
        @course1a = course_with_teacher(:account => @account, :name => "teacher A's first course").course
        @teacherA = @teacher
        @course1b = course_with_teacher(:account => @account, :name => "teacher A's second course", :user => @teacherA).course
        @course2 = course_with_teacher(:account => @account, :name => "teacher B's course").course
        @teacherB = @teacher
        @course3 = course_with_teacher(:account => @account, :name => "teacher C's course").course
        @teacherC = @teacher
      end

      it "should filter courses by teacher" do
        expect(@account.courses.by_teachers([@teacherA.id]).sort_by(&:id)).to eq [@course1a, @course1b]
      end

      it "should support multiple teachers" do
        expect(@account.courses.by_teachers([@teacherB.id, @teacherC.id]).sort_by(&:id)).to eq [@course2, @course3]
      end

      it "should work with an empty array" do
        expect(@account.courses.by_teachers([])).to be_empty
      end

      it "should not follow student enrollments" do
        @course3.enroll_student(user_model)
        expect(@account.courses.by_teachers([@user.id])).to be_empty
      end

      it "should not follow deleted enrollments" do
        @teacherC.enrollments.each { |e| e.destroy }
        expect(@account.courses.by_teachers([@teacherB.id, @teacherC.id]).sort_by(&:id)).to eq [@course2]
      end

      it "should return no results when the user is not enrolled in the course" do
        user_model
        expect(@account.courses.by_teachers([@user.id])).to be_empty
      end

      it "should play nice with other scopes" do
        @course1a.complete!
        expect(@account.courses.by_teachers([@teacherA.id]).completed).to eq [@course1a]
      end
    end

    describe "#by_associated_accounts" do
      before :once do
        @root_account = account_model
        @sub = account_model(:name => 'sub', :parent_account => @root_account, :root_account => @root_account)
        @subA = account_model(:name => 'subA', :parent_account => @sub1, :root_account => @root_account)
        @courseA1 = course_model(:account => @subA, :name => 'A1')
        @courseA2 = course_model(:account => @subA, :name => 'A2')
        @subB = account_model(:name => 'subB', :parent_account => @sub1, :root_account => @root_account)
        @courseB = course_model(:account => @subB, :name => 'B')
        @other_root_account = account_model(:name => 'other')
        @courseC = course_model(:account => @other_root_account)
      end

      it "should filter courses by root account" do
        expect(Course.by_associated_accounts([@root_account.id]).sort_by(&:id)).to eq [@courseA1, @courseA2, @courseB]
      end

      it "should filter courses by subaccount" do
        expect(Course.by_associated_accounts([@subA.id]).sort_by(&:id)).to eq [@courseA1, @courseA2]
      end

      it "should return no results if already scoped to an unrelated account" do
        expect(@other_root_account.courses.by_associated_accounts([@root_account.id])).to be_empty
      end

      it "should accept multiple account IDs" do
        expect(Course.by_associated_accounts([@subB.id, @other_root_account.id]).sort_by(&:id)).to eq [@courseB, @courseC]
      end

      it "should play nice with other scopes" do
        @courseA1.complete!
        expect(Course.by_associated_accounts([@subA.id]).not_completed).to eq [@courseA2]
      end
    end
  end

  describe '#includes_student' do
    let_once(:course) { course_model }

    it 'returns true when the provided user is a student' do
      student = user_model
      student.student_enrollments.create!(:course => course)
      expect(course.includes_student?(student)).to be_truthy
    end

    it 'returns false when the provided user is not a student' do
      expect(course.includes_student?(User.create!)).to be_falsey
    end

    it 'returns false when the user is not yet even in the database' do
      expect(course.includes_student?(User.new)).to be_falsey
    end

    it 'returns false when the provided user is nil' do
      expect(course.includes_student?(nil)).to be_falsey
    end
  end
end

describe Course do
  context "re-enrollments" do
    it "should update concluded enrollment on re-enrollment" do
      @course = course(:active_all => true)

      @user1 = user_model
      @user1.sortable_name = 'jonny'
      @user1.save
      @course.enroll_user(@user1)

      enrollment_count = @course.enrollments.count

      @course.complete
      @course.unconclude

      @course.enroll_user(@user1)

      expect(@course.enrollments.count).to eq enrollment_count
    end

    it 'should allow deleted enrollments to be resurrected as active' do
      course_with_student({ :active_enrollment => true })
      @enrollment.destroy
      @enrollment = @course.enroll_user(@user, 'StudentEnrollment', { :enrollment_state => 'active' })
      expect(@enrollment.workflow_state).to eql 'active'
    end

    context 'SIS re-enrollments' do
      before :once do
        course_with_student({ :active_enrollment => true })
        batch = Account.default.sis_batches.create!
        # Both of these need to be defined, as they're both involved in SIS imports
        # and expected manual enrollment behavior
        @enrollment.sis_batch_id = batch.id
        @enrollment.sis_source_id = 'abc:1234'
        @enrollment.save
      end

      it 'should retain SIS attributes if re-enrolled, but the SIS enrollment is still active' do
        e2 = @course.enroll_student @user
        expect(e2.sis_batch_id).not_to eql nil
        expect(e2.sis_source_id).not_to eql nil
      end

      it 'should remove SIS attributes from enrollments when re-created manually' do
        @enrollment.destroy
        @enrollment = @course.enroll_student @user
        expect(@enrollment.sis_batch_id).to eql nil
        expect(@enrollment.sis_source_id).to eql nil
      end
    end

    context "unique enrollments" do
      before :once do
        course(active_all: true)
        user
        @section2 = @course.course_sections.create!
        @course.enroll_user(@user, 'StudentEnrollment', section: @course.default_section).reject!
        @course.enroll_user(@user, 'StudentEnrollment', section: @section2, allow_multiple_enrollments: true).reject!
      end

      it "should not cause problems moving a user between sections (s1)" do
        expect(@user.enrollments.count).to eq 2
        # this should not cause a unique constraint violation
        @course.enroll_user(@user, 'StudentEnrollment', section: @course.default_section)
      end

      it "should not cause problems moving a user between sections (s2)" do
        expect(@user.enrollments.count).to eq 2
        # this should not cause a unique constraint violation
        @course.enroll_user(@user, 'StudentEnrollment', section: @section2)
      end
    end

    describe "already_enrolled" do
      before :once do
        course
        user
      end

      it "should not be set for a new enrollment" do
        expect(@course.enroll_user(@user).already_enrolled).not_to be_truthy
      end

      it "should be set for an updated enrollment" do
        @course.enroll_user(@user)
        expect(@course.enroll_user(@user).already_enrolled).to be_truthy
      end
    end

    context "custom roles" do
      before :once do
        @account = Account.default
        course
        user
        @lazy_role = custom_student_role('LazyStudent')
        @honor_role = custom_student_role('HonorStudent') # ba-dum-tssh
      end

      it "should re-use an enrollment with the same role" do
        enrollment1 = @course.enroll_user(@user, 'StudentEnrollment', :role => @honor_role)
        enrollment2 = @course.enroll_user(@user, 'StudentEnrollment', :role => @honor_role)
        expect(@user.enrollments.count).to eql 1
        expect(enrollment1).to eql enrollment2
      end

      it "should not re-use an enrollment with a different role" do
        enrollment1 = @course.enroll_user(@user, 'StudentEnrollment', :role => @lazy_role)
        enrollment2 = @course.enroll_user(@user, 'StudentEnrollment', :role => @honor_role)
        expect(@user.enrollments.count).to eql 2
        expect(enrollment1).to_not eql enrollment2
      end

      it "should not re-use an enrollment with no role when enrolling with a role" do
        enrollment1 = @course.enroll_user(@user, 'StudentEnrollment')
        enrollment2 = @course.enroll_user(@user, 'StudentEnrollment', :role => @honor_role)
        expect(@user.enrollments.count).to eql 2
        expect(enrollment1).to_not eql enrollment2
      end

      it "should not re-use an enrollment with a role when enrolling with no role" do
        enrollment1 = @course.enroll_user(@user, 'StudentEnrollment', :role => @lazy_role)
        enrollment2 = @course.enroll_user(@user, 'StudentEnrollment')
        expect(@user.enrollments.count).to eql 2
        expect(enrollment1).not_to eql enrollment2
      end
    end
  end

  describe "short_name_slug" do
    before :once do
      @course = course(:active_all => true)
    end

    it "should hard truncate at 30 characters" do
      @course.short_name = "a" * 31
      expect(@course.short_name.length).to eq 31
      expect(@course.short_name_slug.length).to eq 30
      expect(@course.short_name).to match /^#{@course.short_name_slug}/
    end

    it "should not change the short_name" do
      short_name = "a" * 31
      @course.short_name = short_name
      expect(@course.short_name_slug).not_to eq @course.short_name
      expect(@course.short_name).to eq short_name
    end

    it "should leave short short_names alone" do
      @course.short_name = 'short short_name'
      expect(@course.short_name_slug).to eq @course.short_name
    end
  end

  describe "re_send_invitations!" do
    it "should send invitations" do
      course(:active_all => true)
      user1 = user_with_pseudonym(:active_all => true)
      user2 = user_with_pseudonym(:active_all => true)
      @course.enroll_student(user1)
      @course.enroll_student(user2).accept!

      dm_count = DelayedMessage.count
      expect(DelayedMessage.where(:communication_channel_id => user1.communication_channels.first).count).to eq 0
      Notification.create!(:name => 'Enrollment Invitation')
      @course.re_send_invitations!

      expect(DelayedMessage.count).to eq dm_count + 1
      expect(DelayedMessage.where(:communication_channel_id => user1.communication_channels.first).count).to eq 1
    end
  end

  it "creates a scope the returns deleted courses" do
    @course1 = Course.create!
    @course1.workflow_state = 'deleted'
    @course1.save!
    @course2 = Course.create!

    expect(Course.deleted.count).to eq 1
  end

  describe "visibility_limited_to_course_sections?" do
    before :once do
      course
      @limited = { :limit_privileges_to_course_section => true }
      @full = { :limit_privileges_to_course_section => false }
    end

    it "should be true if all visibilities are limited" do
      expect(@course.visibility_limited_to_course_sections?(nil, [@limited, @limited])).to be_truthy
    end

    it "should be false if only some visibilities are limited" do
      expect(@course.visibility_limited_to_course_sections?(nil, [@limited, @full])).to be_falsey
    end

    it "should be false if no visibilities are limited" do
      expect(@course.visibility_limited_to_course_sections?(nil, [@full, @full])).to be_falsey
    end

    it "should be true if no visibilities are given" do
      expect(@course.visibility_limited_to_course_sections?(nil, [])).to be_truthy
    end
  end

  context '#unpublishable?' do
    it "should not be unpublishable if there are active graded submissions" do
      course_with_teacher(:active_all => true)
      @student = student_in_course(:active_user => true).user
      expect(@course.unpublishable?).to be_truthy
      @assignment = @course.assignments.new(:title => "some assignment")
      @assignment.submission_types = "online_text_entry"
      @assignment.workflow_state = "published"
      @assignment.save
      @submission = @assignment.submit_homework(@student, :body => 'some message')
      expect(@course.unpublishable?).to be_truthy
      @assignment.grade_student(@student, {:grader => @teacher, :grade => 1})
      expect(@course.unpublishable?).to be_falsey
      @assignment.destroy
      expect(@course.unpublishable?).to be_truthy
    end
  end
end

describe Course, "multiple_sections?" do
  before :once do
    course_with_teacher(:active_all => true)
  end

  it "should return false for a class with one section" do
    expect(@course.multiple_sections?).to be_falsey
  end

  it "should return true for a class with more than one active section" do
    @course.course_sections.create!
    expect(@course.multiple_sections?).to be_truthy
  end
end

describe Course, "default_section" do
  it "should create the default section" do
    c = Course.create!
    s = c.default_section
    expect(c.course_sections.pluck(:id)).to eql [s.id]
  end

  it "unless we ask it not to" do
    c = Course.create!
    s = c.default_section(no_create: true)
    expect(s).to be_nil
    expect(c.course_sections.pluck(:id)).to be_empty
  end
end
