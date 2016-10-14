require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper.rb')

describe AddressBook::MessageableUser do
  describe "known_users" do
    it "restricts to provided users" do
      teacher = teacher_in_course(active_all: true).user
      student1 = student_in_course(active_all: true).user
      student2 = student_in_course(active_all: true)
      address_book = AddressBook::MessageableUser.new(teacher)
      known_users = address_book.known_users([student1])
      expect(known_users.map(&:id)).to include(student1.id)
      expect(known_users.map(&:id)).not_to include(student2.id)
    end

    it "includes only known users" do
      teacher = teacher_in_course(active_all: true).user
      student1 = student_in_course(active_all: true).user
      student2 = student_in_course(course: course(), active_all: true)
      address_book = AddressBook::MessageableUser.new(teacher)
      known_users = address_book.known_users([student1, student2])
      expect(known_users.map(&:id)).to include(student1.id)
      expect(known_users.map(&:id)).not_to include(student2.id)
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
      student = student_in_course(course: course(), active_all: true).user
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
      teacher.expects(:load_messageable_users).
        with([student3], anything).
        returns(MessageableUser.where(id: student3).to_a)
      known_users = address_book.known_users([student2, student3])
      expect(known_users.map(&:id)).to include(student2.id)
      expect(known_users.map(&:id)).to include(student3.id)
    end

    describe "with optional :include_context" do
      before :each do
        @admin = account_admin_user()
        @student = student_in_course(active_all: true).user
        @address_book = AddressBook::MessageableUser.new(@admin)
      end

      it "skips course roles in unshared courses when absent" do
        course = @student.enrollments.first.course
        known_users = @address_book.known_users([@student])
        expect(known_users.map(&:id)).to include(@student.id)
        expect(@address_book.common_courses(@student)).not_to include(course.id)
      end

      it "skips group memberships in unshared groups when absent" do
        group = group()
        group.add_user(@student, 'accepted')
        known_users = @address_book.known_users([@student])
        expect(known_users.map(&:id)).to include(@student.id)
        expect(@address_book.common_groups(@student)).not_to include(group.id)
      end

      it "includes otherwise skipped course role in common courses when course specified" do
        course = @student.enrollments.first.course
        @address_book.known_users([@student], include_context: course)
        expect(@address_book.common_courses(@student)).to include(course.id)
      end

      it "includes otherwise skipped groups memberships in common groups when group specified" do
        group = group()
        group.add_user(@student, 'accepted')
        @address_book.known_users([@student], include_context: group)
        expect(@address_book.common_groups(@student)).to include(group.id)
      end

      it "no effect if no role in the course exists" do
        course = course(active_all: true)
        @address_book.known_users([@student], include_context: course)
        expect(@address_book.common_courses(@student)).not_to include(course.id)
      end

      it "no effect if no membership in the group exists" do
        group = group()
        @address_book.known_users([@student], include_context: group)
        expect(@address_book.common_courses(@student)).not_to include(group.id)
      end
    end

    describe "with optional :conversation_id" do
      it "treats unknown users in that conversation as known" do
        course1 = course(active_all: true)
        course2 = course(active_all: true)
        teacher = teacher_in_course(course: course1, active_all: true).user
        student = student_in_course(course: course2, active_all: true).user
        conversation = Conversation.initiate([teacher, student], true)
        address_book = AddressBook::MessageableUser.new(teacher)
        known_users = address_book.known_users([student], conversation_id: conversation.id)
        expect(known_users.map(&:id)).to include(student.id)
      end

      it "ignores if sender is not a participant in the conversation" do
        course1 = course(active_all: true)
        course2 = course(active_all: true)
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
        enrollment = @shard1.activate{ teacher_in_course(active_all: true) }
        teacher = enrollment.user
        course = enrollment.course
        student = @shard2.activate{ user(active_all: true) }
        student_in_course(course: course, user: student, active_all: true)
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
      other = user(active_all: true)
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
      expect(common_courses).to eql({ course.id => ['StudentEnrollment'] })
    end
  end

  describe "common_groups" do
    it "pulls the corresponding MessageableUser's common_groups" do
      sender = user(active_all: true)
      recipient = user(active_all: true)
      group = group()
      group.add_user(sender, 'accepted')
      group.add_user(recipient, 'accepted')
      address_book = AddressBook::MessageableUser.new(sender)
      common_groups = address_book.common_groups(recipient)
      expect(common_groups).to eql({ group.id => ['Member'] })
    end
  end

  describe "known_in_context" do
    it "limits to users in context" do
      course1 = course(active_all: true)
      course2 = course(active_all: true)
      teacher = teacher_in_course(course: course1, active_all: true).user
      teacher_in_course(user: teacher, course: course2, active_all: true)
      student1 = student_in_course(course: course1, active_all: true).user
      student2 = student_in_course(course: course2, active_all: true).user
      address_book = AddressBook::MessageableUser.new(teacher)
      known_users = address_book.known_in_context(course1.asset_string)
      expect(known_users.map(&:id)).to include(student1.id)
      expect(known_users.map(&:id)).not_to include(student2.id)
    end

    describe ":is_admin flag" do
      before :each do
        admin = account_admin_user(active_all: true)
        enrollment = student_in_course(active_all: true)
        @student = enrollment.user
        @course = enrollment.course
        @address_book = AddressBook::MessageableUser.new(admin)
      end

      it "ignores unassociated courses without is_admin flag" do
        known_users = @address_book.known_in_context(@course.asset_string)
        expect(known_users.map(&:id)).not_to include(@student.id)
      end

      it "finds user in an unassociated course with is_admin flag" do
        known_users = @address_book.known_in_context(@course.asset_string, is_admin: true)
        expect(known_users.map(&:id)).to include(@student.id)
      end
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
      student = student_in_course(course: course(), active_all: true).user
      address_book = AddressBook::MessageableUser.new(teacher)
      address_book.known_in_context(course1.asset_string)
      expect(address_book.cached?(student)).to be_falsey
    end

    describe "sharding" do
      specs_require_sharding

      before :each do
        enrollment = @shard1.activate{ teacher_in_course(active_all: true) }
        @teacher = enrollment.user
        @course = enrollment.course
        @student = @shard2.activate{ user(active_all: true) }
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

  describe "count_in_context" do
    it "limits to known users in context" do
      enrollment = ta_in_course(active_all: true, limit_privileges_to_course_section: true)
      ta = enrollment.user
      course = enrollment.course
      section1 = course.default_section
      section2 = course.course_sections.create!
      student_in_course(section: section1, active_all: true).user
      student_in_course(section: section2, active_all: true).user
      # includes teacher, ta, and student in section1, but excludes student in section2
      address_book = AddressBook::MessageableUser.new(ta)
      expect(address_book.count_in_context(course.asset_string)).to eql(3)
    end
  end

  describe "search_users" do
    it "returns a paginatable collection" do
      teacher = teacher_in_course(active_all: true).user
      student_in_course(active_all: true, name: 'Bob').user
      student_in_course(active_all: true, name: 'Bobby').user
      address_book = AddressBook::MessageableUser.new(teacher)
      known_users = address_book.search_users(search: 'Bob')
      expect(known_users).to respond_to(:paginate)
      expect(known_users.paginate(per_page: 1).size).to eql(1)
    end

    it "finds matching known users" do
      teacher = teacher_in_course(active_all: true).user
      student1 = student_in_course(active_all: true, name: 'Bob').user
      student2 = student_in_course(active_all: true, name: 'Bobby').user
      address_book = AddressBook::MessageableUser.new(teacher)
      known_users = address_book.search_users(search: 'Bob').paginate(per_page: 10)
      expect(known_users.map(&:id)).to include(student1.id)
      expect(known_users.map(&:id)).to include(student2.id)
    end

    it "excludes matching known user in optional :exclude_ids" do
      teacher = teacher_in_course(active_all: true).user
      student = student_in_course(active_all: true, name: 'Bob').user
      address_book = AddressBook::MessageableUser.new(teacher)
      known_users = address_book.search_users(search: 'Bob', exclude_ids: [student.id]).paginate(per_page: 10)
      expect(known_users.map(&:id)).not_to include(student.id)
    end

    it "restricts to matching known users in optional :context" do
      course1 = course(active_all: true)
      course2 = course(active_all: true)
      teacher = teacher_in_course(course: course1, active_all: true).user
      teacher_in_course(user: teacher, course: course2, active_all: true)
      student1 = student_in_course(course: course1, active_all: true, name: 'Bob').user
      student2 = student_in_course(course: course2, active_all: true, name: 'Bobby').user
      address_book = AddressBook::MessageableUser.new(teacher)
      known_users = address_book.search_users(search: 'Bob', context: course1.asset_string).paginate(per_page: 10)
      expect(known_users.map(&:id)).to include(student1.id)
      expect(known_users.map(&:id)).not_to include(student2.id)
    end

    it "finds users in an unassociated :context when :is_admin" do
      admin = account_admin_user(active_all: true)
      enrollment = student_in_course(active_all: true, name: 'Bob')
      student = enrollment.user
      course = enrollment.course
      address_book = AddressBook::MessageableUser.new(admin)
      known_users = address_book.search_users(search: 'Bob', context: course.asset_string, is_admin: true).paginate(per_page: 10)
      expect(known_users.map(&:id)).to include(student.id)
    end

    it "excludes 'weak' users without :weak_checks" do
      teacher = teacher_in_course(active_all: true).user
      student = student_in_course(user_state: 'creation_pending', enrollment_state: 'invited', name: 'Bob').user
      address_book = AddressBook::MessageableUser.new(teacher)
      known_users = address_book.search_users(search: 'Bob').paginate(per_page: 10)
      expect(known_users.map(&:id)).not_to include(student.id)
    end

    it "excludes 'weak' enrollments without :weak_checks" do
      teacher = teacher_in_course(active_all: true).user
      student = student_in_course(active_user: true, enrollment_state: 'creation_pending', name: 'Bob').user
      address_book = AddressBook::MessageableUser.new(teacher)
      known_users = address_book.search_users(search: 'Bob').paginate(per_page: 10)
      expect(known_users.map(&:id)).not_to include(student.id)
    end

    it "expands to include 'weak' users and 'weak' enrollments when :weak_checks" do
      teacher = teacher_in_course(active_all: true).user
      student = student_in_course(active_user: true, enrollment_state: 'creation_pending', name: 'Bob').user
      address_book = AddressBook::MessageableUser.new(teacher)
      known_users = address_book.search_users(search: 'Bob', weak_checks: true).paginate(per_page: 10)
      expect(known_users.map(&:id)).to include(student.id)
    end

    it "caches the results for known users when a page is materialized" do
      teacher = teacher_in_course(active_all: true).user
      student = student_in_course(active_all: true, name: 'Bob').user
      address_book = AddressBook::MessageableUser.new(teacher)
      collection = address_book.search_users(search: 'Bob')
      expect(address_book.cached?(student)).to be_falsey
      collection.paginate(per_page: 10)
      expect(address_book.cached?(student)).to be_truthy
    end
  end

  describe "preload_users" do
    it "avoids db query with rails cache" do
      teacher = teacher_in_course(active_all: true).user
      student = student_in_course(active_all: true, name: 'Bob').user
      Rails.cache.expects(:fetch).
        with(regexp_matches(/address_book_preload/)).
        returns(MessageableUser.where(id: student).to_a)
      teacher.expects(:load_messageable_users).never
      AddressBook::MessageableUser.new(teacher).preload_users([student])
    end

    it "caches all provided users" do
      teacher = teacher_in_course(active_all: true).user
      student = student_in_course(active_all: true, name: 'Bob').user
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
