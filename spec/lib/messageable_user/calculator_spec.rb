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
    @viewing_user = user
    @calculator = MessageableUser::Calculator.new(@viewing_user)
  end

  describe "uncached crunchers" do
    describe "#uncached_visible_section_ids" do
      before do
        course_with_student(:user => @viewing_user, :active_all => true)
      end

      it "should not include sections from fully visible courses" do
        @calculator.uncached_visible_section_ids.should == {}
      end

      it "should include sections from section visibile courses" do
        Enrollment.limit_privileges_to_course_section!(@course, @viewing_user, true)
        @calculator.uncached_visible_section_ids.keys.should include(@course.id)
      end

      it "should not include sections from restricted visibility courses" do
        RoleOverride.manage_role_override(Account.default, 'StudentEnrollment', 'send_messages', :override => false)
        @calculator.uncached_visible_section_ids.should == {}
      end
    end

    describe "#uncached_visible_section_ids_in_course" do
      before do
        course_with_student(:user => @viewing_user, :active_all => true)
        @section = @course.course_sections.create!
      end

      it "should include sections the user is enrolled in" do
        @calculator.uncached_visible_section_ids_in_course(@course).should include(@course.default_section.id)
      end

      it "should not include sections the user is not enrolled in" do
        @calculator.uncached_visible_section_ids_in_course(@course).should_not include(@section.id)
      end

      it "should not include sections from deleted enrollments" do
        multiple_student_enrollment(@viewing_user, @section).destroy
        @calculator.uncached_visible_section_ids_in_course(@course).should_not include(@section.id)
      end
    end

    describe "#uncached_observed_student_ids" do
      before do
        @observer_enrollment = course_with_observer(:user => @viewing_user, :active_all => true)
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
        Enrollment.limit_privileges_to_course_section!(@course, @viewing_user, true)
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
        @observer_enrollment = course_with_observer(:user => @viewing_user, :active_all => true)
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
        course_with_student(:user => @viewing_user, :active_all => true)
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
        account_admin_user(:user => @viewing_user, :account => Account.default)
        @calculator.uncached_visible_account_ids.should include(Account.default.id)
      end

      it "should not return accounts the user is not in" do
        # contrived, but have read_roster permission, but no association
        account = Account.create!
        account_admin_user(:user => @viewing_user, :account => account)
        @viewing_user.user_account_associations.scoped.delete_all
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
        course_with_student(:user => @viewing_user, :active_all => true)
        group(:group_context => @course)
      end

      it "should include groups the user is in" do
        group_with_user(:user => @viewing_user)
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
            @group.add_user(@viewing_user)
            @calculator.uncached_fully_visible_group_ids.should include(@group.id)
          end
        end
      end

      context "group in section visible course" do
        before do
          Enrollment.limit_privileges_to_course_section!(@course, @viewing_user, true)
        end

        it "should not include the group" do
          @calculator.uncached_fully_visible_group_ids.should_not include(@group.id)
        end

        it "should include the group if the user's in it" do
          @group.add_user(@viewing_user)
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
          @group.add_user(@viewing_user)
          @calculator.uncached_fully_visible_group_ids.should include(@group.id)
        end
      end
    end

    describe "#uncached_section_visible_group_ids" do
      before do
        course_with_student(:user => @viewing_user, :active_all => true)
        group(:group_context => @course)
      end

      it "should not include groups not in a course, even with the user in it" do
        group_with_user(:user => @viewing_user)
        @calculator.uncached_section_visible_group_ids.should_not include(@group.id)
      end

      it "should not include groups in fully visible courses, even with the user in it" do
        @group.add_user(@viewing_user)
        @calculator.uncached_section_visible_group_ids.should_not include(@group.id)
      end

      context "group in section visible course" do
        before do
          Enrollment.limit_privileges_to_course_section!(@course, @viewing_user, true)
        end

        it "should include the group" do
          @calculator.uncached_section_visible_group_ids.should include(@group.id)
        end

        it "should not include the group if the user is in it" do
          @group.add_user(@viewing_user)
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

    describe "#uncached_messageable_sections" do
      before do
        course_with_teacher(:user => @viewing_user, :active_all => true)
      end

      it "should include all sections from fully visible courses with multiple sections" do
        other_section = @course.course_sections.create!
        @calculator.uncached_messageable_sections.should include(@course.default_section)
        @calculator.uncached_messageable_sections.should include(other_section)
      end

      it "should include only enrolled sections from section visible courses" do
        other_section1 = @course.course_sections.create!
        other_section2 = @course.course_sections.create!
        multiple_student_enrollment(@viewing_user, other_section1)
        Enrollment.limit_privileges_to_course_section!(@course, @viewing_user, true)
        @calculator.uncached_messageable_sections.should include(@course.default_section)
        @calculator.uncached_messageable_sections.should include(other_section1)
        @calculator.uncached_messageable_sections.should_not include(other_section2)
      end

      it "should not include sections from courses with only one sections" do
        @calculator.uncached_messageable_sections.should be_empty
      end
    end

    describe "#uncached_messageable_groups" do
      it "should include groups the user is in" do
        group_with_user(:user => @viewing_user)
        @calculator.uncached_messageable_groups.should include(@group)
      end

      it "should include groups in fully visible courses with messageable group members" do
        course_with_teacher(:user => @viewing_user, :active_all => true)
        group_with_user(:user => @viewing_user, :group_context => @course)
        @calculator.uncached_messageable_groups.should include(@group)
      end

      it "should include groups in section visible courses with messageable group members" do
        course_with_teacher(:user => @viewing_user, :active_all => true)
        group_with_user(:user => @viewing_user, :group_context => @course)
        Enrollment.limit_privileges_to_course_section!(@course, @viewing_user, true)
        @calculator.uncached_messageable_groups.should include(@group)
      end

      it "should not include empty groups in fully visible courses" do
        course_with_teacher(:user => @viewing_user, :active_all => true)
        group(:group_context => @course)
        @calculator.uncached_messageable_groups.should_not include(@group)
      end

      it "should not include empty groups in section visible courses" do
        course_with_teacher(:user => @viewing_user, :active_all => true)
        group(:group_context => @course)
        Enrollment.limit_privileges_to_course_section!(@course, @viewing_user, true)
        @calculator.uncached_messageable_groups.should_not include(@group)
      end

      it "should not include groups in section visible courses whose only members are non-messageable" do
        course_with_teacher(:user => @viewing_user, :active_all => true)
        student_in_course(:active_all => true, :section => @course.course_sections.create!)
        group_with_user(:user => @student, :group_context => @course)
        Enrollment.limit_privileges_to_course_section!(@course, @viewing_user, true)
        @calculator.uncached_messageable_groups.should_not include(@group)
      end
    end
  end

  describe "shard_cached" do
    describe "sharding" do
      specs_require_sharding

      it "should yield once for each of the user's associated shards" do
        @viewing_user.stubs(:associated_shards => [@shard1, @shard2])
        values = @calculator.shard_cached('cache_key') { Shard.current.id }
        values.keys.sort_by(&:id).should == [@shard1, @shard2].sort_by(&:id)
        values[@shard1].should == @shard1.id
        values[@shard2].should == @shard2.id
      end
    end

    describe "rails cache" do
      it "should share across calculators with same user" do
        expected = mock
        calc2 = MessageableUser::Calculator.new(@viewing_user)
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
        calc2 = MessageableUser::Calculator.new(@viewing_user)

        enable_cache do
          @calculator.shard_cached('cache_key') { expected1 }
          @viewing_user.updated_at = 1.minute.from_now
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

        calc2 = MessageableUser::Calculator.new(@viewing_user)
        calc2.stubs(:method1 => expected1)
        calc2.stubs(:method2 => expected2)

        calc3 = MessageableUser::Calculator.new(@viewing_user)
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
    specs_require_sharding

    before do
      @account1 = @shard1.activate{ Account.create! }
      @account2 = @shard2.activate{ Account.create! }
      @course1 = course(:account => @account1, :active_all => 1)
      @course2 = course(:account => @account2, :active_all => 1)
      course_with_student(:course => @course1, :user => @viewing_user, :active_all => 1)
      course_with_student(:course => @course2, :user => @viewing_user, :active_all => 1)
    end

    it "should partition courses by shard in all_courses_by_shard" do
      @calculator.all_courses_by_shard.should == {
        @shard1 => [@course1],
        @shard2 => [@course2],
      }
    end

    describe "#visible_section_ids_by_shard" do
      before do
        Enrollment.limit_privileges_to_course_section!(@course1, @viewing_user, true)
        Enrollment.limit_privileges_to_course_section!(@course2, @viewing_user, true)
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

    describe "#visible_section_ids_in_courses" do
      before do
        Enrollment.limit_privileges_to_course_section!(@course1, @viewing_user, true)
        Enrollment.limit_privileges_to_course_section!(@course2, @viewing_user, true)
      end

      it "should only include ids from the current shard" do
        @shard1.activate{ @calculator.visible_section_ids_in_courses([@course1, @course2]).should == [@course1.default_section.local_id] }
        @shard2.activate{ @calculator.visible_section_ids_in_courses([@course1, @course2]).should == [@course2.default_section.local_id] }
      end

      it "should not include ids from other courses" do
        @shard1.activate{ @calculator.visible_section_ids_in_courses([@course2]).should be_empty }
        @shard2.activate{ @calculator.visible_section_ids_in_courses([@course1]).should be_empty }
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

    describe "#observed_student_ids_in_courses" do
      before do
        RoleOverride.manage_role_override(@account1, 'ObserverEnrollment', 'send_messages', :override => false)
        RoleOverride.manage_role_override(@account2, 'ObserverEnrollment', 'send_messages', :override => false)

        @student1 = student_in_course(:course => @course1, :active_all => true).user
        @observer_enrollment1 = course_with_observer(:course => @course1, :active_all => true)
        @observer_enrollment1.associated_user = @student1
        @observer_enrollment1.save!

        @observer = @observer_enrollment1.user

        @student2 = student_in_course(:course => @course2, :active_all => true).user
        @observer_enrollment2 = course_with_observer(:course => @course2, :user => @observer, :active_all => true)
        @observer_enrollment2.associated_user = @student2
        @observer_enrollment2.save!

        @calculator = MessageableUser::Calculator.new(@observer)
      end

      it "should only include ids from the current shard" do
        @shard1.activate{ @calculator.observed_student_ids_in_courses([@course1, @course2]).should == [@student1.local_id] }
        @shard2.activate{ @calculator.observed_student_ids_in_courses([@course1, @course2]).should == [@student2.local_id] }
      end

      it "should not include ids from other courses" do
        @shard1.activate{ @calculator.observed_student_ids_in_courses([@course2]).should be_empty }
        @shard2.activate{ @calculator.observed_student_ids_in_courses([@course1]).should be_empty }
      end
    end

    describe "#linked_observer_ids_by_shard" do
      before do
        @observer1 = @shard1.activate{ user }
        @observer2 = @shard2.activate{ user }

        @observer_enrollment1 = course_with_observer(:course => @course2, :user => @observer1, :active_all => true)
        @observer_enrollment1.associated_user = @viewing_user
        @observer_enrollment1.save!

        @observer_enrollment2 = course_with_observer(:course => @course2, :user => @observer2, :active_all => true)
        @observer_enrollment2.associated_user = @viewing_user
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
      account_admin_user(:user => @viewing_user, :account => @account1)
      account_admin_user(:user => @viewing_user, :account => @account2)
      @calculator.visible_account_ids_by_shard[@shard1].should == [@account1.local_id]
      @calculator.visible_account_ids_by_shard[@shard2].should == [@account2.local_id]
    end

    describe "fully_visible_group_ids_by_shard" do
      it "should include fully visible groups" do
        group_with_user(:user => @viewing_user)
        result = @calculator.fully_visible_group_ids_by_shard
        result[Shard.default].should == [@group.local_id]
      end

      it "should not include section visible groups" do
        course_with_student(:user => @viewing_user, :active_all => true)
        Enrollment.limit_privileges_to_course_section!(@course, @viewing_user, true)
        group(:group_context => @course)
        result = @calculator.fully_visible_group_ids_by_shard
        result.each{ |k,v| v.should be_empty }
      end

      it "should partition groups by shard" do
        group1 = @shard1.activate do
          account = Account.create!
          group_with_user(:group_context => account, :user => @viewing_user).group
        end
        group2 = @shard2.activate do
          account = Account.create!
          group_with_user(:group_context => account, :user => @viewing_user).group
        end
        result = @calculator.fully_visible_group_ids_by_shard
        result[@shard1].should == [group1.local_id]
        result[@shard2].should == [group2.local_id]
      end
    end

    describe "section_visible_group_ids_by_shard" do
      it "should include section visible groups" do
        course_with_student(:user => @viewing_user, :active_all => true)
        Enrollment.limit_privileges_to_course_section!(@course, @viewing_user, true)
        group(:group_context => @course)
        result = @calculator.section_visible_group_ids_by_shard
        result[Shard.default].should == [@group.local_id]
      end

      it "should not include fully visible groups" do
        group(:user => @viewing_user)
        result = @calculator.section_visible_group_ids_by_shard
        result.each{ |k,v| v.should be_empty }
      end

      it "should partition groups by shard" do
        group1 = nil
        @shard1.activate{
          course_with_student(:account => Account.create!, :user => @viewing_user, :active_all => true)
          group1 = group(:group_context => @course)
        }

        group2 = nil
        @shard2.activate{
          course_with_student(:account => Account.create!, :user => @viewing_user, :active_all => true)
          group2 = group(:group_context => @course)
        }

        Enrollment.limit_privileges_to_course_section!(group1.context, @viewing_user, true)
        Enrollment.limit_privileges_to_course_section!(group2.context, @viewing_user, true)
        result = @calculator.section_visible_group_ids_by_shard
        result[@shard1].should == [group1.local_id]
        result[@shard2].should == [group2.local_id]
      end
    end

    describe "messageable_sections" do
      it "should include messageable sections from any shard" do
        @shard1.activate{ course_with_teacher(:user => @viewing_user, :account => Account.create!, :active_all => true) }
        @course.course_sections.create!
        @calculator.messageable_sections.should include(@course.default_section)
      end
    end

    describe "messageable_groups" do
      it "should include messageable groups from any shard" do
        @shard1.activate{ group_with_user(:user => @viewing_user, :active_all => true) }
        @calculator.messageable_groups.should include(@group)
      end
    end
  end

  describe "public api" do
    describe "load_messageable_users" do
      it "should not break when given an otherwise unmessageable user and a non-nil but empty conversation_id" do
        other_user = User.create!
        lambda{ @calculator.load_messageable_users([other_user], :conversation_id => '') }.should_not raise_exception
      end

      it "should find common courses for users with a common course" do
        course_with_teacher(:user => @viewing_user, :active_all => true)
        student_in_course(:active_all => true)
        @calculator.load_messageable_users([@student]).should_not be_empty
        @calculator.load_messageable_users([@student]).first.common_courses.should == {
          @course.id => ['StudentEnrollment']
        }
      end

      it "should find all common courses for users with a multiple common courses" do
        course_with_teacher(:user => @viewing_user, :active_all => true)
        student_in_course(:active_all => true)
        course1 = @course

        course_with_teacher(:user => @viewing_user, :active_all => true)
        student_in_course(:user => @student, :active_all => true)
        course2 = @course

        @calculator.load_messageable_users([@student]).first.common_courses.should == {
          course1.id => ['StudentEnrollment'],
          course2.id => ['StudentEnrollment']
        }
      end

      it "should only count courses which generate messageability as common" do
        course_with_teacher(:user => @viewing_user, :active_all => true)
        student_in_course(:active_all => true)
        course1 = @course

        course_with_teacher(:user => @viewing_user, :active_all => true)
        student_in_course(:user => @student, :active_all => true, :section => @course.course_sections.create!)
        course2 = @course
        Enrollment.limit_privileges_to_course_section!(course2, @viewing_user, true)

        @calculator.load_messageable_users([@student]).first.common_courses.should == {
          course1.id => ['StudentEnrollment']
        }
      end

      it "should find common groups for users with a common group" do
        group_with_user(:active_all => true)
        @group.add_user(@viewing_user)
        @calculator.load_messageable_users([@user]).should_not be_empty
        @calculator.load_messageable_users([@user]).first.common_groups.should == {
          @group.id => ['Member']
        }
      end

      it "should find all common groups for users with a multiple common groups" do
        group_with_user(:active_all => true)
        @group.add_user(@viewing_user)
        group1 = @group

        group_with_user(:user => @user, :active_all => true)
        @group.add_user(@viewing_user)
        group2 = @group

        @calculator.load_messageable_users([@user]).first.common_groups.should == {
          group1.id => ['Member'],
          group2.id => ['Member']
        }
      end

      it "should only count groups which generate messageability as common" do
        course_with_teacher(:user => @viewing_user, :active_all => true)
        student_in_course(:active_all => true)
        group_with_user(:user => @student, :group_context => @course)
        Enrollment.limit_privileges_to_course_section!(@course, @viewing_user, true)
        @calculator.load_messageable_users([@student]).first.common_groups.should be_empty
      end

      context "creation pending users" do
        before do
          course_with_teacher(:user => @viewing_user, :active_all => true)
          student_in_course(:active_all => true, :user_state => 'creation_pending')
        end

        it "should be excluded by default" do
          @calculator.load_messageable_users([@student]).should be_empty
        end

        it "should be included with strict_checks=false" do
          @calculator.load_messageable_users([@student], :strict_checks => false).should_not be_empty
        end

        it "should set appropriate common courses with strict_checks=false" do
          @calculator.load_messageable_users([@student], :strict_checks => false).first.common_courses.should_not be_empty
        end
      end

      context "deleted users" do
        before do
          course_with_teacher(:user => @viewing_user, :active_all => true)
          student_in_course(:active_all => true, :user_state => 'deleted')
        end

        it "should be excluded by default" do
          @calculator.load_messageable_users([@student]).should be_empty
        end

        it "should be included with strict_checks=false" do
          @calculator.load_messageable_users([@student], :strict_checks => false).should_not be_empty
        end

        it "should set appropriate common courses with strict_checks=false" do
          @calculator.load_messageable_users([@student], :strict_checks => false).first.common_courses.should_not be_empty
        end
      end

      context "unmessageable user" do
        before do
          course_with_teacher(:user => @viewing_user, :active_all => true)
          student_in_course(:active_all => true, :section => @course.course_sections.create!)
          Enrollment.limit_privileges_to_course_section!(@course, @viewing_user, true)
          group_with_user(:group_context => @course, :user => @student)
        end

        it "should not return unmessageable users by default" do
          @calculator.load_messageable_users([@student]).should be_empty
        end

        it "should return nominally unmessageable users with strict_checks=false" do
          @calculator.load_messageable_users([@student], :strict_checks => false).should_not be_empty
        end

        it "should not set common_courses on nominally unmessageable users" do
          @calculator.load_messageable_users([@student], :strict_checks => false).first.common_courses.should be_empty
        end

        it "should not set common_groups on users included only due to strict_checks=false" do
          @calculator.load_messageable_users([@student], :strict_checks => false).first.common_groups.should be_empty
        end
      end

      context "with conversation_id" do
        before do
          @bob = user(:active_all => true)
        end

        it "should not affect anything if the user was already messageable" do
          conversation(@viewing_user, @bob)
          course_with_teacher(:user => @viewing_user, :active_all => true)
          student_in_course(:user => @bob, :active_all => true)

          result = @calculator.load_messageable_users([@bob], :conversation_id => @conversation.conversation_id)
          result.should_not be_empty
          result.first.common_courses.should == {
            @course.id => ['StudentEnrollment']
          }
        end

        it "should make otherwise unmessageable user messageable without adding common contexts" do
          conversation(@viewing_user, @bob)
          course_with_teacher(:user => @viewing_user, :active_all => true)
          student_in_course(:user => @bob, :active_all => true, :section => @course.course_sections.create!)
          Enrollment.limit_privileges_to_course_section!(@course, @viewing_user, true)

          result = @calculator.load_messageable_users([@bob], :conversation_id => @conversation.conversation_id)
          result.should_not be_empty
          result.first.common_courses.should be_empty
        end

        it "should have no effect if conversation doesn't involve viewing user" do
          charlie = user(:active_all => true)
          conversation(@bob, charlie)
          @calculator.load_messageable_users([@bob], :conversation_id => @conversation.conversation_id).should be_empty
        end

        it "should have no effect if conversation doesn't involve target user" do
          charlie = user(:active_all => true)
          conversation(@viewing_user, charlie)
          @calculator.load_messageable_users([@bob], :conversation_id => @conversation.conversation_id).should be_empty
        end

        context "sharding" do
          specs_require_sharding

          it "should work if the conversation's on another shard" do
            @shard1.activate{ conversation(@viewing_user, @bob) }
            @calculator.load_messageable_users([@bob], :conversation_id => @conversation.conversation_id).should_not be_empty
          end
        end
      end
    end

    describe "messageable_users_in_context" do
      it "should recognize asset string course_X" do
        course_with_teacher(:user => @viewing_user)
        @calculator.expects(:messageable_users_in_course_scope).
          with(@course.id, nil, {}).once
        @calculator.messageable_users_in_context(@course.asset_string)
      end

      it "should recognize asset string course_X_admins" do
        course_with_teacher(:user => @viewing_user)
        @calculator.expects(:messageable_users_in_course_scope).
          with(@course.id, ['TeacherEnrollment', 'TaEnrollment'], {}).once
        @calculator.messageable_users_in_context(@course.asset_string + "_admins")
      end

      it "should recognize asset string course_X_students" do
        course_with_teacher(:user => @viewing_user)
        @calculator.expects(:messageable_users_in_course_scope).
          with(@course.id, ['StudentEnrollment'], {}).once
        @calculator.messageable_users_in_context(@course.asset_string + "_students")
      end

      it "should recognize asset string section_X" do
        course_with_teacher(:user => @viewing_user)
        @calculator.expects(:messageable_users_in_section_scope).
          with(@course.default_section.id, nil, {}).once
        @calculator.messageable_users_in_context("section_#{@course.default_section.id}")
      end

      it "should recognize asset string section_X_admins" do
        course_with_teacher(:user => @viewing_user)
        @calculator.expects(:messageable_users_in_section_scope).
          with(@course.default_section.id, ['TeacherEnrollment', 'TaEnrollment'], {}).once
        @calculator.messageable_users_in_context("section_#{@course.default_section.id}_admins")
      end

      it "should recognize asset string section_X_students" do
        course_with_teacher(:user => @viewing_user)
        @calculator.expects(:messageable_users_in_section_scope).
          with(@course.default_section.id, ['StudentEnrollment'], {}).once
        @calculator.messageable_users_in_context("section_#{@course.default_section.id}_students")
      end

      it "should recognize asset string group_X" do
        group_with_user(:user => @viewing_user)
        @calculator.expects(:messageable_users_in_group_scope).
          with(@group.id, {}).once
        @calculator.messageable_users_in_context(@group.asset_string)
      end
    end

    describe "messageable_users_in_course" do
      before do
        course_with_teacher(:user => @viewing_user, :active_all => true)
        student_in_course(:active_all => true)
      end

      it "should include users from the course" do
        @calculator.messageable_users_in_course(@course).map(&:id).
          should include(@student.id)
      end

      it "should exclude otherwise messageable users not in the course" do
        group_with_user(:active_all => true)
        @group.add_user(@viewing_user)
        @calculator.messageable_users_in_course(@course).map(&:id).
          should_not include(@user.id)
      end

      it "should work with a course id" do
        @calculator.messageable_users_in_course(@course.id).map(&:id).
          should include(@student.id)
      end

      context "with enrollment_types" do
        it "should include users with the specified types" do
          @calculator.messageable_users_in_course(@course, :enrollment_types => ['StudentEnrollment']).map(&:id).
            should include(@student.id)
        end

        it "should exclude otherwise messageable users in the course without the specified types" do
          @calculator.messageable_users_in_course(@course, :enrollment_types => ['TeacherEnrollment']).map(&:id).
            should_not include(@student.id)
        end
      end
    end

    describe "messageable_users_in_section" do
      before do
        course_with_teacher(:user => @viewing_user, :active_all => true)
        student_in_course(:active_all => true)
        @section = @course.default_section
      end

      it "should include users from the section" do
        @calculator.messageable_users_in_section(@section).map(&:id).
          should include(@student.id)
      end

      it "should exclude otherwise messageable users not in the section" do
        student_in_course(:active_all => true, :section => @course.course_sections.create!)
        @calculator.load_messageable_users([@student]).should_not be_empty
        @calculator.messageable_users_in_section(@section).map(&:id).
          should_not include(@student.id)
      end

      it "should work with a section id" do
        @calculator.messageable_users_in_section(@section.id).map(&:id).
          should include(@student.id)
      end

      context "with enrollment_types" do
        it "should include users with the specified types" do
          @calculator.messageable_users_in_section(@section, :enrollment_types => ['StudentEnrollment']).map(&:id).
            should include(@student.id)
        end

        it "should exclude otherwise messageable users in the section without the specified types" do
          @calculator.messageable_users_in_section(@section, :enrollment_types => ['TeacherEnrollment']).map(&:id).
            should_not include(@student.id)
        end
      end

      context "with admin_context" do
        it "should treat the section as if visible" do
          other_section = @course.course_sections.create!
          student_in_course(:active_all => true, :section => other_section)
          Enrollment.limit_privileges_to_course_section!(@course, @viewing_user, true)
          @calculator.messageable_users_in_section(other_section, :admin_context => other_section).map(&:id).
            should include(@student.id)
        end
      end

      context "sharding" do
        specs_require_sharding

        it "should work with sections on different shards" do
          Enrollment.limit_privileges_to_course_section!(@course, @viewing_user, true)
          @shard1.activate do
            @calculator.messageable_users_in_section(@section).map(&:id).
              should include(@student.id)
          end
        end
      end
    end

    describe "messageable_users_in_group" do
      before do
        group_with_user(:active_all => true)
        @group.add_user(@viewing_user)
      end

      it "should include users from the group" do
        @calculator.messageable_users_in_group(@group).map(&:id).
          should include(@user.id)
      end

      it "should exclude otherwise messageable users not in the group" do
        course_with_teacher(:user => @viewing_user, :active_all => true)
        student_in_course(:active_all => true)
        @calculator.load_messageable_user(@student).should_not be_nil
        @calculator.messageable_users_in_group(@group).map(&:id).
          should_not include(@student.id)
      end

      it "should work with a group id" do
        @calculator.messageable_users_in_group(@group.id).map(&:id).
          should include(@user.id)
      end

      context "with admin_context" do
        it "should treat the group as if fully visible" do
          # new group, @viewing_user isn't in this one
          group_with_user(:active_all => true)
          @calculator.messageable_users_in_group(@group, :admin_context => @group).map(&:id).
            should include(@user.id)
        end
      end
    end

    describe "search_messageable_users" do
      def messageable_user_ids(options={})
        @calculator.search_messageable_users(options).
          paginate(:per_page => 100).map(&:id)
      end

      context "with a context" do
        before do
          course_with_student(:user => @viewing_user, :active_all => true)
        end

        it "should return a bookmark-paginated collection" do
          @calculator.search_messageable_users(:context => @course.asset_string).
            should be_a(BookmarkedCollection::Proxy)
        end

        it "should not include yourself if you're not in that context" do
          @enrollment.destroy
          messageable_user_ids(:context => @course.asset_string).
            should_not include(@student.id)
        end

        it "should include messageable users from that context" do
          messageable_user_ids(:context => @course.asset_string).should include(@teacher.id)
        end

        it "should not include otherwise messageable users not in that context" do
          # creates a second course separate from @course1 with a new @teacher
          course1 = @course
          course_with_student(:user => @viewing_user, :active_all => true)
          messageable_user_ids(:context => course1.asset_string).should_not include(@teacher.id)
        end

        it "should return an empty set for unrecognized contexts" do
          messageable_user_ids(:context => 'bogus').should be_empty
        end
      end

      context "without a context" do
        it "should return a bookmark-paginated collection" do
          @calculator.search_messageable_users.
            should be_a(BookmarkedCollection::Proxy)
        end

        it "should include yourself even if you're not in any contexts" do
          messageable_user_ids.should include(@viewing_user.id)
        end

        it "should include users messageable via courses" do
          student_in_course(:user => @viewing_user, :active_all => true)
          messageable_user_ids.should include(@teacher.id)
        end

        it "should include users messageable via groups" do
          group_with_user
          @group.add_user(@viewing_user, 'accepted')
          messageable_user_ids.should include(@user.id)
        end

        it "should include users messageable via adminned accounts" do
          user
          tie_user_to_account(@viewing_user, :membership_type => 'AccountAdmin')
          tie_user_to_account(@user, :membership_type => 'Student')
          messageable_user_ids.should include(@user.id)
        end

        it "should sort returned users by name regardless of source" do
          student_in_course(:user => @viewing_user, :active_all => true)
          group_with_user(:user => @viewing_user)

          alice = user(:name => 'Alice')
          @group.add_user(alice, 'accepted')

          @teacher.name = 'Bob'
          @teacher.save!

          @viewing_user.name = 'Charles'
          @viewing_user.save!

          messageable_user_ids.should == [alice.id, @teacher.id, @viewing_user.id]
        end

        context "multiple ways a user is messageable" do
          before do
            student_in_course(:user => @viewing_user, :active_all => true)
            group_with_user(:user => @viewing_user)
            @group.add_user(@teacher, 'accepted')
          end

          it "should only return the user once" do
            messageable_user_ids.should == [@viewing_user.id, @teacher.id]
          end

          it "should have combined common contexts" do
            messageable_user = @calculator.search_messageable_users.
              paginate(:per_page => 2).last
            messageable_user.common_courses.should == {@course.id => ['TeacherEnrollment']}
            messageable_user.common_groups.should == {@group.id => ['Member']}
          end
        end
      end

      it "should exclude exclude_ids" do
        student_in_course(:user => @viewing_user, :active_all => true)
        messageable_user_ids(:exclude_ids => [@teacher.id]).should_not include(@teacher.id)
      end

      context "search parameter" do
        before do
          course_with_teacher(:user => @viewing_user, :active_all => true)
          student_in_course(:name => "Jim Bob")
        end

        it "should include users that match all search terms" do
          messageable_user_ids(:search => "Jim Bob").should include(@student.id)
        end

        it "should exclude users that match only some terms" do
          messageable_user_ids(:search => "Uncle Jim").should_not include(@student.id)
        end

        it "should ignore case when matching search terms" do
          messageable_user_ids(:search => "jim").should include(@student.id)
        end
      end

      context "sharding" do
        specs_require_sharding

        it "should properly interpret and translate exclude_ids" do
          @shard1.activate do
            course(:account => Account.create!, :active_all => true)
            student_in_course(:user => @viewing_user, :active_all => true)
          end

          messageable_user_ids(:exclude_ids => [@teacher.local_id]).should include(@teacher.id)
          messageable_user_ids(:exclude_ids => [@teacher.global_id]).should_not include(@teacher.id)
          @shard1.activate do
            messageable_user_ids(:exclude_ids => [@teacher.local_id]).should_not include(@teacher.id)
            messageable_user_ids(:exclude_ids => [@teacher.global_id]).should_not include(@teacher.id)
          end
        end
      end
    end
  end
end
