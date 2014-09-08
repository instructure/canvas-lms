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

require File.expand_path(File.dirname(__FILE__) + '/../../sharding_spec_helper')

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
        expect(@calculator.uncached_visible_section_ids).to eq({})
      end

      it "should include sections from section visibile courses" do
        Enrollment.limit_privileges_to_course_section!(@course, @viewing_user, true)
        expect(@calculator.uncached_visible_section_ids.keys).to include(@course.id)
      end

      it "should not include sections from restricted visibility courses" do
        RoleOverride.manage_role_override(Account.default, student_role, 'send_messages', :override => false)
        expect(@calculator.uncached_visible_section_ids).to eq({})
      end
    end

    describe "#uncached_visible_section_ids_in_course" do
      before do
        course_with_student(:user => @viewing_user, :active_all => true)
        @section = @course.course_sections.create!
      end

      it "should include sections the user is enrolled in" do
        expect(@calculator.uncached_visible_section_ids_in_course(@course)).to include(@course.default_section.id)
      end

      it "should not include sections the user is not enrolled in" do
        expect(@calculator.uncached_visible_section_ids_in_course(@course)).not_to include(@section.id)
      end

      it "should not include sections from deleted enrollments" do
        multiple_student_enrollment(@viewing_user, @section).destroy
        expect(@calculator.uncached_visible_section_ids_in_course(@course)).not_to include(@section.id)
      end
    end

    describe "#uncached_observed_student_ids" do
      before do
        @observer_enrollment = course_with_observer(:user => @viewing_user, :active_all => true)
        @observer_enrollment.associated_user = student_in_course(:active_all => true).user
        @observer_enrollment.save!
        RoleOverride.manage_role_override(Account.default, observer_role, 'send_messages', :override => true)
      end

      it "should return an empty hash when no courses" do
        @course.destroy
        expect(@calculator.uncached_observed_student_ids).to eq({})
      end

      it "should not include observed students from fully visible courses" do
        expect(@calculator.uncached_observed_student_ids).to eq({})
      end

      it "should not include observed students from section visibile courses" do
        Enrollment.limit_privileges_to_course_section!(@course, @viewing_user, true)
        expect(@calculator.uncached_observed_student_ids).to eq({})
      end

      it "should include observed students from restricted visibility courses" do
        RoleOverride.manage_role_override(Account.default, observer_role, 'send_messages', :override => false)
        expect(@calculator.uncached_observed_student_ids.keys).to include(@course.id)
        expect(@calculator.uncached_observed_student_ids[@course.id]).to include(@student.id)
      end
    end

    describe "#uncached_observed_student_ids_in_course" do
      before do
        @observer_enrollment = course_with_observer(:user => @viewing_user, :active_all => true)
        @observer_enrollment.associated_user = student_in_course(:active_all => true).user
        @observer_enrollment.save!
      end

      it "should include students the user observes" do
        expect(@calculator.uncached_observed_student_ids_in_course(@course)).to include(@student.id)
      end

      it "should not include students the user is not observing" do
        student_in_course(:active_all => true)
        expect(@calculator.uncached_observed_student_ids_in_course(@course)).not_to include(@student.id)
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
        expect(@calculator.uncached_linked_observer_ids).to include(@observer.global_id)
      end

      it "should not return users observing other students" do
        student_in_course(:course => @course, :active_all => true)
        enrollment = course_with_observer(:course => @course, :active_all => true)
        enrollment.associated_user = @student # the new student for this spec
        enrollment.save!
        expect(@calculator.uncached_linked_observer_ids).not_to include(@observer.global_id)
      end
    end

    describe "#uncached_visible_account_ids" do
      it "should return the user's accounts for which the user can read_roster" do
        account_admin_user(:user => @viewing_user, :account => Account.default)
        expect(@calculator.uncached_visible_account_ids).to include(Account.default.id)
      end

      it "should not return accounts the user is not in" do
        # contrived, but have read_roster permission, but no association
        account = Account.create!
        account_admin_user(:user => @viewing_user, :account => account)
        @viewing_user.user_account_associations.scoped.delete_all
        expect(@calculator.uncached_visible_account_ids).not_to include(account.id)
      end

      it "should not return accounts where the user cannot read_roster" do
        # just the pseudonym isn't enough to have an account user that would
        # grant the right
        expect(@calculator.uncached_visible_account_ids).not_to include(Account.default.id)
      end
    end

    describe "#uncached_fully_visible_group_ids" do
      before do
        course_with_student(:user => @viewing_user, :active_all => true)
        group(:group_context => @course)
      end

      it "should include groups the user is in" do
        group_with_user(:user => @viewing_user)
        expect(@calculator.uncached_fully_visible_group_ids).to include(@group.id)
      end

      context "group in fully visible courses" do
        it "should include the group if the enrollment is active" do
          expect(@calculator.uncached_fully_visible_group_ids).to include(@group.id)
        end

        context "concluded enrollment" do
          before do
            @enrollment.workflow_state == 'completed'
            @enrollment.save!
          end

          it "should include the group if the course is still active" do
            expect(@calculator.uncached_fully_visible_group_ids).to include(@group.id)
          end

          it "should include the group if the course was recently concluded" do
            @course.conclude_at = 1.day.ago
            @course.save!
            expect(@calculator.uncached_fully_visible_group_ids).to include(@group.id)
          end

          it "should not include the group if the course concluding was not recent" do
            @course.conclude_at = 45.days.ago
            @course.save!
            expect(@calculator.uncached_fully_visible_group_ids).not_to include(@group.id)
          end

          it "should include the group regardless of course concluding if the user's in the group" do
            @group.add_user(@viewing_user)
            expect(@calculator.uncached_fully_visible_group_ids).to include(@group.id)
          end
        end
      end

      context "group in section visible course" do
        before do
          Enrollment.limit_privileges_to_course_section!(@course, @viewing_user, true)
        end

        it "should not include the group" do
          expect(@calculator.uncached_fully_visible_group_ids).not_to include(@group.id)
        end

        it "should include the group if the user's in it" do
          @group.add_user(@viewing_user)
          expect(@calculator.uncached_fully_visible_group_ids).to include(@group.id)
        end
      end

      context "group in restricted visibilty course" do
        before do
          RoleOverride.manage_role_override(Account.default, student_role, 'send_messages', :override => false)
        end

        it "should not include the group" do
          expect(@calculator.uncached_fully_visible_group_ids).not_to include(@group.id)
        end

        it "should include the group if the user's in it" do
          @group.add_user(@viewing_user)
          expect(@calculator.uncached_fully_visible_group_ids).to include(@group.id)
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
        expect(@calculator.uncached_section_visible_group_ids).not_to include(@group.id)
      end

      it "should not include groups in fully visible courses, even with the user in it" do
        @group.add_user(@viewing_user)
        expect(@calculator.uncached_section_visible_group_ids).not_to include(@group.id)
      end

      context "group in section visible course" do
        before do
          Enrollment.limit_privileges_to_course_section!(@course, @viewing_user, true)
        end

        it "should include the group" do
          expect(@calculator.uncached_section_visible_group_ids).to include(@group.id)
        end

        it "should not include the group if the user is in it" do
          @group.add_user(@viewing_user)
          expect(@calculator.uncached_section_visible_group_ids).not_to include(@group.id)
        end
      end

      it "should not include groups in restricted visibility courses, even with the user in it" do
        RoleOverride.manage_role_override(Account.default, student_role, 'send_messages', :override => false)
        expect(@calculator.uncached_section_visible_group_ids).to_not include(@group.id)
      end
    end

    describe "#uncached_group_ids_in_courses" do
      it "should include active groups in the courses" do
        course1 = course
        course2 = course
        group1 = group(:group_context => course1)
        group2 = group(:group_context => course2)
        ids = @calculator.uncached_group_ids_in_courses([course1, course2])
        expect(ids).to include(group1.id)
        expect(ids).to include(group2.id)
      end

      it "should not include deleted groups in the courses" do
        course
        group(:group_context => @course).destroy
        expect(@calculator.uncached_group_ids_in_courses([@course])).not_to include(@group.id)
      end

      it "should not include groups in other courses" do
        course1 = course
        course2 = course
        group(:group_context => course1)
        expect(@calculator.uncached_group_ids_in_courses([course2])).not_to include(@group.id)
      end
    end

    describe "#uncached_messageable_sections" do
      before do
        course_with_teacher(:user => @viewing_user, :active_all => true)
      end

      it "should include all sections from fully visible courses with multiple sections" do
        other_section = @course.course_sections.create!
        expect(@calculator.uncached_messageable_sections).to include(@course.default_section)
        expect(@calculator.uncached_messageable_sections).to include(other_section)
      end

      it "should include only enrolled sections from section visible courses" do
        other_section1 = @course.course_sections.create!
        other_section2 = @course.course_sections.create!
        multiple_student_enrollment(@viewing_user, other_section1)
        Enrollment.limit_privileges_to_course_section!(@course, @viewing_user, true)
        expect(@calculator.uncached_messageable_sections).to include(@course.default_section)
        expect(@calculator.uncached_messageable_sections).to include(other_section1)
        expect(@calculator.uncached_messageable_sections).not_to include(other_section2)
      end

      it "should not include sections from courses with only one sections" do
        expect(@calculator.uncached_messageable_sections).to be_empty
      end
    end

    describe "#uncached_messageable_groups" do
      it "should include groups the user is in" do
        group_with_user(:user => @viewing_user)
        expect(@calculator.uncached_messageable_groups).to include(@group)
      end

      it "should include groups in fully visible courses with messageable group members" do
        course_with_teacher(:user => @viewing_user, :active_all => true)
        group_with_user(:user => @viewing_user, :group_context => @course)
        expect(@calculator.uncached_messageable_groups).to include(@group)
      end

      it "should include groups in section visible courses with messageable group members" do
        course_with_teacher(:user => @viewing_user, :active_all => true)
        group_with_user(:user => @viewing_user, :group_context => @course)
        Enrollment.limit_privileges_to_course_section!(@course, @viewing_user, true)
        expect(@calculator.uncached_messageable_groups).to include(@group)
      end

      it "should not include empty groups in fully visible courses" do
        course_with_teacher(:user => @viewing_user, :active_all => true)
        group(:group_context => @course)
        expect(@calculator.uncached_messageable_groups).not_to include(@group)
      end

      it "should not include empty groups in section visible courses" do
        course_with_teacher(:user => @viewing_user, :active_all => true)
        group(:group_context => @course)
        Enrollment.limit_privileges_to_course_section!(@course, @viewing_user, true)
        expect(@calculator.uncached_messageable_groups).not_to include(@group)
      end

      it "should not include groups in section visible courses whose only members are non-messageable" do
        course_with_teacher(:user => @viewing_user, :active_all => true)
        student_in_course(:active_all => true, :section => @course.course_sections.create!)
        group_with_user(:user => @student, :group_context => @course)
        Enrollment.limit_privileges_to_course_section!(@course, @viewing_user, true)
        expect(@calculator.uncached_messageable_groups).not_to include(@group)
      end
    end
  end

  describe "shard_cached" do
    before do
      @expected1 = 'random_string1'
      @expected2 = 'random_string2'
      @expected3 = 'random_string3 (also ponies)'
      Foo = Struct.new(:cache_key)
    end

    after do
      Object.send(:remove_const, :Foo)
    end

    describe "sharding" do
      specs_require_sharding

      it "should yield once for each of the user's associated shards" do
        @viewing_user.stubs(:associated_shards => [@shard1, @shard2])
        values = @calculator.shard_cached('cache_key') { Shard.current.id }
        expect(values.keys.sort_by(&:id)).to eq [@shard1, @shard2].sort_by(&:id)
        expect(values[@shard1]).to eq @shard1.id
        expect(values[@shard2]).to eq @shard2.id
      end
    end

    describe "rails cache" do
      it "should share across calculators with same user" do
        calc2 = MessageableUser::Calculator.new(@viewing_user)
        enable_cache do
          @calculator.shard_cached('cache_key') { @expected1 }
          expect(calc2.shard_cached('cache_key')[Shard.current]).to eq @expected1
        end
      end

      it "should distinguish users" do
        calc2 = MessageableUser::Calculator.new(user)

        enable_cache do
          @calculator.shard_cached('cache_key') { @expected1 }
          calc2.shard_cached('cache_key') { @expected2 }
          expect(calc2.shard_cached('cache_key')[Shard.current]).to eq @expected2
        end
      end

      it "should notice when a user changes" do
        calc2 = MessageableUser::Calculator.new(@viewing_user)

        enable_cache do
          @calculator.shard_cached('cache_key') { @expected1 }
          @viewing_user.updated_at = 1.minute.from_now
          calc2.shard_cached('cache_key') { @expected2 }
          expect(calc2.shard_cached('cache_key')[Shard.current]).to eq @expected2
        end
      end

      it "should be sensitive to the key" do
        enable_cache do
          @calculator.shard_cached('cache_key1') { @expected1 }
          @calculator.shard_cached('cache_key2') { @expected2 }
          expect(@calculator.shard_cached('cache_key2')[Shard.current]).to eq @expected2
        end
      end

      it "should be sensitive to the method results from additional parameters" do
        expected1 = Foo.new('a')
        expected2 = Foo.new('b')
        expected3 = Foo.new('c')
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

          expect(calc2.shard_cached('cache_key')[Shard.current]).to eq expected1
          expect(calc3.shard_cached('cache_key')[Shard.current]).to eq expected3
        end
      end
    end

    describe "object-local cache" do
      it "should cache the result the key" do
        @calculator.shard_cached('cache_key') { @expected1 }
        @calculator.shard_cached('cache_key') { raise 'should not get here' }
        expect(@calculator.shard_cached('cache_key')[Shard.current]).to eq @expected1
      end

      it "should distinguish different keys" do
        @calculator.shard_cached('cache_key1') { @expected1 }
        @calculator.shard_cached('cache_key2') { @expected2 }
        expect(@calculator.shard_cached('cache_key1')[Shard.current]).to eq @expected1
        expect(@calculator.shard_cached('cache_key2')[Shard.current]).to eq @expected2
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
      expect(@calculator.all_courses_by_shard).to eq({
        @shard1 => [@course1],
        @shard2 => [@course2],
      })
    end

    describe "#visible_section_ids_by_shard" do
      before do
        Enrollment.limit_privileges_to_course_section!(@course1, @viewing_user, true)
        Enrollment.limit_privileges_to_course_section!(@course2, @viewing_user, true)
      end

      it "should have data local to the shard in the shard bin" do
        expect(@calculator.visible_section_ids_by_shard[@shard1]).to eq({
          @course1.local_id => [@course1.default_section.local_id]
        })
      end

      it "should include sections from each shard" do
        expect(@calculator.visible_section_ids_by_shard).to eq({
          Shard.default => {},
          @shard1 => {@course1.local_id => [@course1.default_section.local_id]},
          @shard2 => {@course2.local_id => [@course2.default_section.local_id]}
        })
      end
    end

    describe "#visible_section_ids_in_courses" do
      before do
        Enrollment.limit_privileges_to_course_section!(@course1, @viewing_user, true)
        Enrollment.limit_privileges_to_course_section!(@course2, @viewing_user, true)
      end

      it "should only include ids from the current shard" do
        @shard1.activate{ expect(@calculator.visible_section_ids_in_courses([@course1, @course2])).to eq [@course1.default_section.local_id] }
        @shard2.activate{ expect(@calculator.visible_section_ids_in_courses([@course1, @course2])).to eq [@course2.default_section.local_id] }
      end

      it "should not include ids from other courses" do
        @shard1.activate{ expect(@calculator.visible_section_ids_in_courses([@course2])).to be_empty }
        @shard2.activate{ expect(@calculator.visible_section_ids_in_courses([@course1])).to be_empty }
      end
    end

    describe "#observed_student_ids_by_shard" do
      before do
        RoleOverride.manage_role_override(@account1, observer_role, 'send_messages', :override => false)
        RoleOverride.manage_role_override(@account2, observer_role, 'send_messages', :override => false)
        @observer_enrollment1 = course_with_observer(:course => @course1, :active_all => true)
        @observer = @observer_enrollment1.user
        @observer_enrollment2 = course_with_observer(:course => @course2, :user => @observer, :active_all => true)
        @calculator = MessageableUser::Calculator.new(@observer)
      end

      it "should handle shard-local observer observing shard-local student" do
        @student = student_in_course(:course => @course1, :active_all => true).user
        @observer_enrollment1.associated_user = @student
        @observer_enrollment1.save!

        expect(@calculator.observed_student_ids_by_shard[@shard1]).to eq({@course1.local_id => [@student.local_id]})
      end

      it "should handle shard-local observer observing cross-shard student" do
        @shard2.activate{ @student = user }
        student_in_course(:course => @course1, :user => @student, :active_all => true)
        @observer_enrollment1.associated_user = @student
        @observer_enrollment1.save!

        expect(@calculator.observed_student_ids_by_shard[@shard1]).to eq({@course1.local_id => [@student.global_id]})
      end

      it "should handle cross-shard observer observing local-shard student" do
        @student = student_in_course(:course => @course2, :active_all => true).user
        @observer_enrollment2.associated_user = @student
        @observer_enrollment2.save!

        expect(@calculator.observed_student_ids_by_shard[@shard2]).to eq({@course2.local_id => [@student.local_id]})
      end

      it "should handle cross-shard observer observing cross-shard student" do
        @shard1.activate{ @student = user }
        student_in_course(:course => @course2, :user => @student, :active_all => true)
        @observer_enrollment2.associated_user = @student
        @observer_enrollment2.save!

        expect(@calculator.observed_student_ids_by_shard[@shard2]).to eq({@course2.local_id => [@student.global_id]})
      end
    end

    describe "#observed_student_ids_in_courses" do
      before do
        RoleOverride.manage_role_override(@account1, observer_role, 'send_messages', :override => false)
        RoleOverride.manage_role_override(@account2, observer_role, 'send_messages', :override => false)

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
        @shard1.activate{ expect(@calculator.observed_student_ids_in_courses([@course1, @course2])).to eq [@student1.local_id] }
        @shard2.activate{ expect(@calculator.observed_student_ids_in_courses([@course1, @course2])).to eq [@student2.local_id] }
      end

      it "should not include ids from other courses" do
        @shard1.activate{ expect(@calculator.observed_student_ids_in_courses([@course2])).to be_empty }
        @shard2.activate{ expect(@calculator.observed_student_ids_in_courses([@course1])).to be_empty }
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
        expect(@calculator.linked_observer_ids_by_shard[@shard1]).to include(@observer1.local_id)
        expect(@calculator.linked_observer_ids_by_shard[@shard1]).to include(@observer2.global_id)
      end

      it "should transpose observers ids to shard" do
        expect(@calculator.linked_observer_ids_by_shard[@shard2]).to include(@observer1.global_id)
        expect(@calculator.linked_observer_ids_by_shard[@shard2]).to include(@observer2.local_id)
      end
    end

    it "should partition accounts by shard in visible_account_ids_by_shard" do
      account_admin_user(:user => @viewing_user, :account => @account1)
      account_admin_user(:user => @viewing_user, :account => @account2)
      expect(@calculator.visible_account_ids_by_shard[@shard1]).to eq [@account1.local_id]
      expect(@calculator.visible_account_ids_by_shard[@shard2]).to eq [@account2.local_id]
    end

    describe "fully_visible_group_ids_by_shard" do
      it "should include fully visible groups" do
        group_with_user(:user => @viewing_user)
        result = @calculator.fully_visible_group_ids_by_shard
        expect(result[Shard.default]).to eq [@group.local_id]
      end

      it "should not include section visible groups" do
        course_with_student(:user => @viewing_user, :active_all => true)
        Enrollment.limit_privileges_to_course_section!(@course, @viewing_user, true)
        group(:group_context => @course)
        result = @calculator.fully_visible_group_ids_by_shard
        result.each{ |k,v| expect(v).to be_empty }
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
        expect(result[@shard1]).to eq [group1.local_id]
        expect(result[@shard2]).to eq [group2.local_id]
      end
    end

    describe "section_visible_group_ids_by_shard" do
      it "should include section visible groups" do
        course_with_student(:user => @viewing_user, :active_all => true)
        Enrollment.limit_privileges_to_course_section!(@course, @viewing_user, true)
        group(:group_context => @course)
        result = @calculator.section_visible_group_ids_by_shard
        expect(result[Shard.default]).to eq [@group.local_id]
      end

      it "should not include fully visible groups" do
        group(:user => @viewing_user)
        result = @calculator.section_visible_group_ids_by_shard
        result.each{ |k,v| expect(v).to be_empty }
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
        expect(result[@shard1]).to eq [group1.local_id]
        expect(result[@shard2]).to eq [group2.local_id]
      end
    end

    describe "messageable_sections" do
      it "should include messageable sections from any shard" do
        @shard1.activate{ course_with_teacher(:user => @viewing_user, :account => Account.create!, :active_all => true) }
        @course.course_sections.create!
        expect(@calculator.messageable_sections).to include(@course.default_section)
      end
    end

    describe "messageable_groups" do
      it "should include messageable groups from any shard" do
        @shard1.activate{ group_with_user(:user => @viewing_user, :active_all => true) }
        expect(@calculator.messageable_groups).to include(@group)
      end
    end
  end

  describe "public api" do
    describe "load_messageable_users" do
      it "should not break when given an otherwise unmessageable user and a non-nil but empty conversation_id" do
        other_user = User.create!
        expect{ @calculator.load_messageable_users([other_user], :conversation_id => '') }.not_to raise_exception
      end

      it "should find common courses for users with a common course" do
        course_with_teacher(:user => @viewing_user, :active_all => true)
        student_in_course(:active_all => true)
        expect(@calculator.load_messageable_users([@student])).not_to be_empty
        expect(@calculator.load_messageable_users([@student]).first.common_courses).to eq({
          @course.id => ['StudentEnrollment']
        })
      end

      it "should find all common courses for users with a multiple common courses" do
        course_with_teacher(:user => @viewing_user, :active_all => true)
        student_in_course(:active_all => true)
        course1 = @course

        course_with_teacher(:user => @viewing_user, :active_all => true)
        student_in_course(:user => @student, :active_all => true)
        course2 = @course

        expect(@calculator.load_messageable_users([@student]).first.common_courses).to eq({
          course1.id => ['StudentEnrollment'],
          course2.id => ['StudentEnrollment']
        })
      end

      it "should only count courses which generate messageability as common" do
        course_with_teacher(:user => @viewing_user, :active_all => true)
        student_in_course(:active_all => true)
        course1 = @course

        course_with_teacher(:user => @viewing_user, :active_all => true)
        student_in_course(:user => @student, :active_all => true, :section => @course.course_sections.create!)
        course2 = @course
        Enrollment.limit_privileges_to_course_section!(course2, @viewing_user, true)

        expect(@calculator.load_messageable_users([@student]).first.common_courses).to eq({
          course1.id => ['StudentEnrollment']
        })
      end

      it "should find common groups for users with a common group" do
        group_with_user(:active_all => true)
        @group.add_user(@viewing_user)
        expect(@calculator.load_messageable_users([@user])).not_to be_empty
        expect(@calculator.load_messageable_users([@user]).first.common_groups).to eq({
          @group.id => ['Member']
        })
      end

      it "should find all common groups for users with a multiple common groups" do
        group_with_user(:active_all => true)
        @group.add_user(@viewing_user)
        group1 = @group

        group_with_user(:user => @user, :active_all => true)
        @group.add_user(@viewing_user)
        group2 = @group

        expect(@calculator.load_messageable_users([@user]).first.common_groups).to eq({
          group1.id => ['Member'],
          group2.id => ['Member']
        })
      end

      it "should only count groups which generate messageability as common" do
        course_with_teacher(:user => @viewing_user, :active_all => true)
        student_in_course(:active_all => true)
        group_with_user(:user => @student, :group_context => @course)
        Enrollment.limit_privileges_to_course_section!(@course, @viewing_user, true)
        expect(@calculator.load_messageable_users([@student]).first.common_groups).to be_empty
      end

      context "creation pending users" do
        before do
          course_with_teacher(:user => @viewing_user, :active_all => true)
          student_in_course(:active_all => true, :user_state => 'creation_pending')
        end

        it "should be excluded by default" do
          expect(@calculator.load_messageable_users([@student])).to be_empty
        end

        it "should be included with strict_checks=false" do
          expect(@calculator.load_messageable_users([@student], :strict_checks => false)).not_to be_empty
        end

        it "should set appropriate common courses with strict_checks=false" do
          expect(@calculator.load_messageable_users([@student], :strict_checks => false).first.common_courses).not_to be_empty
        end
      end

      context "deleted users" do
        before do
          course_with_teacher(:user => @viewing_user, :active_all => true)
          student_in_course(:active_all => true, :user_state => 'deleted')
        end

        it "should be excluded by default" do
          expect(@calculator.load_messageable_users([@student])).to be_empty
        end

        it "should be included with strict_checks=false" do
          expect(@calculator.load_messageable_users([@student], :strict_checks => false)).not_to be_empty
        end

        it "should set appropriate common courses with strict_checks=false" do
          expect(@calculator.load_messageable_users([@student], :strict_checks => false).first.common_courses).not_to be_empty
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
          expect(@calculator.load_messageable_users([@student])).to be_empty
        end

        it "should return nominally unmessageable users with strict_checks=false" do
          expect(@calculator.load_messageable_users([@student], :strict_checks => false)).not_to be_empty
        end

        it "should not set common_courses on nominally unmessageable users" do
          expect(@calculator.load_messageable_users([@student], :strict_checks => false).first.common_courses).to be_empty
        end

        it "should not set common_groups on users included only due to strict_checks=false" do
          expect(@calculator.load_messageable_users([@student], :strict_checks => false).first.common_groups).to be_empty
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
          expect(result).not_to be_empty
          expect(result.first.common_courses).to eq({
            @course.id => ['StudentEnrollment']
          })
        end

        it "should make otherwise unmessageable user messageable without adding common contexts" do
          conversation(@viewing_user, @bob)
          course_with_teacher(:user => @viewing_user, :active_all => true)
          student_in_course(:user => @bob, :active_all => true, :section => @course.course_sections.create!)
          Enrollment.limit_privileges_to_course_section!(@course, @viewing_user, true)

          result = @calculator.load_messageable_users([@bob], :conversation_id => @conversation.conversation_id)
          expect(result).not_to be_empty
          expect(result.first.common_courses).to be_empty
        end

        it "should have no effect if conversation doesn't involve viewing user" do
          charlie = user(:active_all => true)
          conversation(@bob, charlie)
          expect(@calculator.load_messageable_users([@bob], :conversation_id => @conversation.conversation_id)).to be_empty
        end

        it "should have no effect if conversation doesn't involve target user" do
          charlie = user(:active_all => true)
          conversation(@viewing_user, charlie)
          expect(@calculator.load_messageable_users([@bob], :conversation_id => @conversation.conversation_id)).to be_empty
        end

        context "sharding" do
          specs_require_sharding

          it "should work if the conversation's on another shard" do
            @shard1.activate{ conversation(@viewing_user, @bob) }
            expect(@calculator.load_messageable_users([@bob], :conversation_id => @conversation.conversation_id)).not_to be_empty
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
        expect(@calculator.messageable_users_in_course(@course).map(&:id)).
          to include(@student.id)
      end

      it "should exclude otherwise messageable users not in the course" do
        group_with_user(:active_all => true)
        @group.add_user(@viewing_user)
        expect(@calculator.messageable_users_in_course(@course).map(&:id)).
          not_to include(@user.id)
      end

      it "should work with a course id" do
        expect(@calculator.messageable_users_in_course(@course.id).map(&:id)).
          to include(@student.id)
      end

      context "with enrollment_types" do
        it "should include users with the specified types" do
          expect(@calculator.messageable_users_in_course(@course, :enrollment_types => ['StudentEnrollment']).map(&:id)).
            to include(@student.id)
        end

        it "should exclude otherwise messageable users in the course without the specified types" do
          expect(@calculator.messageable_users_in_course(@course, :enrollment_types => ['TeacherEnrollment']).map(&:id)).
            not_to include(@student.id)
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
        expect(@calculator.messageable_users_in_section(@section).map(&:id)).
          to include(@student.id)
      end

      it "should exclude otherwise messageable users not in the section" do
        student_in_course(:active_all => true, :section => @course.course_sections.create!)
        expect(@calculator.load_messageable_users([@student])).not_to be_empty
        expect(@calculator.messageable_users_in_section(@section).map(&:id)).
          not_to include(@student.id)
      end

      it "should work with a section id" do
        expect(@calculator.messageable_users_in_section(@section.id).map(&:id)).
          to include(@student.id)
      end

      context "with enrollment_types" do
        it "should include users with the specified types" do
          expect(@calculator.messageable_users_in_section(@section, :enrollment_types => ['StudentEnrollment']).map(&:id)).
            to include(@student.id)
        end

        it "should exclude otherwise messageable users in the section without the specified types" do
          expect(@calculator.messageable_users_in_section(@section, :enrollment_types => ['TeacherEnrollment']).map(&:id)).
            not_to include(@student.id)
        end
      end

      context "with admin_context" do
        it "should treat the section as if visible" do
          other_section = @course.course_sections.create!
          student_in_course(:active_all => true, :section => other_section)
          Enrollment.limit_privileges_to_course_section!(@course, @viewing_user, true)
          expect(@calculator.messageable_users_in_section(other_section, :admin_context => other_section).map(&:id)).
            to include(@student.id)
        end
      end

      context "sharding" do
        specs_require_sharding

        it "should work with sections on different shards" do
          Enrollment.limit_privileges_to_course_section!(@course, @viewing_user, true)
          @shard1.activate do
            expect(@calculator.messageable_users_in_section(@section).map(&:id)).
              to include(@student.id)
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
        expect(@calculator.messageable_users_in_group(@group).map(&:id)).
          to include(@user.id)
      end

      it "should exclude otherwise messageable users not in the group" do
        course_with_teacher(:user => @viewing_user, :active_all => true)
        student_in_course(:active_all => true)
        expect(@calculator.load_messageable_user(@student)).not_to be_nil
        expect(@calculator.messageable_users_in_group(@group).map(&:id)).
          not_to include(@student.id)
      end

      it "should work with a group id" do
        expect(@calculator.messageable_users_in_group(@group.id).map(&:id)).
          to include(@user.id)
      end

      context "with admin_context" do
        it "should treat the group as if fully visible" do
          # new group, @viewing_user isn't in this one
          group_with_user(:active_all => true)
          expect(@calculator.messageable_users_in_group(@group, :admin_context => @group).map(&:id)).
            to include(@user.id)
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
          expect(@calculator.search_messageable_users(:context => @course.asset_string)).
            to be_a(BookmarkedCollection::Proxy)
        end

        it "should not include yourself if you're not in that context" do
          @enrollment.destroy
          expect(messageable_user_ids(:context => @course.asset_string)).
            not_to include(@student.id)
        end

        it "should include messageable users from that context" do
          expect(messageable_user_ids(:context => @course.asset_string)).to include(@teacher.id)
        end

        it "should not include otherwise messageable users not in that context" do
          # creates a second course separate from @course1 with a new @teacher
          course1 = @course
          course_with_student(:user => @viewing_user, :active_all => true)
          expect(messageable_user_ids(:context => course1.asset_string)).not_to include(@teacher.id)
        end

        it "should return an empty set for unrecognized contexts" do
          expect(messageable_user_ids(:context => 'bogus')).to be_empty
        end
      end

      context "without a context" do
        it "should return a bookmark-paginated collection" do
          expect(@calculator.search_messageable_users).
            to be_a(BookmarkedCollection::Proxy)
        end

        it "should include yourself even if you're not in any contexts" do
          expect(messageable_user_ids).to include(@viewing_user.id)
        end

        it "should include users messageable via courses" do
          student_in_course(:user => @viewing_user, :active_all => true)
          expect(messageable_user_ids).to include(@teacher.id)
        end

        it "should include users messageable via groups" do
          group_with_user
          @group.add_user(@viewing_user, 'accepted')
          expect(messageable_user_ids).to include(@user.id)
        end

        it "should include users messageable via adminned accounts" do
          user
          tie_user_to_account(@viewing_user, :role => admin_role)
          custom_role = custom_account_role('Student', :account => Account.default)
          tie_user_to_account(@user, :role => custom_role)
          expect(messageable_user_ids).to include(@user.id)
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

          expect(messageable_user_ids).to eq [alice.id, @teacher.id, @viewing_user.id]
        end

        context "multiple ways a user is messageable" do
          before do
            student_in_course(:user => @viewing_user, :active_all => true)
            group_with_user(:user => @viewing_user)
            @group.add_user(@teacher, 'accepted')
          end

          it "should only return the user once" do
            expect(messageable_user_ids).to eq [@viewing_user.id, @teacher.id]
          end

          it "should have combined common contexts" do
            messageable_user = @calculator.search_messageable_users.
              paginate(:per_page => 2).last
            expect(messageable_user.common_courses).to eq({@course.id => ['TeacherEnrollment']})
            expect(messageable_user.common_groups).to eq({@group.id => ['Member']})
          end
        end
      end

      it "should exclude exclude_ids" do
        student_in_course(:user => @viewing_user, :active_all => true)
        expect(messageable_user_ids(:exclude_ids => [@teacher.id])).not_to include(@teacher.id)
      end

      context "search parameter" do
        before do
          course_with_teacher(:user => @viewing_user, :active_all => true)
          student_in_course(:name => "Jim Bob")
        end

        it "should include users that match all search terms" do
          expect(messageable_user_ids(:search => "Jim Bob")).to include(@student.id)
        end

        it "should exclude users that match only some terms" do
          expect(messageable_user_ids(:search => "Uncle Jim")).not_to include(@student.id)
        end

        it "should ignore case when matching search terms" do
          expect(messageable_user_ids(:search => "jim")).to include(@student.id)
        end
      end

      context "sharding" do
        specs_require_sharding

        it "should properly interpret and translate exclude_ids" do
          @shard1.activate do
            course(:account => Account.create!, :active_all => true)
            student_in_course(:user => @viewing_user, :active_all => true)
          end

          expect(messageable_user_ids(:exclude_ids => [@teacher.local_id])).to include(@teacher.id)
          expect(messageable_user_ids(:exclude_ids => [@teacher.global_id])).not_to include(@teacher.id)
          @shard1.activate do
            expect(messageable_user_ids(:exclude_ids => [@teacher.local_id])).not_to include(@teacher.id)
            expect(messageable_user_ids(:exclude_ids => [@teacher.global_id])).not_to include(@teacher.id)
          end
        end
      end
    end
  end
end
