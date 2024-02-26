# frozen_string_literal: true

#
# Copyright (C) 2016 - present Instructure, Inc.
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

describe AddressBook::MessageableUser do
  describe "known_users" do
    it "restricts to provided users" do
      teacher = teacher_in_course(active_all: true).user
      student1 = student_in_course(active_all: true).user
      student2 = student_in_course(active_all: true).user
      address_book = AddressBook::MessageableUser.new(teacher)
      known_users = address_book.known_users([student1])
      expect(known_users.map(&:id)).to include(student1.id)
      expect(known_users.map(&:id)).not_to include(student2.id)
    end

    it "includes only known users" do
      teacher = teacher_in_course(active_all: true).user
      student1 = student_in_course(active_all: true).user
      student2 = student_in_course(course: course_factory, active_all: true).user
      address_book = AddressBook::MessageableUser.new(teacher)
      known_users = address_book.known_users([student1, student2])
      expect(known_users.map(&:id)).to include(student1.id)
      expect(known_users.map(&:id)).not_to include(student2.id)
    end

    it "includes group members from different sections" do
      course = course_factory(active_all: true)
      section1 = course.course_sections.create!
      section2 = course.course_sections.create!

      student1 = student_in_course(user: @sender, course:, active_all: true, section: section1, limit_privileges_to_course_section: true).user
      student2 = student_in_course(course:, active_all: true, section: section2, limit_privileges_to_course_section: true).user
      student3 = student_in_course(course:, active_all: true, section: section2, limit_privileges_to_course_section: true).user

      group = group_with_user(user: student1, group_context: course).group
      group.add_user(student2)

      address_book = AddressBook::MessageableUser.new(student1)
      known_users = address_book.known_users([student2, student3])
      expect(known_users.map(&:id)).to include(student2.id)
      expect(known_users.map(&:id)).not_to include(student3.id)
    end

    it "works for a discussion topic" do
      course = course_factory(active_all: true)
      topic = course.discussion_topics.create!

      student1 = student_in_course(user: @sender, course:, active_all: true).user
      student2 = student_in_course(course:, active_all: true).user

      address_book = AddressBook::MessageableUser.new(student1)
      known_users = address_book.known_users([student2], context: topic)
      expect(known_users.map(&:id)).to include(student2.id)
    end

    it "works for a group discussion topic" do
      course = course_factory(active_all: true)

      student1 = student_in_course(user: @sender, course:, active_all: true).user
      student2 = student_in_course(course:, active_all: true).user
      student3 = student_in_course(course:, active_all: true).user
      group = group_with_user(user: student1, group_context: course).group
      group.add_user(student2)
      topic = group.discussion_topics.create!

      address_book = AddressBook::MessageableUser.new(student1)
      known_users = address_book.known_users([student2, student3], context: topic)
      expect(known_users.map(&:id)).to include(student2.id)
      expect(known_users.map(&:id)).not_to include(student3.id)
    end

    it "works for a graded discussion topic" do
      course = course_factory(active_all: true)
      topic = graded_discussion_topic(context: course)

      teacher = teacher_in_course(course:, active_all: true).user
      student1 = student_in_course(course:, active_all: true).user
      student2 = student_in_course(course:, active_all: true).user
      student3 = student_in_course(course:, active_all: true).user
      student4 = student_in_course(course:, active_all: true).user
      student5 = student_in_course(course:, active_all: true).user

      assignment = topic.assignment
      assignment.only_visible_to_overrides = true
      assignment.save

      create_adhoc_override_for_assignment(assignment, [student1, student2])

      address_book = AddressBook::MessageableUser.new(teacher)
      known_users = address_book.known_users([student1, student2, student3, student4, student5], context: topic)
      known_user_ids = known_users.map(&:id)

      expect(known_user_ids).to include(student1.id)
      expect(known_user_ids).to include(student2.id)
      expect(known_user_ids).not_to include(student3.id)
      expect(known_user_ids).not_to include(student4.id)
      expect(known_user_ids).not_to include(student5.id)
    end

    it "caches the results for known users" do
      teacher = teacher_in_course(active_all: true).user
      student = student_in_course(active_all: true).user
      address_book = AddressBook::MessageableUser.new(teacher)
      expect(address_book.known_users([student])).to be_present
      expect(address_book.cached?(student)).to be_truthy
    end

    it "caches the failure for unknown users" do
      teacher = teacher_in_course(active_all: true).user
      student = student_in_course(course: course_factory, active_all: true).user
      address_book = AddressBook::MessageableUser.new(teacher)
      expect(address_book.known_users([student])).to be_empty
      expect(address_book.cached?(student)).to be_truthy
    end

    it "doesn't refetch already cached users" do
      teacher = teacher_in_course(active_all: true).user
      student1 = student_in_course(active_all: true).user
      student2 = student_in_course(active_all: true).user
      student3 = student_in_course(active_all: true).user
      address_book = AddressBook::MessageableUser.new(teacher)
      address_book.known_users([student1, student2])
      expect(teacher).to receive(:load_messageable_users)
        .with([student3], anything)
        .and_return(MessageableUser.where(id: student3).to_a)
      known_users = address_book.known_users([student2, student3])
      expect(known_users.map(&:id)).to include(student2.id)
      expect(known_users.map(&:id)).to include(student3.id)
    end

    describe "with optional :context" do
      before do
        @recipient = user_model(workflow_state: "registered")
        @sender = user_model(workflow_state: "registered")
        @address_book = AddressBook::MessageableUser.new(@sender)

        # recipient participates in three courses
        @course1 = course_model(workflow_state: "available")
        @course2 = course_model(workflow_state: "available")
        @course3 = course_model(workflow_state: "available")
        student_in_course(user: @recipient, course: @course1, active_all: true)
        student_in_course(user: @recipient, course: @course2, active_all: true)
        student_in_course(user: @recipient, course: @course3, active_all: true)

        # but only two are shared with sender (visible with the sender)
        teacher_in_course(user: @sender, course: @course1, active_all: true)
        teacher_in_course(user: @sender, course: @course2, active_all: true)
      end

      it "includes all known contexts when absent" do
        expect(@address_book.known_users([@recipient])).not_to be_empty
        expect(@address_book.common_courses(@recipient)).to include(@course1.id)
        expect(@address_book.common_courses(@recipient)).to include(@course2.id)
      end

      it "excludes unknown contexts when absent, even if admin" do
        account_admin_user(user: @sender, account: @course3.account)
        expect(@address_book.known_users([@recipient])).not_to be_empty
        expect(@address_book.common_courses(@recipient)).not_to include(@course3.id)
      end

      it "excludes other known contexts when specified" do
        expect(@address_book.known_users([@recipient], context: @course1)).not_to be_empty
        expect(@address_book.common_courses(@recipient)).to include(@course1.id)
        expect(@address_book.common_courses(@recipient)).not_to include(@course2.id)
      end

      it "excludes specified unknown context when sender is non-admin" do
        expect(@address_book.known_users([@recipient], context: @course3)).to be_empty
        expect(@address_book.common_courses(@recipient)).not_to include(@course3.id)
      end

      it "excludes specified unknown course when sender is a participant admin" do
        # i.e. the sender does partipate in the course, at a level that
        # nominally gives them read_as_admin (e.g. teacher, usually), but still
        # doesn't know of recipient's participation, likely because of section
        # limited enrollment.
        section = @course3.course_sections.create!
        teacher_in_course(user: @sender, course: @course3, active_all: true, section:, limit_privileges_to_course_section: true)
        expect(@address_book.known_users([@recipient], context: @course3)).to be_empty
        expect(@address_book.common_courses(@recipient)).not_to include(@course3.id)
      end

      it "includes specified unknown context when sender is non-participant admin" do
        account_admin_user(user: @sender, account: @course3.account)
        expect(@address_book.known_users([@recipient], context: @course3)).not_to be_empty
        expect(@address_book.common_courses(@recipient)).to include(@course3.id)
      end
    end

    describe "with optional :conversation_id" do
      it "treats unknown users in that conversation as known" do
        course1 = course_factory(active_all: true)
        course2 = course_factory(active_all: true)
        teacher = teacher_in_course(course: course1, active_all: true).user
        student = student_in_course(course: course2, active_all: true).user
        conversation = Conversation.initiate([teacher, student], true)
        address_book = AddressBook::MessageableUser.new(teacher)
        known_users = address_book.known_users([student], conversation_id: conversation.id)
        expect(known_users.map(&:id)).to include(student.id)
      end

      it "ignores if sender is not a participant in the conversation" do
        course1 = course_factory(active_all: true)
        course2 = course_factory(active_all: true)
        teacher = teacher_in_course(course: course1, active_all: true).user
        student1 = student_in_course(course: course2, active_all: true).user
        student2 = student_in_course(course: course2, active_all: true).user
        conversation = Conversation.initiate([student1, student2], true)
        address_book = AddressBook::MessageableUser.new(teacher)
        known_users = address_book.known_users([student1], conversation_id: conversation.id)
        expect(known_users.map(&:id)).not_to include(student1.id)
      end
    end

    describe "sharding" do
      specs_require_sharding

      it "finds cross-shard known users" do
        enrollment = @shard1.activate { teacher_in_course(active_all: true) }
        teacher = enrollment.user
        course = enrollment.course
        student = @shard2.activate { user_factory(active_all: true) }
        student_in_course(course:, user: student, active_all: true)
        address_book = AddressBook::MessageableUser.new(teacher)
        known_users = address_book.known_users([student])
        expect(known_users.map(&:id)).to include(student.id)
      end
    end
  end

  describe "known_user" do
    it "returns the user if known" do
      teacher = teacher_in_course(active_all: true).user
      student = student_in_course(active_all: true).user
      address_book = AddressBook::MessageableUser.new(teacher)
      known_user = address_book.known_user(student)
      expect(known_user).not_to be_nil
    end

    it "returns nil if not known" do
      teacher = teacher_in_course(active_all: true).user
      other = user_factory(active_all: true)
      address_book = AddressBook::MessageableUser.new(teacher)
      known_user = address_book.known_user(other)
      expect(known_user).to be_nil
    end
  end

  describe "common_courses" do
    it "pulls the corresponding MessageableUser's common_courses" do
      enrollment = teacher_in_course(active_all: true)
      teacher = enrollment.user
      course = enrollment.course
      student = student_in_course(active_all: true).user
      address_book = AddressBook::MessageableUser.new(teacher)
      common_courses = address_book.common_courses(student)
      expect(common_courses).to eql({ course.id => ["StudentEnrollment"] })
    end
  end

  describe "common_groups" do
    it "pulls the corresponding MessageableUser's common_groups" do
      sender = user_factory(active_all: true)
      recipient = user_factory(active_all: true)
      group = group()
      group.add_user(sender, "accepted")
      group.add_user(recipient, "accepted")
      address_book = AddressBook::MessageableUser.new(sender)
      common_groups = address_book.common_groups(recipient)
      expect(common_groups).to eql({ group.id => ["Member"] })
    end
  end

  describe "known_in_context" do
    it "limits to users in context" do
      course1 = course_factory(active_all: true)
      course2 = course_factory(active_all: true)
      teacher = teacher_in_course(course: course1, active_all: true).user
      teacher_in_course(user: teacher, course: course2, active_all: true)
      student1 = student_in_course(course: course1, active_all: true).user
      student2 = student_in_course(course: course2, active_all: true).user
      address_book = AddressBook::MessageableUser.new(teacher)
      known_users = address_book.known_in_context(course1.asset_string)
      expect(known_users.map(&:id)).to include(student1.id)
      expect(known_users.map(&:id)).not_to include(student2.id)
    end

    it "caches the results for known users" do
      enrollment = teacher_in_course(active_all: true)
      teacher = enrollment.user
      course = enrollment.course
      student = student_in_course(active_all: true).user
      address_book = AddressBook::MessageableUser.new(teacher)
      address_book.known_in_context(course.asset_string)
      expect(address_book.cached?(student)).to be_truthy
    end

    it "does not cache unknown users" do
      enrollment = teacher_in_course(active_all: true)
      teacher = enrollment.user
      course1 = enrollment.course
      student = student_in_course(course: course_factory, active_all: true).user
      address_book = AddressBook::MessageableUser.new(teacher)
      address_book.known_in_context(course1.asset_string)
      expect(address_book.cached?(student)).to be_falsey
    end

    describe "sharding" do
      specs_require_sharding

      before do
        enrollment = @shard1.activate { teacher_in_course(active_all: true) }
        @teacher = enrollment.user
        @course = enrollment.course
        @student = @shard2.activate { user_factory(active_all: true) }
        student_in_course(course: @course, user: @student, active_all: true)
      end

      it "works for cross-shard courses" do
        address_book = AddressBook::MessageableUser.new(@student)
        known_users = address_book.known_in_context(@course.asset_string)
        expect(known_users.map(&:id)).to include(@teacher.id)
      end

      it "finds known cross-shard users in course" do
        address_book = AddressBook::MessageableUser.new(@teacher)
        known_users = address_book.known_in_context(@course.asset_string)
        expect(known_users.map(&:id)).to include(@student.id)
      end
    end
  end

  describe "count_in_contexts" do
    it "limits to known users in contexts" do
      enrollment = ta_in_course(active_all: true, limit_privileges_to_course_section: true)
      ta = enrollment.user
      course = enrollment.course
      section1 = course.default_section
      section2 = course.course_sections.create!
      student_in_course(section: section1, active_all: true)
      student_in_course(section: section2, active_all: true)
      # includes teacher, ta, and student in section1, but excludes student in section2
      address_book = AddressBook::MessageableUser.new(ta)
      expect(address_book.count_in_contexts([course.asset_string])).to eql({
                                                                             course.asset_string => 3
                                                                           })
    end

    it "returns count in an unassociated :context when an admin" do
      sender = account_admin_user(active_all: true)
      enrollment = student_in_course(active_all: true)
      course = enrollment.course
      address_book = AddressBook::MessageableUser.new(sender)
      expect(address_book.count_in_contexts([course.asset_string])).to eql({
                                                                             course.asset_string => 2
                                                                           })
    end
  end

  describe "search_users" do
    it "returns a paginatable collection" do
      teacher = teacher_in_course(active_all: true).user
      student_in_course(active_all: true, name: "Bob").user
      student_in_course(active_all: true, name: "Bobby").user
      address_book = AddressBook::MessageableUser.new(teacher)
      known_users = address_book.search_users(search: "Bob")
      expect(known_users).to respond_to(:paginate)
      expect(known_users.paginate(per_page: 1).size).to be(1)
    end

    it "finds matching known users" do
      teacher = teacher_in_course(active_all: true).user
      student1 = student_in_course(active_all: true, name: "Bob").user
      student2 = student_in_course(active_all: true, name: "Bobby").user
      address_book = AddressBook::MessageableUser.new(teacher)
      known_users = address_book.search_users(search: "Bob").paginate(per_page: 10)
      expect(known_users.map(&:id)).to include(student1.id)
      expect(known_users.map(&:id)).to include(student2.id)
    end

    it "excludes matching known user in optional :exclude_ids" do
      teacher = teacher_in_course(active_all: true).user
      student = student_in_course(active_all: true, name: "Bob").user
      address_book = AddressBook::MessageableUser.new(teacher)
      known_users = address_book.search_users(search: "Bob", exclude_ids: [student.id]).paginate(per_page: 10)
      expect(known_users.map(&:id)).not_to include(student.id)
    end

    it "restricts to matching known users in optional :context" do
      course1 = course_factory(active_all: true)
      course2 = course_factory(active_all: true)
      teacher = teacher_in_course(course: course1, active_all: true).user
      teacher_in_course(user: teacher, course: course2, active_all: true)
      student1 = student_in_course(course: course1, active_all: true, name: "Bob").user
      student2 = student_in_course(course: course2, active_all: true, name: "Bobby").user
      address_book = AddressBook::MessageableUser.new(teacher)
      known_users = address_book.search_users(search: "Bob", context: course1.asset_string).paginate(per_page: 10)
      expect(known_users.map(&:id)).to include(student1.id)
      expect(known_users.map(&:id)).not_to include(student2.id)
    end

    it "finds users in an unassociated :context when an admin" do
      admin = account_admin_user(active_all: true)
      enrollment = student_in_course(active_all: true, name: "Bob")
      student = enrollment.user
      course = enrollment.course
      address_book = AddressBook::MessageableUser.new(admin)
      known_users = address_book.search_users(search: "Bob", context: course.asset_string).paginate(per_page: 10)
      expect(known_users.map(&:id)).to include(student.id)
    end

    it "excludes users in an admined :context when also participating" do
      admin = account_admin_user(active_all: true)
      enrollment = student_in_course(active_all: true, name: "Bob")
      student = enrollment.user
      course = enrollment.course
      section = course.course_sections.create!
      teacher_in_course(user: admin, course:, active_all: true, section:, limit_privileges_to_course_section: true)
      address_book = AddressBook::MessageableUser.new(admin)
      known_users = address_book.search_users(search: "Bob", context: course.asset_string).paginate(per_page: 10)
      expect(known_users.map(&:id)).not_to include(student.id)
    end

    it "excludes 'weak' users without :weak_checks" do
      teacher = teacher_in_course(active_all: true).user
      student = student_in_course(user_state: "creation_pending", enrollment_state: "invited", name: "Bob").user
      address_book = AddressBook::MessageableUser.new(teacher)
      known_users = address_book.search_users(search: "Bob").paginate(per_page: 10)
      expect(known_users.map(&:id)).not_to include(student.id)
    end

    it "excludes 'weak' enrollments without :weak_checks" do
      teacher = teacher_in_course(active_all: true).user
      student = student_in_course(active_user: true, enrollment_state: "creation_pending", name: "Bob").user
      address_book = AddressBook::MessageableUser.new(teacher)
      known_users = address_book.search_users(search: "Bob").paginate(per_page: 10)
      expect(known_users.map(&:id)).not_to include(student.id)
    end

    it "expands to include 'weak' users and 'weak' enrollments when :weak_checks" do
      teacher = teacher_in_course(active_all: true).user
      student = student_in_course(active_user: true, enrollment_state: "creation_pending", name: "Bob").user
      address_book = AddressBook::MessageableUser.new(teacher)
      known_users = address_book.search_users(search: "Bob", weak_checks: true).paginate(per_page: 10)
      expect(known_users.map(&:id)).to include(student.id)
    end

    it "caches the results for known users when a page is materialized" do
      teacher = teacher_in_course(active_all: true).user
      student = student_in_course(active_all: true, name: "Bob").user
      address_book = AddressBook::MessageableUser.new(teacher)
      collection = address_book.search_users(search: "Bob")
      expect(address_book.cached?(student)).to be_falsey
      collection.paginate(per_page: 10)
      expect(address_book.cached?(student)).to be_truthy
    end
  end

  describe "preload_users" do
    it "avoids db query with rails cache" do
      teacher = teacher_in_course(active_all: true).user
      student = student_in_course(active_all: true, name: "Bob").user
      expect(Rails.cache).to receive(:fetch)
        .with(match(/address_book_preload/))
        .and_return(MessageableUser.where(id: student).to_a)
      expect(teacher).not_to receive(:load_messageable_users)
      AddressBook::MessageableUser.new(teacher).preload_users([student])
    end

    it "caches all provided users" do
      teacher = teacher_in_course(active_all: true).user
      student = student_in_course(active_all: true, name: "Bob").user
      address_book = AddressBook::MessageableUser.new(teacher)
      address_book.preload_users([student])
      expect(address_book.cached?(student)).to be_truthy
    end
  end

  describe "sections" do
    it "returns course sections known to sender" do
      enrollment = ta_in_course(active_all: true)
      ta = enrollment.user
      course = enrollment.course
      section1 = course.default_section
      section2 = course.course_sections.create!
      address_book = AddressBook::MessageableUser.new(ta)
      sections = address_book.sections
      expect(sections.map(&:id)).to include(section1.id)
      expect(sections.map(&:id)).to include(section2.id)
    end
  end

  describe "groups" do
    it "returns groups known to sender" do
      membership = group_with_user(active_all: true)
      user = membership.user
      group1 = membership.group
      group2 = group(active_all: true)
      address_book = AddressBook::MessageableUser.new(user)
      groups = address_book.groups
      expect(groups.map(&:id)).to include(group1.id)
      expect(groups.map(&:id)).not_to include(group2.id)
    end
  end
end
