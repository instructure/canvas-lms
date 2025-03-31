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

describe Api::V1::AssignmentOverride do
  subject { test_class.new }

  let(:test_class) do
    Class.new do
      include Api::V1::AssignmentOverride
      attr_accessor :current_user

      def session
        {}
      end
    end
  end

  describe "#interpret_assignment_override_data" do
    it "works even with nil date fields" do
      override = { student_ids: [1],
                   due_at: nil,
                   unlock_at: nil,
                   lock_at: nil }
      allow(subject).to receive(:api_find_all).and_return []
      assignment = double(context: double(all_students: []))
      result = subject.interpret_assignment_override_data(assignment, override, "ADHOC")
      expect(result.first[:due_at]).to be_nil
      expect(result.first[:unlock_at]).to be_nil
      expect(result.first[:lock_at]).to be_nil
    end

    context "sharding" do
      specs_require_sharding

      it "works even with global ids for students" do
        course_with_student

        # Mock sharding data
        @shard1.activate { @user = User.create!(name: "Shardy McShardface") }
        @course.enroll_student @user

        override = { student_ids: [@student.global_id] }

        allow(subject).to receive(:api_find_all).and_return [@student]
        assignment = double(context: double(all_students: []))
        result = subject.interpret_assignment_override_data(assignment, override, "ADHOC")
        expect(result[1]).to be_nil
        expect(result.first[:students]).to eq [@student]
      end
    end

    context "group overrides" do
      describe "non collaborative group overrides" do
        before :once do
          course_with_teacher(active_all: true)
          @course.account.enable_feature!(:assign_to_differentiation_tags)
          @course.account.settings[:allow_assign_to_differentiation_tags] = { value: true }
          @course.account.save!
          @course.account.reload

          @group_category = @course.group_categories.create!(name: "Diff Tag Group Set", non_collaborative: true)
          @group_category.create_groups(2)
          @differentiation_tag_group_1 = @group_category.groups.first
          @differentiation_tag_group_2 = @group_category.groups.second
        end

        def returns_correct_hash(assignment, override)
          allow(subject).to receive(:api_find_all).and_return [@differentiation_tag_group_1]
          result = subject.interpret_assignment_override_data(assignment, override, nil)
          expect(result.first[:group][:id]).to eq @differentiation_tag_group_1.id
        end

        it "returns the correct hash for wiki page override" do
          wiki_page = @course.wiki_pages.create!(title: "Wiki Page 1")
          override = { group_id: @differentiation_tag_group_1.id, wiki_page_id: wiki_page.id }
          returns_correct_hash(wiki_page, override)
        end

        it "returns the correct hash for quiz override" do
          quiz = @course.quizzes.create!(title: "Quiz 1")
          override = { group_id: @differentiation_tag_group_1.id, quiz_id: quiz.id }
          returns_correct_hash(quiz, override)
        end

        it "returns the correct hash for discussion topic override" do
          discussion_topic = @course.discussion_topics.create!(title: "Discussion Topic 1")
          override = { group_id: @differentiation_tag_group_1.id, discussion_topic_id: discussion_topic.id }
          returns_correct_hash(discussion_topic, override)
        end

        it "returns the correct hash for assignment override" do
          assignment = @course.assignments.create!(title: "Assignment 1")
          override = { group_id: @differentiation_tag_group_1.id, assignment_id: assignment.id }
          returns_correct_hash(assignment, override)
        end

        it "returns error if account setting is disabled" do
          @course.account.settings[:allow_assign_to_differentiation_tags] = { value: false }
          @course.account.save!
          @course.account.reload

          assignment = @course.assignments.create!(title: "Wiki Page 1")
          override = { group_id: @differentiation_tag_group_1.id, assignment_id: assignment.id }
          result = subject.interpret_assignment_override_data(assignment, override, nil)
          expect(result).to eq [{}, ["group_id is not valid"]]
        end
      end

      describe "collaborative group overrides" do
        before :once do
          course_with_teacher(active_all: true)

          @group_category = @course.group_categories.create!(name: "Collaborative Group Set", non_collaborative: false)
          @group_category.create_groups(2)
          @collaborative_group_1 = @group_category.groups.first
          @collaborative_group_1 = @group_category.groups.second
        end

        def returns_correct_hash(assignment, override)
          allow(subject).to receive(:api_find_all).and_return [@collaborative_group_1]
          result = subject.interpret_assignment_override_data(assignment, override, nil)
          expect(result.first[:group][:id]).to eq @collaborative_group_1.id
        end

        it "returns the correct hash for group discussion topic" do
          discussion_topic = @course.discussion_topics.create!(title: "Discussion Topic 1", group_category_id: @group_category.id)
          override = { group_id: @collaborative_group_1.id, discussion_topic_id: discussion_topic.id }
          returns_correct_hash(discussion_topic, override)
        end

        it "returns the correct hash for group assignment" do
          assignment = @course.assignments.create!(title: "Assignment 1", group_category_id: @group_category.id)
          override = { group_id: @collaborative_group_1.id, assignment_id: assignment.id }
          returns_correct_hash(assignment, override)
        end

        it "returns error if group is not in the group category" do
          group_cat = @course.group_categories.create!(name: "Another Group Category", non_collaborative: false)
          collab_group = group_cat.groups.create!(name: "another collab group", non_collaborative: false, context: @course)
          assignment = @course.assignments.create!(title: "Assignment 1", group_category_id: @group_category.id)
          override = { group_id: collab_group.id, assignment_id: assignment.id }
          allow(subject).to receive(:api_find_all).and_return [collab_group]
          result = subject.interpret_assignment_override_data(assignment, override, nil)
          expect(result).to eq [{}, ["group_id is not valid"]]
        end

        it "allows non collaborative group to be assigned to group assignment" do
          @course.account.enable_feature!(:assign_to_differentiation_tags)
          @course.account.settings[:allow_assign_to_differentiation_tags] = { value: true }
          @course.account.save!
          @course.account.reload

          @group_category = @course.group_categories.create!(name: "Diff Tag Group Set", non_collaborative: true)
          @group_category.create_groups(1)
          @differentiation_tag_group_1 = @group_category.groups.first
          assignment = @course.assignments.create!(title: "Assignment 1", group_category_id: @group_category.id)
          override = { group_id: @differentiation_tag_group_1.id, assignment_id: assignment.id }
          allow(subject).to receive(:api_find_all).and_return [@differentiation_tag_group_1]
          result = subject.interpret_assignment_override_data(assignment, override, nil)
          expect(result.first[:group][:id]).to eq @differentiation_tag_group_1.id
        end
      end
    end
  end

  describe "interpret_batch_assignment_overrides_data" do
    subject do
      subj = test_class.new
      subj.current_user = @teacher
      subj
    end

    before(:once) do
      course_with_teacher(active_all: true)
      @a = assignment_model(course: @course, group_category: "category1")
      @b = assignment_model(course: @course, group_category: "category2")
      @a1, @a2 = Array.new(2) do
        create_section_override_for_assignment @a, course_section: @course.course_sections.create!
      end
      @b1, @b2, @b3 = Array.new(2) do
        create_section_override_for_assignment @b, course_section: @course.course_sections.create!
      end
    end

    it "has error if no updates requested" do
      _data, errors = subject.interpret_batch_assignment_overrides_data(@course, [], true)
      expect(errors[0]).to eq "no assignment override data present"
    end

    it "has error if assignments are malformed" do
      _data, errors = subject.interpret_batch_assignment_overrides_data(
        @course,
        { foo: @a.id, bar: @b.id }.with_indifferent_access,
        true
      )
      expect(errors[0]).to match(/must specify an array/)
    end

    it "fails if list of overrides is malformed" do
      _data, errors = subject.interpret_batch_assignment_overrides_data(@course,
                                                                        [
                                                                          { assignment_id: @a.id, override: @a1.id }.with_indifferent_access,
                                                                          { title: "foo" }.with_indifferent_access
                                                                        ],
                                                                        true)
      expect(errors[0]).to eq ["must specify an override id"]
      expect(errors[1]).to eq ["must specify an assignment id", "must specify an override id"]
    end

    it "fails if individual overrides are malformed" do
      _data, errors = subject.interpret_batch_assignment_overrides_data(@course,
                                                                        [
                                                                          { assignment_id: @a.id, id: @a1.id, due_at: "foo" }.with_indifferent_access
                                                                        ],
                                                                        true)
      expect(errors[0]).to eq ['invalid due_at "foo"']
    end

    it "fails if assignment not found" do
      @a.destroy!
      _data, errors = subject.interpret_batch_assignment_overrides_data(@course,
                                                                        [
                                                                          { assignment_id: @a.id, id: @a1.id, title: "foo" }.with_indifferent_access
                                                                        ],
                                                                        true)
      expect(errors[0]).to eq ["assignment not found"]
    end

    it "fails if override not found" do
      @a1.destroy!
      _data, errors = subject.interpret_batch_assignment_overrides_data(@course,
                                                                        [
                                                                          { assignment_id: @a.id, id: @a1.id, title: "foo" }.with_indifferent_access
                                                                        ],
                                                                        true)
      expect(errors[0]).to eq ["override not found"]
    end

    it "succeeds if formatted correctly" do
      new_date = Time.zone.now.tomorrow
      data, errors = subject.interpret_batch_assignment_overrides_data(@course,
                                                                       [
                                                                         { assignment_id: @a.id, id: @a1.id, due_at: new_date.to_s }.with_indifferent_access,
                                                                         { assignment_id: @a.id, id: @a2.id, lock_at: new_date.to_s }.with_indifferent_access,
                                                                         { assignment_id: @b.id, id: @b2.id, unlock_at: new_date.to_s }.with_indifferent_access
                                                                       ],
                                                                       true)
      expect(errors).to be_blank
      expect(data[0][:due_at].to_date).to eq new_date.to_date
      expect(data[1][:lock_at].to_date).to eq new_date.to_date
      expect(data[2][:unlock_at].to_date).to eq new_date.to_date
    end
  end

  describe "overrides retrieved for teacher" do
    before :once do
      course_model
      @override = assignment_override_model
    end

    context "in restricted course section" do
      before do
        2.times { @course.course_sections.create! }
        @section_invisible = @course.active_course_sections[2]
        @section_visible = @course.active_course_sections.second

        @student_invisible = student_in_section(@section_invisible)
        @student_visible = student_in_section(@section_visible, user: user_factory)
        @teacher = teacher_in_section(@section_visible, user: user_factory)

        enrollment = @teacher.enrollments.first
        enrollment.limit_privileges_to_course_section = true
        enrollment.save!
      end

      describe "#invisble_users_and_overrides_for_user" do
        before do
          @override.set_type = "ADHOC"
          @override_student = @override.assignment_override_students.build
          @override_student.user = @student_visible
          @override_student.save!
        end

        it "returns the invisible_student's id in first param" do
          @override_student = @override.assignment_override_students.build
          @override_student.user = @student_invisible
          @override_student.save!

          invisible_ids, _ = subject.invisible_users_and_overrides_for_user(
            @course, @teacher, @assignment.assignment_overrides.active
          )
          expect(invisible_ids).to include(@student_invisible.id)
        end

        it "returns the invisible_override in the second param" do
          override_invisible = @override.assignment.assignment_overrides.create
          override_invisible.set_type = "ADHOC"
          override_student = override_invisible.assignment_override_students.build
          override_student.user = @student_invisible
          override_student.save!

          _, invisible_overrides = subject.invisible_users_and_overrides_for_user(
            @course, @teacher, @assignment.assignment_overrides.active
          )
          expect(invisible_overrides.first).to eq override_invisible.id
        end
      end
    end

    context "with no restrictions" do
      before do
        2.times { @course.course_sections.create! }
        @section_invisible = @course.active_course_sections[2]
        @section_visible = @course.active_course_sections.second

        @student_invisible = student_in_section(@section_invisible)
        @student_visible = student_in_section(@section_visible, user: user_factory)
      end

      describe "#invisble_users_and_overrides_for_user" do
        before do
          @override.set_type = "ADHOC"
          @override_student = @override.assignment_override_students.build
          @override_student.user = @student_visible
          @override_student.save!
        end

        it "does not return the invisible student's param in first param" do
          @override_student = @override.assignment_override_students.build
          @override_student.user = @student_invisible
          @override_student.save!

          invisible_ids, _ = subject.invisible_users_and_overrides_for_user(
            @course, @teacher, @assignment.assignment_overrides.active
          )
          expect(invisible_ids).to_not include(@student_invisible.id)
        end

        it "returns no override ids in the second param" do
          override_invisible = @override.assignment.assignment_overrides.create
          override_invisible.set_type = "ADHOC"
          override_student = override_invisible.assignment_override_students.build
          override_student.user = @student_invisible
          override_student.save!

          _, invisible_overrides = subject.invisible_users_and_overrides_for_user(
            @course, @teacher, @assignment.assignment_overrides.active
          )
          expect(invisible_overrides).to be_empty
        end
      end
    end
  end

  describe "#assignment_overrides_json" do
    subject(:assignment_overrides_json) { test_class.new.assignment_overrides_json([@override], @student) }

    before :once do
      course_model
      student_in_course(active_all: true)
      @quiz = quiz_model course: @course
      @override = create_section_override_for_assignment(@quiz)
    end

    it "delegates to AssignmentOverride.visible_enrollments_for" do
      expect(AssignmentOverride).to receive(:visible_enrollments_for).once.and_return(Enrollment.none)
      assignment_overrides_json
    end

    context "group module overrides" do
      before do
        @group = @course.groups.create!(name: "Group 1")
        @context_module = ContextModule.create!(context: @course, name: "Module 1")
        @group_override = AssignmentOverride.create!(
          set_type: "Group",
          set_id: @course.groups.first.id,
          context_module_id: @context_module.id
        )
        @group_override.save!
      end

      it "correctly returns group overrides" do
        expected_result = {
          "id" => @group_override.id,
          "context_module_id" => @context_module.id,
          "group_id" => @group.id,
          "group_category_id" => @group.group_category_id,
          "non_collaborative" => false,
          "title" => @group.name,
          "unassign_item" => false
        }
        expect(test_class.new.assignment_overrides_json([@group_override], @teacher).first).to eq expected_result
      end
    end

    context "differentiaiton tag overrides" do
      before do
        @course.account.enable_feature!(:assign_to_differentiation_tags)
        @course.account.settings[:allow_assign_to_differentiation_tags] = { value: true }
        @course.account.save!
        @course.account.reload

        @group_category = @course.group_categories.create!(name: "Diff Tag Group Set", non_collaborative: true)
        @group_category.create_groups(2)
        @differentiation_tag_group_1 = @group_category.groups.first
        @differentiation_tag_group_2 = @group_category.groups.second
      end

      it "correctly includes differentiation tag overrides for an assignment" do
        @assignment = @course.assignments.create!(title: "Assignment 1")
        @override = @assignment.assignment_overrides.create!(set_type: "Group", set_id: @differentiation_tag_group_1.id)
        expected_result = {
          "id" => @override.id,
          "assignment_id" => @assignment.id,
          "group_id" => @differentiation_tag_group_1.id,
          "group_category_id" => @group_category.id,
          "non_collaborative" => true,
          "title" => @differentiation_tag_group_1.name,
          "unassign_item" => false
        }
        test = test_class.new
        test.current_user = @teacher
        expect(test.assignment_overrides_json([@override], @teacher).first).to eq expected_result
      end

      it "removes the 'title' of the override for users without differentiation tag read permissions" do
        @assignment = @course.assignments.create!(title: "Assignment 1")
        @override = @assignment.assignment_overrides.create!(set_type: "Group", set_id: @differentiation_tag_group_1.id)
        expected_result = {
          "id" => @override.id,
          "assignment_id" => @assignment.id,
          "group_id" => @differentiation_tag_group_1.id,
          "group_category_id" => @group_category.id,
          "non_collaborative" => true,
          "unassign_item" => false
        }
        test = test_class.new
        test.current_user = @student
        expect(test.assignment_overrides_json([@override], @student).first).to eq expected_result
      end
    end

    context "sharding" do
      specs_require_sharding

      it "does not break when running for a teacher on a different shard while preloading adhoc overrides" do
        @shard1.activate do
          account = Account.create!

          @student = User.create!
          @teacher = User.create!

          @cs_course = Course.create!(account:)
          @cs_course.enroll_user(@student, "StudentEnrollment", enrollment_state: "active")
          @cs_course.enroll_user(@teacher, "TeacherEnrollment", enrollment_state: "active")

          @cs_assignment = @cs_course.assignments.create name: "assignment1"

          @adhoc_override = assignment_override_model(assignment: @cs_assignment)
          @adhoc_override.assignment_override_students.create!(user: @student)
        end

        expect(test_class.new.assignment_overrides_json([@override], @teacher).first[:student_ids]).to eq [@student.id]
      end
    end
  end

  describe "perform_batch_update_assignment_overrides" do
    before :once do
      course_with_teacher(active_all: true)
      assignment_model(course: @course)
    end

    it "touches the assignment" do
      expect(@assignment).to receive(:touch)
      subject.perform_batch_update_assignment_overrides(@assignment, {
                                                          overrides_to_create: [],
                                                          overrides_to_update: [],
                                                          overrides_to_delete: [],
                                                          override_errors: []
                                                        })
    end
  end
end
