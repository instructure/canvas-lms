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

require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper.rb')

describe "MessageableUser::Calculator" do
  before do
    @user = user
    @calculator = MessageableUser::Calculator.new(@user)
  end

  describe "uncached crunchers" do
    describe "#uncached_visible_section_ids" do
      before do
        course_with_student(:user => @user, :active_all => true)
      end

      it "should not include sections from fully visible courses" do
        @calculator.uncached_visible_section_ids.should == {}
      end

      it "should include sections from section visibile courses" do
        Enrollment.limit_privileges_to_course_section!(@course, @user, true)
        @calculator.uncached_visible_section_ids.keys.should include(@course.id)
      end

      it "should not include sections from restricted visibility courses" do
        RoleOverride.manage_role_override(Account.default, 'StudentEnrollment', 'send_messages', :override => false)
        @calculator.uncached_visible_section_ids.should == {}
      end
    end

    describe "#uncached_visible_section_ids_in_course" do
      before do
        course_with_student(:user => @user, :active_all => true)
        @section = @course.course_sections.create!
      end

      it "should include sections the user is enrolled in" do
        @calculator.uncached_visible_section_ids_in_course(@course).should include(@course.default_section.id)
      end

      it "should not include sections the user is not enrolled in" do
        @calculator.uncached_visible_section_ids_in_course(@course).should_not include(@section.id)
      end

      it "should not include sections from deleted enrollments" do
        multiple_student_enrollment(@user, @section).destroy
        @calculator.uncached_visible_section_ids_in_course(@course).should_not include(@section.id)
      end
    end

    describe "#uncached_observed_student_ids" do
      before do
        @observer_enrollment = course_with_observer(:user => @user, :active_all => true)
        @observer_enrollment.associated_user = student_in_course(:active_all => true).user
        @observer_enrollment.save!
        RoleOverride.manage_role_override(Account.default, 'ObserverEnrollment', 'send_messages', :override => true)
      end

      it "should return an empty hash when no courses" do
        @course.destroy
        @calculator.uncached_observed_student_ids.should == {}
      end

      it "should not include observed students from fully visible courses" do
        @calculator.uncached_observed_student_ids.should == {}
      end

      it "should not include observed students from section visibile courses" do
        Enrollment.limit_privileges_to_course_section!(@course, @user, true)
        @calculator.uncached_observed_student_ids.should == {}
      end

      it "should include observed students from restricted visibility courses" do
        RoleOverride.manage_role_override(Account.default, 'ObserverEnrollment', 'send_messages', :override => false)
        @calculator.uncached_observed_student_ids.keys.should include(@course.id)
        @calculator.uncached_observed_student_ids[@course.id].should include(@student.id)
      end
    end

    describe "#uncached_observed_student_ids_in_course" do
      before do
        @observer_enrollment = course_with_observer(:user => @user, :active_all => true)
        @observer_enrollment.associated_user = student_in_course(:active_all => true).user
        @observer_enrollment.save!
      end

      it "should include students the user observes" do
        @calculator.uncached_observed_student_ids_in_course(@course).should include(@student.id)
      end

      it "should not include students the user is not observing" do
        student_in_course(:active_all => true)
        @calculator.uncached_observed_student_ids_in_course(@course).should_not include(@student.id)
      end
    end

    describe "#uncached_linked_observer_ids" do
      before do
        course_with_student(:user => @user, :active_all => true)
      end

      it "should return users observing the student" do
        enrollment = course_with_observer(:course => @course, :active_all => true)
        enrollment.associated_user = @student
        enrollment.save!
        @calculator.uncached_linked_observer_ids.should include(@observer.global_id)
      end

      it "should not return users observing other students" do
        student_in_course(:course => @course, :active_all => true)
        enrollment = course_with_observer(:course => @course, :active_all => true)
        enrollment.associated_user = @student # the new student for this spec
        enrollment.save!
        @calculator.uncached_linked_observer_ids.should_not include(@observer.global_id)
      end
    end

    describe "#uncached_visible_account_ids" do
      it "should return the user's accounts for which the user can read_roster" do
        account_admin_user(:user => @user, :account => Account.default)
        @calculator.uncached_visible_account_ids.should include(Account.default.id)
      end

      it "should not return accounts the user is not in" do
        # contrived, but have read_roster permission, but no association
        account = Account.create!
        account_admin_user(:user => @user, :account => account)
        @user.user_account_associations.delete_all
        @calculator.uncached_visible_account_ids.should_not include(account.id)
      end

      it "should not return accounts where the user cannot read_roster" do
        # just the pseudonym isn't enough to have an account user that would
        # grant the right
        @calculator.uncached_visible_account_ids.should_not include(Account.default.id)
      end
    end

    describe "#uncached_fully_visible_group_ids" do
      before do
        course_with_student(:user => @user, :active_all => true)
        group(:group_context => @course)
      end

      it "should include groups the user is in" do
        group_with_user(:user => @user)
        @calculator.uncached_fully_visible_group_ids.should include(@group.id)
      end

      context "group in fully visible courses" do
        it "should include the group if the enrollment is active" do
          @calculator.uncached_fully_visible_group_ids.should include(@group.id)
        end

        context "concluded enrollment" do
          before do
            @enrollment.workflow_state == 'completed'
            @enrollment.save!
          end

          it "should include the group if the course is still active" do
            @calculator.uncached_fully_visible_group_ids.should include(@group.id)
          end

          it "should include the group if the course was recently concluded" do
            @course.conclude_at = 1.day.ago
            @course.save!
            @calculator.uncached_fully_visible_group_ids.should include(@group.id)
          end

          it "should not include the group if the course concluding was not recent" do
            @course.conclude_at = 45.days.ago
            @course.save!
            @calculator.uncached_fully_visible_group_ids.should_not include(@group.id)
          end

          it "should include the group regardless of course concluding if the user's in the group" do
            @group.add_user(@user)
            @calculator.uncached_fully_visible_group_ids.should include(@group.id)
          end
        end
      end

      context "group in section visible course" do
        before do
          Enrollment.limit_privileges_to_course_section!(@course, @user, true)
        end

        it "should not include the group" do
          @calculator.uncached_fully_visible_group_ids.should_not include(@group.id)
        end

        it "should include the group if the user's in it" do
          @group.add_user(@user)
          @calculator.uncached_fully_visible_group_ids.should include(@group.id)
        end
      end

      context "group in restricted visibilty course" do
        before do
          RoleOverride.manage_role_override(Account.default, 'StudentEnrollment', 'send_messages', :override => false)
        end

        it "should not include the group" do
          @calculator.uncached_fully_visible_group_ids.should_not include(@group.id)
        end

        it "should include the group if the user's in it" do
          @group.add_user(@user)
          @calculator.uncached_fully_visible_group_ids.should include(@group.id)
        end
      end
    end

    describe "#uncached_section_visible_group_ids" do
      before do
        course_with_student(:user => @user, :active_all => true)
        group(:group_context => @course)
      end

      it "should not include groups not in a course, even with the user in it" do
        group_with_user(:user => @user)
        @calculator.uncached_section_visible_group_ids.should_not include(@group.id)
      end

      it "should not include groups in fully visible courses, even with the user in it" do
        @group.add_user(@user)
        @calculator.uncached_section_visible_group_ids.should_not include(@group.id)
      end

      context "group in section visible course" do
        before do
          Enrollment.limit_privileges_to_course_section!(@course, @user, true)
        end

        it "should include the group" do
          @calculator.uncached_section_visible_group_ids.should include(@group.id)
        end

        it "should not include the group if the user is in it" do
          @group.add_user(@user)
          @calculator.uncached_section_visible_group_ids.should_not include(@group.id)
        end
      end

      it "should not include groups in restricted visibility courses, even with the user in it" do
        RoleOverride.manage_role_override(Account.default, 'StudentEnrollment', 'send_messages', :override => false)
        @calculator.uncached_section_visible_group_ids.should_not include(@group.id)
      end
    end

    describe "#uncached_group_ids_in_courses" do
      it "should include active groups in the courses" do
        course1 = course
        course2 = course
        group1 = group(:group_context => course1)
        group2 = group(:group_context => course2)
        ids = @calculator.uncached_group_ids_in_courses([course1, course2])
        ids.should include(group1.id)
        ids.should include(group2.id)
      end

      it "should not include deleted groups in the courses" do
        course
        group(:group_context => @course).destroy
        @calculator.uncached_group_ids_in_courses([@course]).should_not include(@group.id)
      end

      it "should not include groups in other courses" do
        course1 = course
        course2 = course
        group(:group_context => course1)
        @calculator.uncached_group_ids_in_courses([course2]).should_not include(@group.id)
      end
    end
  end

  describe "shard_cached" do
    describe "sharding" do
      it_should_behave_like "sharding"

      it "should yield once for each of the user's associated shards" do
        @user.stubs(:associated_shards => [@shard1, @shard2])
        values = @calculator.shard_cached('cache_key') { Shard.current.id }
        values.keys.sort_by(&:id).should == [@shard1, @shard2].sort_by(&:id)
        values[@shard1].should == @shard1.id
        values[@shard2].should == @shard2.id
      end
    end

    describe "rails cache" do
      it "should share across calculators with same user" do
        expected = mock
        calc2 = MessageableUser::Calculator.new(@user)
        enable_cache do
          @calculator.shard_cached('cache_key') { expected }
          calc2.shard_cached('cache_key')[Shard.current].should == expected
        end
      end

      it "should distinguish users" do
        expected1 = mock
        expected2 = mock
        calc2 = MessageableUser::Calculator.new(user)

        enable_cache do
          @calculator.shard_cached('cache_key') { expected1 }
          calc2.shard_cached('cache_key') { expected2 }
          calc2.shard_cached('cache_key')[Shard.current].should == expected2
        end
      end

      it "should notice when a user changes" do
        expected1 = mock
        expected2 = mock
        calc2 = MessageableUser::Calculator.new(@user)

        enable_cache do
          @calculator.shard_cached('cache_key') { expected1 }
          @user.updated_at = 1.minute.from_now
          calc2.shard_cached('cache_key') { expected2 }
          calc2.shard_cached('cache_key')[Shard.current].should == expected2
        end
      end

      it "should be sensitive to the key" do
        expected1 = mock
        expected2 = mock

        enable_cache do
          @calculator.shard_cached('cache_key1') { expected1 }
          @calculator.shard_cached('cache_key2') { expected2 }
          @calculator.shard_cached('cache_key2')[Shard.current].should == expected2
        end
      end

      it "should be sensitive to the method results from additional parameters" do
        expected1 = stub(:cache_key => 'a')
        expected2 = stub(:cache_key => 'b')
        expected3 = stub(:cache_key => 'c')
        @calculator.stubs(:method1 => expected1)
        @calculator.stubs(:method2 => expected2)

        calc2 = MessageableUser::Calculator.new(@user)
        calc2.stubs(:method1 => expected1)
        calc2.stubs(:method2 => expected2)

        calc3 = MessageableUser::Calculator.new(@user)
        calc3.stubs(:method1 => expected1)
        calc3.stubs(:method2 => expected3)

        enable_cache do
          @calculator.shard_cached('cache_key', :method1, :method2) { expected1 }
          calc2.shard_cached('cache_key', :method1, :method2) { expected2 }
          calc3.shard_cached('cache_key', :method1, :method2) { expected3 }

          calc2.shard_cached('cache_key')[Shard.current].should == expected1
          calc3.shard_cached('cache_key')[Shard.current].should == expected3
        end
      end
    end

    describe "object-local cache" do
      it "should cache the result the key" do
        expected = mock
        @calculator.shard_cached('cache_key') { expected }
        @calculator.shard_cached('cache_key') { raise 'should not get here' }
        @calculator.shard_cached('cache_key')[Shard.current].should == expected
      end

      it "should distinguish different keys" do
        expected1 = mock
        expected2 = mock
        @calculator.shard_cached('cache_key1') { expected1 }
        @calculator.shard_cached('cache_key2') { expected2 }
        @calculator.shard_cached('cache_key1')[Shard.current].should == expected1
        @calculator.shard_cached('cache_key2')[Shard.current].should == expected2
      end
    end
  end

  describe "sharded and cached summaries" do
    it_should_behave_like "sharding"

    before do
      @account1 = @shard1.activate{ Account.create! }
      @account2 = @shard2.activate{ Account.create! }
      @course1 = course(:account => @account1, :active_all => 1)
      @course2 = course(:account => @account2, :active_all => 1)
      course_with_student(:course => @course1, :user => @user, :active_all => 1)
      course_with_student(:course => @course2, :user => @user, :active_all => 1)
    end

    it "should partition courses by shard in all_courses_by_shard" do
      @calculator.all_courses_by_shard.should == {
        @shard1 => [@course1],
        @shard2 => [@course2],
      }
    end

    describe "#visible_section_ids_by_shard" do
      before do
        Enrollment.limit_privileges_to_course_section!(@course1, @user, true)
        Enrollment.limit_privileges_to_course_section!(@course2, @user, true)
      end

      it "should have data local to the shard in the shard bin" do
        @calculator.visible_section_ids_by_shard[@shard1].should == {
          @course1.local_id => [@course1.default_section.local_id]
        }
      end

      it "should include sections from each shard" do
        @calculator.visible_section_ids_by_shard.should == {
          Shard.default => {},
          @shard1 => {@course1.local_id => [@course1.default_section.local_id]},
          @shard2 => {@course2.local_id => [@course2.default_section.local_id]}
        }
      end
    end

    describe "#observed_student_ids_by_shard" do
      before do
        RoleOverride.manage_role_override(@account1, 'ObserverEnrollment', 'send_messages', :override => false)
        RoleOverride.manage_role_override(@account2, 'ObserverEnrollment', 'send_messages', :override => false)
        @observer_enrollment1 = course_with_observer(:course => @course1, :active_all => true)
        @observer = @observer_enrollment1.user
        @observer_enrollment2 = course_with_observer(:course => @course2, :user => @observer, :active_all => true)
        @calculator = MessageableUser::Calculator.new(@observer)
      end

      it "should handle shard-local observer observing shard-local student" do
        @student = student_in_course(:course => @course1, :active_all => true).user
        @observer_enrollment1.associated_user = @student
        @observer_enrollment1.save!

        @calculator.observed_student_ids_by_shard[@shard1].should == {@course1.local_id => [@student.local_id]}
      end

      it "should handle shard-local observer observing cross-shard student" do
        @shard2.activate{ @student = user }
        student_in_course(:course => @course1, :user => @student, :active_all => true)
        @observer_enrollment1.associated_user = @student
        @observer_enrollment1.save!

        @calculator.observed_student_ids_by_shard[@shard1].should == {@course1.local_id => [@student.global_id]}
      end

      it "should handle cross-shard observer observing local-shard student" do
        @student = student_in_course(:course => @course2, :active_all => true).user
        @observer_enrollment2.associated_user = @student
        @observer_enrollment2.save!

        @calculator.observed_student_ids_by_shard[@shard2].should == {@course2.local_id => [@student.local_id]}
      end

      it "should handle cross-shard observer observing cross-shard student" do
        @shard1.activate{ @student = user }
        student_in_course(:course => @course2, :user => @student, :active_all => true)
        @observer_enrollment2.associated_user = @student
        @observer_enrollment2.save!

        @calculator.observed_student_ids_by_shard[@shard2].should == {@course2.local_id => [@student.global_id]}
      end
    end

    describe "#linked_observer_ids_by_shard" do
      before do
        me = @user
        @observer1 = @shard1.activate{ user }
        @observer2 = @shard2.activate{ user }

        @observer_enrollment1 = course_with_observer(:course => @course2, :user => @observer1, :active_all => true)
        @observer_enrollment1.associated_user = me
        @observer_enrollment1.save!

        @observer_enrollment2 = course_with_observer(:course => @course2, :user => @observer2, :active_all => true)
        @observer_enrollment2.associated_user = me
        @observer_enrollment2.save!
      end

      it "should not partition observers by shards" do
        @calculator.linked_observer_ids_by_shard[@shard1].should include(@observer1.local_id)
        @calculator.linked_observer_ids_by_shard[@shard1].should include(@observer2.global_id)
      end

      it "should transpose observers ids to shard" do
        @calculator.linked_observer_ids_by_shard[@shard2].should include(@observer1.global_id)
        @calculator.linked_observer_ids_by_shard[@shard2].should include(@observer2.local_id)
      end
    end

    it "should partition accounts by shard in visible_account_ids_by_shard" do
      account_admin_user(:user => @user, :account => @account1)
      account_admin_user(:user => @user, :account => @account2)
      @calculator.visible_account_ids_by_shard[@shard1].should == [@account1.local_id]
      @calculator.visible_account_ids_by_shard[@shard2].should == [@account2.local_id]
    end

    describe "fully_visible_group_ids_by_shard" do
      it "should partition groups by shard"
      it "should include fully visible groups"
      it "should not include section visible groups"
    end

    describe "section_visible_group_ids_by_shard" do
      it "should partition groups by shard"
      it "should include section visible groups"
      it "should not include fully visible groups"
    end
  end

  describe "public api" do
    describe "load_messageable_users" do
      it "should not break when given an otherwise unmessageable user and a non-nil but empty conversation_id" do
        other_user = User.create!
        lambda{ @calculator.load_messageable_users([other_user], :conversation_id => '') }.should_not raise_exception
      end

      it "should have more specs"
    end

    describe "messageable_users_in_context" do
      context "context is a course" do
        it "should have specs"
      end

      context "context is a section" do
        it "should have specs"
      end

      context "context is a group" do
        it "should have specs"
      end
    end
  end
end
