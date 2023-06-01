# frozen_string_literal: true

#
# Copyright (C) 2013 - present Instructure, Inc.
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

describe "MessageableUser::Calculator" do
  before do
    @viewing_user = user_factory
    @calculator = MessageableUser::Calculator.new(@viewing_user)
  end

  it "is dumpable" do
    @calculator.linked_observer_ids
    calc2 = Marshal.load(Marshal.dump(@calculator))
    # have to force this to be re-set
    calc2.linked_observer_ids
    expect(calc2.instance_variables.sort).to eq @calculator.instance_variables.sort
  end

  def add_section_to_topic(topic, section)
    topic.is_section_specific = true
    topic.discussion_topic_section_visibilities <<
      DiscussionTopicSectionVisibility.new(
        discussion_topic: topic,
        course_section: section,
        workflow_state: "active"
      )
    topic.save!
  end

  describe "section specific discussion topic" do
    before do
      course_factory(course_name: "Course Name", active_all: true)

      section1 = @course.course_sections.create!(name: "Section 1")
      section2 = @course.course_sections.create!(name: "Section 2")
      section3 = @course.course_sections.create!(name: "Section 3")

      @u1_s1 = student_in_course(course: @course, section: section1, name: "User1 Section1", active_all: true).user
      @u2_s1 = student_in_course(course: @course, section: section1, name: "User2 Section1", active_all: true).user
      @u3_s2 = student_in_course(course: @course, section: section2, name: "User3 Section2", active_all: true).user
      @u4_s2 = student_in_course(course: @course, section: section2, name: "User4 Section2", active_all: true).user
      @u5_s3 = student_in_course(course: @course, section: section3, name: "User5 Section3", active_all: true).user
      @u6_s3 = student_in_course(course: @course, section: section3, name: "User6 Section3", active_all: true).user

      @teacher = User.create(name: "Teacher")

      enrollment = @course.enroll_user(@teacher, "TeacherEnrollment", section: section1)
      enrollment.workflow_state = "active"
      enrollment.save

      enrollment = @course.enroll_user(@teacher, "TeacherEnrollment", section: section2, allow_multiple_enrollments: true)
      enrollment.workflow_state = "active"
      enrollment.save

      enrollment = @course.enroll_user(@teacher, "TeacherEnrollment", section: section3, allow_multiple_enrollments: true)
      enrollment.workflow_state = "active"
      enrollment.save

      @dt = @course.discussion_topics.create!(title: "Section Specific Discussion Topic")
      add_section_to_topic(@dt, section1)
      add_section_to_topic(@dt, section2)
      add_section_to_topic(@dt, section3)
      @dt.reload
    end

    it "mentionable users should have two students and the teacher when user 1" do
      calculator = MessageableUser::Calculator.new(@u1_s1)
      expect(calculator.search_in_context_scope(context: @dt, search: "").pluck(:name)).to eq(["User1 Section1", "User2 Section1", "Teacher"])
    end

    it "mentionable users should have two students and the teacher when user 3" do
      calculator = MessageableUser::Calculator.new(@u3_s2)
      expect(calculator.search_in_context_scope(context: @dt, search: "").pluck(:name)).to eq(["User3 Section2", "User4 Section2", "Teacher"])
    end

    it "mentionable users should have two students and the teacher when user 5" do
      calculator = MessageableUser::Calculator.new(@u5_s3)
      expect(calculator.search_in_context_scope(context: @dt, search: "").pluck(:name)).to eq(["User5 Section3", "User6 Section3", "Teacher"])
    end

    it "mentionable users should have six students and the teacher when teacher" do
      calculator = MessageableUser::Calculator.new(@teacher)
      expect(calculator.search_in_context_scope(context: @dt, search: "").pluck(:name)).to eq(["User1 Section1", "User2 Section1", "User3 Section2", "User4 Section2", "User5 Section3", "User6 Section3", "Teacher"])
    end
  end

  describe "section specific discussion topic with teacher without limit_privileges_to_course_section" do
    before do
      course_factory(course_name: "Course Name", active_all: true)

      section1 = @course.course_sections.create!(name: "Section 1")
      section2 = @course.course_sections.create!(name: "Section 2")
      section3 = @course.course_sections.create!(name: "Section 3")

      @u1_s1 = student_in_course(course: @course, section: section1, name: "User1 Section1", active_all: true).user
      @u2_s1 = student_in_course(course: @course, section: section1, name: "User2 Section1", active_all: true).user
      @u3_s2 = student_in_course(course: @course, section: section2, name: "User3 Section2", active_all: true).user
      @u4_s2 = student_in_course(course: @course, section: section2, name: "User4 Section2", active_all: true).user
      @u5_s3 = student_in_course(course: @course, section: section3, name: "User5 Section3", active_all: true).user
      @u6_s3 = student_in_course(course: @course, section: section3, name: "User6 Section3", active_all: true).user

      @teacher = User.create(name: "Teacher")

      enrollment = @course.enroll_user(@teacher, "TeacherEnrollment", limit_privileges_to_course_section: false)
      enrollment.workflow_state = "active"
      enrollment.save

      @dt1 = @course.discussion_topics.create!(title: "Section 1 Specific Discussion Topic")
      add_section_to_topic(@dt1, section1)
      @dt1.reload

      @dt2 = @course.discussion_topics.create!(title: "Section 2 Specific Discussion Topic")
      add_section_to_topic(@dt2, section2)
      @dt2.reload

      @dt3 = @course.discussion_topics.create!(title: "Section 3 Specific Discussion Topic")
      add_section_to_topic(@dt3, section3)
      @dt3.reload
    end

    it "will return section members" do
      calculator = MessageableUser::Calculator.new(@teacher)
      expect(calculator.search_in_context_scope(context: @dt1, search: "").pluck(:name)).to eq(["User1 Section1", "User2 Section1"])

      calculator = MessageableUser::Calculator.new(@teacher)
      expect(calculator.search_in_context_scope(context: @dt2, search: "").pluck(:name)).to eq(["User3 Section2", "User4 Section2"])

      calculator = MessageableUser::Calculator.new(@teacher)
      expect(calculator.search_in_context_scope(context: @dt3, search: "").pluck(:name)).to eq(["User5 Section3", "User6 Section3"])
    end
  end

  describe "section specific discussion topic with teacher with limit_privileges_to_course_section" do
    before do
      course_factory(course_name: "Course Name", active_all: true)

      section1 = @course.course_sections.create!(name: "Section 1")
      section2 = @course.course_sections.create!(name: "Section 2")
      section3 = @course.course_sections.create!(name: "Section 3")

      @u1_s1 = student_in_course(course: @course, section: section1, name: "User1 Section1", active_all: true).user
      @u2_s1 = student_in_course(course: @course, section: section1, name: "User2 Section1", active_all: true).user
      @u3_s2 = student_in_course(course: @course, section: section2, name: "User3 Section2", active_all: true).user
      @u4_s2 = student_in_course(course: @course, section: section2, name: "User4 Section2", active_all: true).user
      @u5_s3 = student_in_course(course: @course, section: section3, name: "User5 Section3", active_all: true).user
      @u6_s3 = student_in_course(course: @course, section: section3, name: "User6 Section3", active_all: true).user

      @teacher = User.create(name: "Teacher")

      enrollment = @course.enroll_user(@teacher, "TeacherEnrollment", section: section1, limit_privileges_to_course_section: true)
      enrollment.workflow_state = "active"
      enrollment.save

      @dt1 = @course.discussion_topics.create!(title: "Section 1 Specific Discussion Topic")
      add_section_to_topic(@dt1, section1)
      @dt1.reload

      @dt2 = @course.discussion_topics.create!(title: "Section 2 Specific Discussion Topic")
      add_section_to_topic(@dt2, section2)
      @dt2.reload

      @dt3 = @course.discussion_topics.create!(title: "Section 3 Specific Discussion Topic")
      add_section_to_topic(@dt3, section3)
      @dt3.reload
    end

    it "will return the section 1 members" do
      calculator = MessageableUser::Calculator.new(@teacher)
      expect(calculator.search_in_context_scope(context: @dt1, search: "").pluck(:name)).to eq(["User1 Section1", "User2 Section1", "Teacher"])
    end

    it "will return an empty collection of section members" do
      calculator = MessageableUser::Calculator.new(@teacher)
      expect(calculator.search_in_context_scope(context: @dt2, search: "").pluck(:name)).to eq([])

      calculator = MessageableUser::Calculator.new(@teacher)
      expect(calculator.search_in_context_scope(context: @dt3, search: "").pluck(:name)).to eq([])
    end
  end

  describe "uncached crunchers" do
    describe "#uncached_visible_section_ids" do
      before do
        course_with_student(user: @viewing_user, active_all: true)
      end

      it "does not include sections from fully visible courses" do
        expect(@calculator.uncached_visible_section_ids).to eq({})
      end

      it "includes sections from section visible courses" do
        Enrollment.limit_privileges_to_course_section!(@course, @viewing_user, true)
        expect(@calculator.uncached_visible_section_ids.keys).to include(@course.id)
      end

      it "does not include sections from restricted visibility courses" do
        RoleOverride.manage_role_override(Account.default, student_role, "send_messages", override: false)
        expect(@calculator.uncached_visible_section_ids).to eq({})
      end
    end

    describe "#uncached_visible_section_ids_in_course" do
      before do
        course_with_student(user: @viewing_user, active_all: true)
        @section = @course.course_sections.create!
      end

      it "includes sections the user is enrolled in" do
        expect(@calculator.uncached_visible_section_ids_in_course(@course)).to include(@course.default_section.id)
      end

      it "does not include sections the user is not enrolled in" do
        expect(@calculator.uncached_visible_section_ids_in_course(@course)).not_to include(@section.id)
      end

      it "does not include sections from deleted enrollments" do
        multiple_student_enrollment(@viewing_user, @section).destroy
        expect(@calculator.uncached_visible_section_ids_in_course(@course)).not_to include(@section.id)
      end
    end

    describe "#uncached_observed_student_ids" do
      before do
        @observer_enrollment = course_with_observer(user: @viewing_user, active_all: true)
        @observer_enrollment.associated_user = student_in_course(active_all: true).user
        @observer_enrollment.save!
        RoleOverride.manage_role_override(Account.default, observer_role, "send_messages", override: true)
      end

      it "returns an empty hash when no courses" do
        @course.destroy
        expect(@calculator.uncached_observed_student_ids).to eq({})
      end

      it "does not include observed students from fully visible courses" do
        expect(@calculator.uncached_observed_student_ids).to eq({})
      end

      it "does not include observed students from section visible courses" do
        Enrollment.limit_privileges_to_course_section!(@course, @viewing_user, true)
        expect(@calculator.uncached_observed_student_ids).to eq({})
      end

      it "includes observed students from restricted visibility courses" do
        RoleOverride.manage_role_override(Account.default, observer_role, "send_messages", override: false)
        expect(@calculator.uncached_observed_student_ids.keys).to include(@course.id)
        expect(@calculator.uncached_observed_student_ids[@course.id]).to include(@student.id)
      end
    end

    describe "#uncached_observed_student_ids_in_course" do
      before do
        @observer_enrollment = course_with_observer(user: @viewing_user, active_all: true)
        @observer_enrollment.associated_user = student_in_course(active_all: true).user
        @observer_enrollment.save!
      end

      it "includes students the user observes" do
        expect(@calculator.uncached_observed_student_ids_in_course(@course)).to include(@student.id)
      end

      it "does not include students the user is not observing" do
        student_in_course(active_all: true)
        expect(@calculator.uncached_observed_student_ids_in_course(@course)).not_to include(@student.id)
      end
    end

    describe "#uncached_linked_observer_ids" do
      before do
        course_with_student(user: @viewing_user, active_all: true)
      end

      it "returns users observing the student" do
        enrollment = course_with_observer(course: @course, active_all: true)
        enrollment.associated_user = @student
        enrollment.save!
        expect(@calculator.uncached_linked_observer_ids).to include(@observer.global_id)
      end

      it "does not return users observing other students" do
        student_in_course(course: @course, active_all: true)
        enrollment = course_with_observer(course: @course, active_all: true)
        enrollment.associated_user = @student # the new student for this spec
        enrollment.save!
        expect(@calculator.uncached_linked_observer_ids).not_to include(@observer.global_id)
      end
    end

    describe "#uncached_visible_account_ids" do
      it "returns the user's accounts for which the user can read_roster" do
        account_admin_user(user: @viewing_user, account: Account.default)
        expect(@calculator.uncached_visible_account_ids).to include(Account.default.id)
      end

      it "does not return accounts the user is not in" do
        # contrived, but have read_roster permission, but no association
        account = Account.create!
        account_admin_user(user: @viewing_user, account:)
        @viewing_user.user_account_associations.scope.delete_all
        expect(@calculator.uncached_visible_account_ids).not_to include(account.id)
      end

      it "does not return accounts where the user cannot read_roster" do
        # just the pseudonym isn't enough to have an account user that would
        # grant the right
        expect(@calculator.uncached_visible_account_ids).not_to include(Account.default.id)
      end
    end

    describe "#uncached_fully_visible_group_ids" do
      before do
        course_with_student(user: @viewing_user, active_all: true)
        group(group_context: @course)
      end

      it "includes groups the user is in" do
        group_with_user(user: @viewing_user)
        expect(@calculator.uncached_fully_visible_group_ids).to include(@group.id)
      end

      context "group in fully visible courses" do
        it "includes the group if the enrollment is active" do
          expect(@calculator.uncached_fully_visible_group_ids).to include(@group.id)
        end
      end

      context "group in section visible course" do
        before do
          Enrollment.limit_privileges_to_course_section!(@course, @viewing_user, true)
        end

        it "does not include the group" do
          expect(@calculator.uncached_fully_visible_group_ids).not_to include(@group.id)
        end

        it "includes the group if the user's in it" do
          @group.add_user(@viewing_user)
          expect(@calculator.uncached_fully_visible_group_ids).to include(@group.id)
        end
      end

      context "group in restricted visibilty course" do
        before do
          RoleOverride.manage_role_override(Account.default, student_role, "send_messages", override: false)
        end

        it "does not include the group" do
          expect(@calculator.uncached_fully_visible_group_ids).not_to include(@group.id)
        end

        it "includes the group if the user's in it" do
          @group.add_user(@viewing_user)
          expect(@calculator.uncached_fully_visible_group_ids).to include(@group.id)
        end
      end
    end

    describe "#uncached_section_visible_group_ids" do
      before do
        course_with_student(user: @viewing_user, active_all: true)
        group(group_context: @course)
      end

      it "does not include groups not in a course, even with the user in it" do
        group_with_user(user: @viewing_user)
        expect(@calculator.uncached_section_visible_group_ids).not_to include(@group.id)
      end

      it "does not include groups in fully visible courses, even with the user in it" do
        @group.add_user(@viewing_user)
        expect(@calculator.uncached_section_visible_group_ids).not_to include(@group.id)
      end

      context "group in section visible course" do
        before do
          Enrollment.limit_privileges_to_course_section!(@course, @viewing_user, true)
        end

        it "includes the group" do
          expect(@calculator.uncached_section_visible_group_ids).to include(@group.id)
        end

        it "does not include the group if the user is in it" do
          @group.add_user(@viewing_user)
          expect(@calculator.uncached_section_visible_group_ids).not_to include(@group.id)
        end
      end

      it "does not include groups in restricted visibility courses, even with the user in it" do
        RoleOverride.manage_role_override(Account.default, student_role, "send_messages", override: false)
        expect(@calculator.uncached_section_visible_group_ids).to_not include(@group.id)
      end
    end

    describe "#uncached_group_ids_in_courses" do
      it "includes active groups in the courses" do
        course1 = course_factory
        course2 = course_factory
        group1 = group(group_context: course1)
        group2 = group(group_context: course2)
        ids = @calculator.uncached_group_ids_in_courses([course1, course2])
        expect(ids).to include(group1.id)
        expect(ids).to include(group2.id)
      end

      it "does not include deleted groups in the courses" do
        course_factory
        group(group_context: @course).destroy
        expect(@calculator.uncached_group_ids_in_courses([@course])).not_to include(@group.id)
      end

      it "does not include groups in other courses" do
        course1 = course_factory
        course2 = course_factory
        group(group_context: course1)
        expect(@calculator.uncached_group_ids_in_courses([course2])).not_to include(@group.id)
      end
    end

    describe "#uncached_messageable_sections" do
      before do
        course_with_teacher(user: @viewing_user, active_all: true)
      end

      it "includes all sections from fully visible courses with multiple sections" do
        other_section = @course.course_sections.create!
        expect(@calculator.uncached_messageable_sections).to include(@course.default_section)
        expect(@calculator.uncached_messageable_sections).to include(other_section)
      end

      it "includes only enrolled sections from section visible courses" do
        other_section1 = @course.course_sections.create!
        other_section2 = @course.course_sections.create!
        multiple_student_enrollment(@viewing_user, other_section1)
        Enrollment.limit_privileges_to_course_section!(@course, @viewing_user, true)
        expect(@calculator.uncached_messageable_sections).to include(@course.default_section)
        expect(@calculator.uncached_messageable_sections).to include(other_section1)
        expect(@calculator.uncached_messageable_sections).not_to include(other_section2)
      end

      it "does not include sections from courses with only one sections" do
        expect(@calculator.uncached_messageable_sections).to be_empty
      end
    end

    describe "#uncached_messageable_groups" do
      it "includes groups the user is in" do
        group_with_user(user: @viewing_user)
        expect(@calculator.uncached_messageable_groups).to include(@group)
      end

      it "includes groups in fully visible courses with messageable group members" do
        course_with_teacher(user: @viewing_user, active_all: true)
        group_with_user(user: @viewing_user, group_context: @course)
        expect(@calculator.uncached_messageable_groups).to include(@group)
      end

      it "includes groups in section visible courses with messageable group members" do
        course_with_teacher(user: @viewing_user, active_all: true)
        group_with_user(user: @viewing_user, group_context: @course)
        Enrollment.limit_privileges_to_course_section!(@course, @viewing_user, true)
        expect(@calculator.uncached_messageable_groups).to include(@group)
      end

      it "does not include empty groups in fully visible courses" do
        course_with_teacher(user: @viewing_user, active_all: true)
        group(group_context: @course)
        expect(@calculator.uncached_messageable_groups).not_to include(@group)
      end

      it "does not include empty groups in section visible courses" do
        course_with_teacher(user: @viewing_user, active_all: true)
        group(group_context: @course)
        Enrollment.limit_privileges_to_course_section!(@course, @viewing_user, true)
        expect(@calculator.uncached_messageable_groups).not_to include(@group)
      end

      it "does not include groups in section visible courses whose only members are non-messageable" do
        course_with_teacher(user: @viewing_user, active_all: true)
        student_in_course(active_all: true, section: @course.course_sections.create!)
        group_with_user(user: @student, group_context: @course)
        Enrollment.limit_privileges_to_course_section!(@course, @viewing_user, true)
        expect(@calculator.uncached_messageable_groups).not_to include(@group)
      end
    end
  end

  describe "shard_cached" do
    before do
      @expected1 = "random_string1"
      @expected2 = "random_string2"
      @expected3 = "random_string3 (also ponies)"
    end

    describe "sharding" do
      specs_require_sharding

      it "yields once for each of the user's associated shards" do
        allow(@viewing_user).to receive_messages(associated_shards: [@shard1, @shard2])
        values = @calculator.shard_cached("cache_key") { Shard.current.id }
        expect(values.keys.sort_by(&:id)).to eq [@shard1, @shard2].sort_by(&:id)
        expect(values[@shard1]).to eq @shard1.id
        expect(values[@shard2]).to eq @shard2.id
      end
    end

    describe "rails cache" do
      it "shares across calculators with same user" do
        calc2 = MessageableUser::Calculator.new(@viewing_user)
        enable_cache do
          @calculator.shard_cached("cache_key") { @expected1 }
          expect(calc2.shard_cached("cache_key")[Shard.current]).to eq @expected1
        end
      end

      it "distinguishes users" do
        calc2 = MessageableUser::Calculator.new(user_factory)

        enable_cache do
          @calculator.shard_cached("cache_key") { @expected1 }
          calc2.shard_cached("cache_key") { @expected2 }
          expect(calc2.shard_cached("cache_key")[Shard.current]).to eq @expected2
        end
      end

      it "notices when a user changes" do
        calc2 = MessageableUser::Calculator.new(@viewing_user)

        enable_cache do
          @calculator.shard_cached("cache_key") { @expected1 }
          @viewing_user.updated_at = 1.minute.from_now
          calc2.shard_cached("cache_key") { @expected2 }
          expect(calc2.shard_cached("cache_key")[Shard.current]).to eq @expected2
        end
      end

      it "is sensitive to the key" do
        enable_cache do
          @calculator.shard_cached("cache_key1") { @expected1 }
          @calculator.shard_cached("cache_key2") { @expected2 }
          expect(@calculator.shard_cached("cache_key2")[Shard.current]).to eq @expected2
        end
      end

      it "is sensitive to the method results from additional parameters" do
        stub_const("Foo", Struct.new(:cache_key) do
          def marshal_dump
            cache_key
          end

          def marshal_load(data)
            self.cache_key = data
          end
        end)
        expected1 = Foo.new("a")
        expected2 = Foo.new("b")
        expected3 = Foo.new("c")
        allow(@calculator).to receive_messages(method1: expected1)
        allow(@calculator).to receive_messages(method2: expected2)

        calc2 = MessageableUser::Calculator.new(@viewing_user)
        allow(calc2).to receive_messages(method1: expected1)
        allow(calc2).to receive_messages(method2: expected2)

        calc3 = MessageableUser::Calculator.new(@viewing_user)
        allow(calc3).to receive_messages(method1: expected1)
        allow(calc3).to receive_messages(method2: expected3)

        enable_cache do
          @calculator.shard_cached("cache_key", :method1, :method2) { expected1 }
          calc2.shard_cached("cache_key", :method1, :method2) { expected2 }
          calc3.shard_cached("cache_key", :method1, :method2) { expected3 }

          expect(calc2.shard_cached("cache_key")[Shard.current]).to eq expected1
          expect(calc3.shard_cached("cache_key")[Shard.current]).to eq expected3
        end
      end
    end

    describe "object-local cache" do
      it "caches the result the key" do
        @calculator.shard_cached("cache_key") { @expected1 }
        @calculator.shard_cached("cache_key") { raise "should not get here" }
        expect(@calculator.shard_cached("cache_key")[Shard.current]).to eq @expected1
      end

      it "distinguishes different keys" do
        @calculator.shard_cached("cache_key1") { @expected1 }
        @calculator.shard_cached("cache_key2") { @expected2 }
        expect(@calculator.shard_cached("cache_key1")[Shard.current]).to eq @expected1
        expect(@calculator.shard_cached("cache_key2")[Shard.current]).to eq @expected2
      end
    end
  end

  describe "sharded and cached summaries" do
    specs_require_sharding

    before do
      @account1 = @shard1.activate { Account.create! }
      @account2 = @shard2.activate { Account.create! }
      @course1 = course_factory(account: @account1, active_all: 1)
      @course2 = course_factory(account: @account2, active_all: 1)
      course_with_student(course: @course1, user: @viewing_user, active_all: 1)
      course_with_student(course: @course2, user: @viewing_user, active_all: 1)
    end

    it "partitions courses by shard in all_courses_by_shard" do
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

      it "has data local to the shard in the shard bin" do
        expect(@calculator.visible_section_ids_by_shard[@shard1]).to eq({
                                                                          @course1.local_id => [@course1.default_section.local_id]
                                                                        })
      end

      it "includes sections from each shard" do
        expect(@calculator.visible_section_ids_by_shard).to eq({
                                                                 Shard.default => {},
                                                                 @shard1 => { @course1.local_id => [@course1.default_section.local_id] },
                                                                 @shard2 => { @course2.local_id => [@course2.default_section.local_id] }
                                                               })
      end
    end

    describe "#visible_section_ids_in_courses" do
      before do
        Enrollment.limit_privileges_to_course_section!(@course1, @viewing_user, true)
        Enrollment.limit_privileges_to_course_section!(@course2, @viewing_user, true)
      end

      it "only includes ids from the current shard" do
        @shard1.activate { expect(@calculator.visible_section_ids_in_courses([@course1, @course2])).to eq [@course1.default_section.local_id] }
        @shard2.activate { expect(@calculator.visible_section_ids_in_courses([@course1, @course2])).to eq [@course2.default_section.local_id] }
      end

      it "does not include ids from other courses" do
        @shard1.activate { expect(@calculator.visible_section_ids_in_courses([@course2])).to be_empty }
        @shard2.activate { expect(@calculator.visible_section_ids_in_courses([@course1])).to be_empty }
      end
    end

    describe "#observed_student_ids_by_shard" do
      before do
        RoleOverride.manage_role_override(@account1, observer_role, "send_messages", override: false)
        RoleOverride.manage_role_override(@account2, observer_role, "send_messages", override: false)
        @observer_enrollment1 = course_with_observer(course: @course1, active_all: true)
        @observer = @observer_enrollment1.user
        @observer_enrollment2 = course_with_observer(course: @course2, user: @observer, active_all: true)
        @calculator = MessageableUser::Calculator.new(@observer)
      end

      it "handles shard-local observer observing shard-local student" do
        @student = student_in_course(course: @course1, active_all: true).user
        @observer_enrollment1.associated_user = @student
        @observer_enrollment1.save!

        expect(@calculator.observed_student_ids_by_shard[@shard1]).to eq({ @course1.local_id => [@student.local_id] })
      end

      it "handles shard-local observer observing cross-shard student" do
        @shard2.activate { @student = user_factory }
        student_in_course(course: @course1, user: @student, active_all: true)
        @observer_enrollment1.associated_user = @student
        @observer_enrollment1.save!

        expect(@calculator.observed_student_ids_by_shard[@shard1]).to eq({ @course1.local_id => [@student.global_id] })
      end

      it "handles cross-shard observer observing local-shard student" do
        @student = student_in_course(course: @course2, active_all: true).user
        @observer_enrollment2.associated_user = @student
        @observer_enrollment2.save!

        expect(@calculator.observed_student_ids_by_shard[@shard2]).to eq({ @course2.local_id => [@student.local_id] })
      end

      it "handles cross-shard observer observing cross-shard student" do
        @shard1.activate { @student = user_factory }
        student_in_course(course: @course2, user: @student, active_all: true)
        @observer_enrollment2.associated_user = @student
        @observer_enrollment2.save!

        expect(@calculator.observed_student_ids_by_shard[@shard2]).to eq({ @course2.local_id => [@student.global_id] })
      end
    end

    describe "#observed_student_ids_in_courses" do
      before do
        RoleOverride.manage_role_override(@account1, observer_role, "send_messages", override: false)
        RoleOverride.manage_role_override(@account2, observer_role, "send_messages", override: false)

        @student1 = student_in_course(course: @course1, active_all: true).user
        @observer_enrollment1 = course_with_observer(course: @course1, active_all: true)
        @observer_enrollment1.associated_user = @student1
        @observer_enrollment1.save!

        @observer = @observer_enrollment1.user

        @student2 = student_in_course(course: @course2, active_all: true).user
        @observer_enrollment2 = course_with_observer(course: @course2, user: @observer, active_all: true)
        @observer_enrollment2.associated_user = @student2
        @observer_enrollment2.save!

        @calculator = MessageableUser::Calculator.new(@observer)
      end

      it "only includes ids from the current shard" do
        @shard1.activate { expect(@calculator.observed_student_ids_in_courses([@course1, @course2])).to eq [@student1.local_id] }
        @shard2.activate { expect(@calculator.observed_student_ids_in_courses([@course1, @course2])).to eq [@student2.local_id] }
      end

      it "does not include ids from other courses" do
        @shard1.activate { expect(@calculator.observed_student_ids_in_courses([@course2])).to be_empty }
        @shard2.activate { expect(@calculator.observed_student_ids_in_courses([@course1])).to be_empty }
      end
    end

    describe "#linked_observer_ids_by_shard" do
      before do
        @observer1 = @shard1.activate { user_factory }
        @observer2 = @shard2.activate { user_factory }

        @observer_enrollment1 = course_with_observer(course: @course2, user: @observer1, active_all: true)
        @observer_enrollment1.associated_user = @viewing_user
        @observer_enrollment1.save!

        @observer_enrollment2 = course_with_observer(course: @course2, user: @observer2, active_all: true)
        @observer_enrollment2.associated_user = @viewing_user
        @observer_enrollment2.save!
      end

      it "does not partition observers by shards" do
        expect(@calculator.linked_observer_ids_by_shard[@shard1]).to include(@observer1.local_id)
        expect(@calculator.linked_observer_ids_by_shard[@shard1]).to include(@observer2.global_id)
      end

      it "transposes observers ids to shard" do
        expect(@calculator.linked_observer_ids_by_shard[@shard2]).to include(@observer1.global_id)
        expect(@calculator.linked_observer_ids_by_shard[@shard2]).to include(@observer2.local_id)
      end
    end

    it "partitions accounts by shard in visible_account_ids_by_shard" do
      account_admin_user(user: @viewing_user, account: @account1)
      account_admin_user(user: @viewing_user, account: @account2)
      expect(@calculator.visible_account_ids_by_shard[@shard1]).to eq [@account1.local_id]
      expect(@calculator.visible_account_ids_by_shard[@shard2]).to eq [@account2.local_id]
    end

    describe "fully_visible_group_ids_by_shard" do
      it "includes fully visible groups" do
        group_with_user(user: @viewing_user)
        result = @calculator.fully_visible_group_ids_by_shard
        expect(result[Shard.default]).to eq [@group.local_id]
      end

      it "does not include section visible groups" do
        course_with_student(user: @viewing_user, active_all: true)
        Enrollment.limit_privileges_to_course_section!(@course, @viewing_user, true)
        group(group_context: @course)
        result = @calculator.fully_visible_group_ids_by_shard
        result.each_value { |v| expect(v).to be_empty }
      end

      it "partitions groups by shard" do
        group1 = @shard1.activate do
          account = Account.create!
          group_with_user(group_context: account, user: @viewing_user).group
        end
        group2 = @shard2.activate do
          account = Account.create!
          group_with_user(group_context: account, user: @viewing_user).group
        end
        result = @calculator.fully_visible_group_ids_by_shard
        expect(result[@shard1]).to eq [group1.local_id]
        expect(result[@shard2]).to eq [group2.local_id]
      end
    end

    describe "section_visible_group_ids_by_shard" do
      it "includes section visible groups" do
        course_with_student(user: @viewing_user, active_all: true)
        Enrollment.limit_privileges_to_course_section!(@course, @viewing_user, true)
        group(group_context: @course)
        result = @calculator.section_visible_group_ids_by_shard
        expect(result[Shard.default]).to eq [@group.local_id]
      end

      it "does not include fully visible groups" do
        group(user: @viewing_user)
        result = @calculator.section_visible_group_ids_by_shard
        result.each_value { |v| expect(v).to be_empty }
      end

      it "partitions groups by shard" do
        group1 = nil
        @shard1.activate do
          course_with_student(account: Account.create!, user: @viewing_user, active_all: true)
          group1 = group(group_context: @course)
        end

        group2 = nil
        @shard2.activate do
          course_with_student(account: Account.create!, user: @viewing_user, active_all: true)
          group2 = group(group_context: @course)
        end

        Enrollment.limit_privileges_to_course_section!(group1.context, @viewing_user, true)
        Enrollment.limit_privileges_to_course_section!(group2.context, @viewing_user, true)
        result = @calculator.section_visible_group_ids_by_shard
        expect(result[@shard1]).to eq [group1.local_id]
        expect(result[@shard2]).to eq [group2.local_id]
      end
    end

    describe "messageable_sections" do
      it "includes messageable sections from any shard" do
        @shard1.activate { course_with_teacher(user: @viewing_user, account: Account.create!, active_all: true) }
        @course.course_sections.create!
        expect(@calculator.messageable_sections).to include(@course.default_section)
      end
    end

    describe "messageable_groups" do
      it "includes messageable groups from any shard" do
        @shard1.activate { group_with_user(user: @viewing_user, active_all: true) }
        expect(@calculator.messageable_groups).to include(@group)
      end
    end
  end

  describe "public api" do
    describe "load_messageable_users" do
      it "does not break when given an otherwise unmessageable user and a non-nil but empty conversation_id" do
        other_user = User.create!
        expect { @calculator.load_messageable_users([other_user], conversation_id: "") }.not_to raise_exception
      end

      it "finds common courses for users with a common course" do
        course_with_teacher(user: @viewing_user, active_all: true)
        student_in_course(active_all: true)
        expect(@calculator.load_messageable_users([@student])).not_to be_empty
        expect(@calculator.load_messageable_users([@student]).first.common_courses).to eq({
                                                                                            @course.id => ["StudentEnrollment"]
                                                                                          })
      end

      it "finds all common courses for users with a multiple common courses" do
        course_with_teacher(user: @viewing_user, active_all: true)
        student_in_course(active_all: true)
        course1 = @course

        course_with_teacher(user: @viewing_user, active_all: true)
        student_in_course(user: @student, active_all: true)
        course2 = @course

        expect(@calculator.load_messageable_users([@student]).first.common_courses).to eq({
                                                                                            course1.id => ["StudentEnrollment"],
                                                                                            course2.id => ["StudentEnrollment"]
                                                                                          })
      end

      it "only counts courses which generate messageability as common" do
        course_with_teacher(user: @viewing_user, active_all: true)
        student_in_course(active_all: true)
        course1 = @course

        course_with_teacher(user: @viewing_user, active_all: true)
        student_in_course(user: @student, active_all: true, section: @course.course_sections.create!)
        course2 = @course
        Enrollment.limit_privileges_to_course_section!(course2, @viewing_user, true)

        expect(@calculator.load_messageable_users([@student]).first.common_courses).to eq({
                                                                                            course1.id => ["StudentEnrollment"]
                                                                                          })
      end

      it "finds common groups for users with a common group" do
        group_with_user(active_all: true)
        @group.add_user(@viewing_user)
        expect(@calculator.load_messageable_users([@user])).not_to be_empty
        expect(@calculator.load_messageable_users([@user]).first.common_groups).to eq({
                                                                                        @group.id => ["Member"]
                                                                                      })
      end

      it "finds all common groups for users with a multiple common groups" do
        group_with_user(active_all: true)
        @group.add_user(@viewing_user)
        group1 = @group

        group_with_user(user: @user, active_all: true)
        @group.add_user(@viewing_user)
        group2 = @group

        expect(@calculator.load_messageable_users([@user]).first.common_groups).to eq({
                                                                                        group1.id => ["Member"],
                                                                                        group2.id => ["Member"]
                                                                                      })
      end

      it "only counts groups which generate messageability as common" do
        course_with_teacher(user: @viewing_user, active_all: true)
        student_in_course(active_all: true)
        group_with_user(user: @student, group_context: @course)
        Enrollment.limit_privileges_to_course_section!(@course, @viewing_user, true)
        expect(@calculator.load_messageable_users([@student]).first.common_groups).to be_empty
      end

      it "includes user who are admins of the account with no enrollments" do
        new_admin = user_factory
        tie_user_to_account(@viewing_user, role: admin_role)
        tie_user_to_account(new_admin, role: admin_role)
        messageable_users = @calculator.load_messageable_users([new_admin.id])
        expect(messageable_users.map(&:id)).to include(new_admin.id)
      end

      context "creation pending users" do
        before do
          course_with_teacher(user: @viewing_user, active_all: true)
          student_in_course(active_all: true, user_state: "creation_pending")
        end

        it "is excluded by default" do
          expect(@calculator.load_messageable_users([@student])).to be_empty
        end

        it "is included with strict_checks=false" do
          expect(@calculator.load_messageable_users([@student], strict_checks: false)).not_to be_empty
        end

        it "sets appropriate common courses with strict_checks=false" do
          expect(@calculator.load_messageable_users([@student], strict_checks: false).first.common_courses).not_to be_empty
        end
      end

      context "deleted users" do
        before do
          course_with_teacher(user: @viewing_user, active_all: true)
          student_in_course(active_all: true, user_state: "deleted")
        end

        it "is excluded by default" do
          expect(@calculator.load_messageable_users([@student])).to be_empty
        end

        it "is included with strict_checks=false" do
          expect(@calculator.load_messageable_users([@student], strict_checks: false)).not_to be_empty
        end

        it "sets appropriate common courses with strict_checks=false" do
          expect(@calculator.load_messageable_users([@student], strict_checks: false).first.common_courses).not_to be_empty
        end
      end

      context "unmessageable user" do
        before do
          course_with_teacher(user: @viewing_user, active_all: true)
          student_in_course(active_all: true, section: @course.course_sections.create!)
          Enrollment.limit_privileges_to_course_section!(@course, @viewing_user, true)
          group_with_user(group_context: @course, user: @student)
        end

        it "does not return unmessageable users by default" do
          expect(@calculator.load_messageable_users([@student])).to be_empty
        end

        it "returns nominally unmessageable users with strict_checks=false" do
          expect(@calculator.load_messageable_users([@student], strict_checks: false)).not_to be_empty
        end

        it "does not set common_courses on nominally unmessageable users" do
          expect(@calculator.load_messageable_users([@student], strict_checks: false).first.common_courses).to be_empty
        end

        it "does not set common_groups on users included only due to strict_checks=false" do
          expect(@calculator.load_messageable_users([@student], strict_checks: false).first.common_groups).to be_empty
        end
      end

      context "with conversation_id" do
        before do
          @bob = user_factory(active_all: true)
        end

        it "does not affect anything if the user was already messageable" do
          conversation(@viewing_user, @bob)
          course_with_teacher(user: @viewing_user, active_all: true)
          student_in_course(user: @bob, active_all: true)

          result = @calculator.load_messageable_users([@bob], conversation_id: @conversation.conversation_id)
          expect(result).not_to be_empty
          expect(result.first.common_courses).to eq({
                                                      @course.id => ["StudentEnrollment"]
                                                    })
        end

        it "makes otherwise unmessageable user messageable without adding common contexts" do
          conversation(@viewing_user, @bob)
          course_with_teacher(user: @viewing_user, active_all: true)
          student_in_course(user: @bob, active_all: true, section: @course.course_sections.create!)
          Enrollment.limit_privileges_to_course_section!(@course, @viewing_user, true)

          result = @calculator.load_messageable_users([@bob], conversation_id: @conversation.conversation_id)
          expect(result).not_to be_empty
          expect(result.first.common_courses).to be_empty
        end

        it "has no effect if conversation doesn't involve viewing user" do
          charlie = user_factory(active_all: true)
          conversation(@bob, charlie)
          expect(@calculator.load_messageable_users([@bob], conversation_id: @conversation.conversation_id)).to be_empty
        end

        it "has no effect if conversation doesn't involve target user" do
          charlie = user_factory(active_all: true)
          conversation(@viewing_user, charlie)
          expect(@calculator.load_messageable_users([@bob], conversation_id: @conversation.conversation_id)).to be_empty
        end

        context "sharding" do
          specs_require_sharding

          it "works if the conversation's on another shard" do
            @shard1.activate { conversation(@viewing_user, @bob) }
            expect(@calculator.load_messageable_users([@bob], conversation_id: @conversation.conversation_id)).not_to be_empty
          end
        end
      end
    end

    describe "messageable_users_in_context" do
      it "recognizes asset string course_X" do
        course_with_teacher(user: @viewing_user)
        expect(@calculator).to receive(:messageable_users_in_course_scope)
          .with(@course.id, nil, {}).once
        @calculator.messageable_users_in_context(@course.asset_string)
      end

      it "recognizes asset string course_X_admins" do
        course_with_teacher(user: @viewing_user)
        expect(@calculator).to receive(:messageable_users_in_course_scope)
          .with(@course.id, ["TeacherEnrollment", "TaEnrollment"], {}).once
        @calculator.messageable_users_in_context(@course.asset_string + "_admins")
      end

      it "recognizes asset string course_X_students" do
        course_with_teacher(user: @viewing_user)
        expect(@calculator).to receive(:messageable_users_in_course_scope)
          .with(@course.id, ["StudentEnrollment"], {}).once
        @calculator.messageable_users_in_context(@course.asset_string + "_students")
      end

      it "recognizes asset string section_X" do
        course_with_teacher(user: @viewing_user)
        expect(@calculator).to receive(:messageable_users_in_section_scope)
          .with(@course.default_section.id, nil, {}).once
        @calculator.messageable_users_in_context("section_#{@course.default_section.id}")
      end

      it "recognizes asset string section_X_admins" do
        course_with_teacher(user: @viewing_user)
        expect(@calculator).to receive(:messageable_users_in_section_scope)
          .with(@course.default_section.id, ["TeacherEnrollment", "TaEnrollment"], {}).once
        @calculator.messageable_users_in_context("section_#{@course.default_section.id}_admins")
      end

      it "recognizes asset string section_X_students" do
        course_with_teacher(user: @viewing_user)
        expect(@calculator).to receive(:messageable_users_in_section_scope)
          .with(@course.default_section.id, ["StudentEnrollment"], {}).once
        @calculator.messageable_users_in_context("section_#{@course.default_section.id}_students")
      end

      it "recognizes asset string group_X" do
        group_with_user(user: @viewing_user)
        expect(@calculator).to receive(:messageable_users_in_group_scope)
          .with(@group.id, {}).once
        @calculator.messageable_users_in_context(@group.asset_string)
      end
    end

    describe "messageable_users_in_course" do
      before do
        course_with_teacher(user: @viewing_user, active_all: true)
        student_in_course(active_all: true)
      end

      it "includes users from the course" do
        expect(@calculator.messageable_users_in_course(@course).map(&:id))
          .to include(@student.id)
      end

      it "excludes otherwise messageable users not in the course" do
        group_with_user(active_all: true)
        @group.add_user(@viewing_user)
        expect(@calculator.messageable_users_in_course(@course).map(&:id))
          .not_to include(@user.id)
      end

      it "works with a course id" do
        expect(@calculator.messageable_users_in_course(@course.id).map(&:id))
          .to include(@student.id)
      end

      context "with enrollment_types" do
        it "includes users with the specified types" do
          expect(@calculator.messageable_users_in_course(@course, enrollment_types: ["StudentEnrollment"]).map(&:id))
            .to include(@student.id)
        end

        it "excludes otherwise messageable users in the course without the specified types" do
          expect(@calculator.messageable_users_in_course(@course, enrollment_types: ["TeacherEnrollment"]).map(&:id))
            .not_to include(@student.id)
        end
      end
    end

    describe "messageable_users_in_section" do
      before do
        course_with_teacher(user: @viewing_user, active_all: true)
        student_in_course(active_all: true)
        @section = @course.default_section
      end

      it "includes users from the section" do
        expect(@calculator.messageable_users_in_section(@section).map(&:id))
          .to include(@student.id)
      end

      it "excludes otherwise messageable users not in the section" do
        student_in_course(active_all: true, section: @course.course_sections.create!)
        expect(@calculator.load_messageable_users([@student])).not_to be_empty
        expect(@calculator.messageable_users_in_section(@section).map(&:id))
          .not_to include(@student.id)
      end

      it "works with a section id" do
        expect(@calculator.messageable_users_in_section(@section.id).map(&:id))
          .to include(@student.id)
      end

      context "with enrollment_types" do
        it "includes users with the specified types" do
          expect(@calculator.messageable_users_in_section(@section, enrollment_types: ["StudentEnrollment"]).map(&:id))
            .to include(@student.id)
        end

        it "excludes otherwise messageable users in the section without the specified types" do
          expect(@calculator.messageable_users_in_section(@section, enrollment_types: ["TeacherEnrollment"]).map(&:id))
            .not_to include(@student.id)
        end
      end

      context "with admin_context" do
        it "treats the section as if visible" do
          other_section = @course.course_sections.create!
          student_in_course(active_all: true, section: other_section)
          Enrollment.limit_privileges_to_course_section!(@course, @viewing_user, true)
          expect(@calculator.messageable_users_in_section(other_section, admin_context: other_section).map(&:id))
            .to include(@student.id)
        end
      end

      context "sharding" do
        specs_require_sharding

        it "works with sections on different shards" do
          Enrollment.limit_privileges_to_course_section!(@course, @viewing_user, true)
          @shard1.activate do
            expect(@calculator.messageable_users_in_section(@section).map(&:id))
              .to include(@student.id)
          end
        end
      end
    end

    describe "messageable_users_in_group" do
      before do
        group_with_user(active_all: true)
        @group.add_user(@viewing_user)
      end

      it "includes users from the group" do
        expect(@calculator.messageable_users_in_group(@group).map(&:id))
          .to include(@user.id)
      end

      it "excludes otherwise messageable users not in the group" do
        course_with_teacher(user: @viewing_user, active_all: true)
        student_in_course(active_all: true)
        expect(@calculator.load_messageable_user(@student)).not_to be_nil
        expect(@calculator.messageable_users_in_group(@group).map(&:id))
          .not_to include(@student.id)
      end

      it "works with a group id" do
        expect(@calculator.messageable_users_in_group(@group.id).map(&:id))
          .to include(@user.id)
      end

      context "with admin_context" do
        it "treats the group as if fully visible" do
          # new group, @viewing_user isn't in this one
          group_with_user(active_all: true)
          expect(@calculator.messageable_users_in_group(@group, admin_context: @group).map(&:id))
            .to include(@user.id)
        end
      end
    end

    describe "search_messageable_users" do
      def messageable_user_ids(options = {})
        @calculator.search_messageable_users(options)
                   .paginate(per_page: 100).map(&:id)
      end

      context "with a context" do
        before do
          course_with_student(user: @viewing_user, active_all: true)
        end

        it "returns a bookmark-paginated collection" do
          expect(@calculator.search_messageable_users(context: @course.asset_string))
            .to be_a(BookmarkedCollection::Proxy)
        end

        it "does not include yourself if you're not in that context" do
          @enrollment.destroy
          expect(messageable_user_ids(context: @course.asset_string))
            .not_to include(@student.id)
        end

        it "includes messageable users from that context" do
          expect(messageable_user_ids(context: @course.asset_string)).to include(@teacher.id)
        end

        it "does not include otherwise messageable users not in that context" do
          # creates a second course separate from @course1 with a new @teacher
          course1 = @course
          course_with_student(user: @viewing_user, active_all: true)
          expect(messageable_user_ids(context: course1.asset_string)).not_to include(@teacher.id)
        end

        it "returns an empty set for unrecognized contexts" do
          expect(messageable_user_ids(context: "bogus")).to be_empty
        end

        context "for a group" do
          before do
            @group = @course.groups.create(name: "the group")
            @group.add_user(@viewing_user)
          end

          context "send_messages permission is disabled" do
            before do
              @course.account.role_overrides.create!(role: student_role, permission: "send_messages", enabled: false)
            end

            it "does not include group members" do
              expect(messageable_user_ids(context: @group.asset_string)).to be_empty
            end
          end
        end
      end

      context "without a context" do
        it "returns a bookmark-paginated collection" do
          expect(@calculator.search_messageable_users)
            .to be_a(BookmarkedCollection::Proxy)
        end

        it "includes yourself even if you're not in any contexts" do
          expect(messageable_user_ids).to include(@viewing_user.id)
        end

        it "includes users messageable via courses" do
          student_in_course(user: @viewing_user, active_all: true)
          expect(messageable_user_ids).to include(@teacher.id)
        end

        it "includes users messageable via groups" do
          group_with_user
          @group.add_user(@viewing_user, "accepted")
          expect(messageable_user_ids).to include(@user.id)
        end

        it "includes users messageable via adminned accounts" do
          user_factory
          tie_user_to_account(@viewing_user, role: admin_role)
          custom_role = custom_account_role("CustomStudent", account: Account.default)
          tie_user_to_account(@user, role: custom_role)
          expect(messageable_user_ids).to include(@user.id)
        end

        it "sorts returned users by name regardless of source" do
          student_in_course(user: @viewing_user, active_all: true)
          group_with_user(user: @viewing_user)

          alice = user_factory(name: "Alice")
          @group.add_user(alice, "accepted")

          @teacher.name = "Bob"
          @teacher.save!

          @viewing_user.name = "Charles"
          @viewing_user.save!

          expect(messageable_user_ids).to eq [alice.id, @teacher.id, @viewing_user.id]
        end

        context "multiple ways a user is messageable" do
          before do
            student_in_course(user: @viewing_user, active_all: true)
            group_with_user(user: @viewing_user)
            @group.add_user(@teacher, "accepted")
          end

          it "only returns the user once" do
            expect(messageable_user_ids.sort).to eq [@viewing_user.id, @teacher.id]
          end

          it "has combined common contexts" do
            messageable_user = @calculator.search_messageable_users
                                          .paginate(per_page: 2).last
            expect(messageable_user.common_courses).to eq({ @course.id => ["TeacherEnrollment"] })
            expect(messageable_user.common_groups).to eq({ @group.id => ["Member"] })
          end
        end
      end

      it "excludes exclude_ids" do
        student_in_course(user: @viewing_user, active_all: true)
        expect(messageable_user_ids(exclude_ids: [@teacher.id])).not_to include(@teacher.id)
      end

      context "search parameter" do
        before do
          course_with_teacher(user: @viewing_user, active_all: true)
          student_in_course(name: "Jim Bob")
        end

        it "includes users that match all search terms" do
          expect(messageable_user_ids(search: "Jim Bob")).to include(@student.id)
        end

        it "excludes users that match only some terms" do
          expect(messageable_user_ids(search: "Uncle Jim")).not_to include(@student.id)
        end

        it "ignores case when matching search terms" do
          expect(messageable_user_ids(search: "jim")).to include(@student.id)
        end
      end

      context "sharding" do
        specs_require_sharding

        it "properly interprets and translate exclude_ids" do
          @shard1.activate do
            course_factory(account: Account.create!, active_all: true)
            student_in_course(user: @viewing_user, active_all: true)
          end

          expect(messageable_user_ids(exclude_ids: [@teacher.local_id])).to include(@teacher.id)
          expect(messageable_user_ids(exclude_ids: [@teacher.global_id])).not_to include(@teacher.id)
          @shard1.activate do
            expect(messageable_user_ids(exclude_ids: [@teacher.local_id])).not_to include(@teacher.id)
            expect(messageable_user_ids(exclude_ids: [@teacher.global_id])).not_to include(@teacher.id)
          end
        end
      end
    end
  end
end
