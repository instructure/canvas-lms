# frozen_string_literal: true

#
# Copyright (C) 2012 - present Instructure, Inc.
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

shared_examples_for "learning object with due dates" do
  # let(:overridable) - an Assignment or Quiz
  # let(:overridable_type) - :assignment or :quiz

  let(:course) { overridable.context }
  let(:override) { assignment_override_model(overridable_type => overridable) }

  describe "#teacher_due_date_for_display" do
    it "returns nil when differentiated with no due dates" do
      student_in_course(course:)
      overridable.update!(due_at: nil, only_visible_to_overrides: true)
      override.update!(set_type: "ADHOC")
      override.assignment_override_students.create(user: @student)

      expect(overridable.teacher_due_date_for_display(@student)).to be_nil
    end
  end

  describe "#all_dates_visible_to" do
    before do
      @section2 = course.course_sections.create!(name: "Summer session")
      override2 = assignment_override_model(overridable_type => overridable)
      override2.set = @section2
      override2.override_due_at(18.days.from_now)
      override2.save!
    end

    context "as a teacher" do
      it "only returns active overrides" do
        override.delete
        overridable.reload
        expect(overridable.all_dates_visible_to(@teacher).size).to eq 2
      end

      it "doesn't duplicate adhoc overrides in list" do
        override.set_type = "ADHOC"
        2.times { override.assignment_override_students.create(user: student_in_section(course.active_course_sections.first)) }
        override.title = nil
        override.save!

        dates_hash = overridable.dates_hash_visible_to(@teacher)
        expect(dates_hash.size).to eq 3
        expect(dates_hash.pluck(:title)).to eq [nil, "Summer session", "2 students"]
      end
    end

    context "as a student" do
      it "only returns active overrides" do
        course_with_student({ course:, active_all: true })
        override.delete
        expect(overridable.all_dates_visible_to(@student).size).to eq 1
      end
    end

    context "as an observer with students" do
      before do
        course_with_student({ course:, active_all: true })
        course_with_observer({ course:, active_all: true })
        course.enroll_user(@observer, "ObserverEnrollment", { associated_user_id: @student.id })
      end

      it "only returns active overrides for a single student" do
        override.delete
        expect(overridable.all_dates_visible_to(@observer).size).to eq 1
      end

      it "returns all active overrides for 2+ students" do
        student2 = student_in_section(@section2, { active_all: true })
        course.enroll_user(@observer, "ObserverEnrollment", { allow_multiple_enrollments: true, associated_user_id: student2.id })
        override.delete
        expect(overridable.all_dates_visible_to(@observer).size).to eq 2
      end
    end

    context "as an observer without students" do
      before do
        course_with_observer({ course:, active_all: true })
        course.enroll_user(@observer, "ObserverEnrollment")
        override.delete
      end

      it "returns a date with DA" do
        expect(overridable.all_dates_visible_to(@observer).size).to eq 1
      end
    end

    it "returns each override represented using its as_hash method" do
      all_dates = overridable.all_dates_visible_to(@user)
      overridable.active_assignment_overrides.map(&:as_hash).each do |o|
        expect(all_dates).to include o
      end
    end

    it "includes the overridable as a hash" do
      all_dates = overridable.all_dates_visible_to(@user)
      last_hash = all_dates.last
      overridable_hash =
        overridable.without_overrides.due_date_hash.merge(base: true)
      overridable_hash.each do |k, v|
        expect(last_hash[k]).to eq v
      end
    end
  end

  describe "#dates_hash_visible_to" do
    before do
      override.set = course.default_section
      override.override_due_at(7.days.from_now)
      override.save!

      @section2 = course.course_sections.create!(name: "Summer session")
    end

    it "only returns active overrides" do
      expect(overridable.dates_hash_visible_to(@teacher).size).to eq 2
    end

    it "includes the original date as a hash" do
      dates_hash = overridable.dates_hash_visible_to(@teacher)
      expect(dates_hash.size).to eq 2

      dates_hash.sort_by! { |d| d[:title].to_s }
      expect(dates_hash[0][:title]).to be_nil
      expect(dates_hash[1][:title]).to eq "value for name"
    end

    it "not include original dates if all sections are overriden" do
      override2 = assignment_override_model(overridable_type => overridable)
      override2.set = @section2
      override2.override_due_at(8.days.from_now)
      override2.save!

      dates_hash = overridable.dates_hash_visible_to(@teacher)
      expect(dates_hash.size).to eq 2

      dates_hash.sort_by! { |d| d[:title] }
      expect(dates_hash[0][:title]).to eq "Summer session"
      expect(dates_hash[1][:title]).to eq "value for name"
    end
  end

  describe "due_date_hash" do
    it "returns the due at, lock_at, unlock_at, all day, and all day fields" do
      due = 5.days.from_now
      due_params = { due_at: due, lock_at: due, unlock_at: due }
      a = overridable.class.new(due_params)
      if a.is_a?(Quizzes::Quiz)
        a.assignment = Assignment.new(due_params)
      end
      expect(a.due_date_hash[:due_at]).to eq due
      expect(a.due_date_hash[:lock_at]).to eq due
      expect(a.due_date_hash[:unlock_at]).to eq due
      expect(a.due_date_hash[:all_day]).to be false
      expect(a.due_date_hash[:all_day_date]).to be_nil
    end
  end

  describe "observed_student_due_dates" do
    it "returns a list of overridden due date hashes" do
      a = assignment_model(course: @course)
      u = User.new
      student1, student2 = [double, double]

      { student1 => "1", student2 => "2" }.each do |student, value|
        expect(a).to receive(:all_dates_visible_to).with(student).and_return({ student: value })
      end

      expect(ObserverEnrollment).to receive(:observed_students).and_return({ student1 => [], student2 => [] })

      override_hashes = a.observed_student_due_dates(u)
      expect(override_hashes).to match_array [{ student: "1" }, { student: "2" }]
    end
  end

  describe "multiple_due_dates?" do
    before do
      course_with_student(course:)
      course.course_sections.create!
      override.set = course.active_course_sections.second
      override.override_due_at(2.days.ago)
      override.save!
    end

    context "when the object has been overridden" do
      context "and it has multiple due dates" do
        it "returns true" do
          expect(overridable.overridden_for(@teacher).multiple_due_dates?).to be true
        end
      end

      context "and it has one due date" do
        it "returns false" do
          expect(overridable.overridden_for(@student).multiple_due_dates?).to be false
        end
      end
    end

    context "when the object hasn't been overridden" do
      it "raises an exception because it doesn't have any context" do
        expect { overridable.multiple_due_dates? }.to raise_exception(DatesOverridable::NotOverriddenError)
      end
    end

    context "when the object has been overridden for a guest" do
      it "returns false" do
        expect(overridable.overridden_for(nil).multiple_due_dates?).to be false
      end
    end
  end
end

shared_examples_for "all learning objects" do
  # let(:overridable) - an Assignment, Quiz, WikiPage, or DiscussionTopic
  # let(:overridable_type) - :assignment, :quiz, :wiki_page, or :discussion_topic
  # WikiPages and DiscussionTopics don't have a due_at field, so these tests can only
  # use lock_at and unlock_at.

  let(:course) { overridable.context }
  let(:override) { overridable.assignment_overrides.create! }

  describe "overridden_for" do
    before do
      student_in_course(course:)
    end

    context "when there are overrides" do
      before do
        override.override_lock_at(7.days.from_now)
        override.save!

        override_student = override.assignment_override_students.build
        override_student.user = @student
        override_student.save!
      end

      it "returns a clone of the object with the relevant override(s) applied" do
        overridden = overridable.overridden_for(@student)
        expect(overridden.lock_at.to_i).to eq override.lock_at.to_i
      end

      it "returns the same object when the user is nil (e.g. a guest)" do
        expect(overridable.overridden_for(nil)).to eq overridable
      end
    end

    context "with no overrides" do
      it "returns the original object" do
        @overridden = overridable.overridden_for(@student)
        expect(@overridden.lock_at.to_i).to eq overridable.lock_at.to_i
      end
    end
  end

  describe "assignment overrides_for" do
    before do
      student_in_course(course:)
    end

    context "with adhoc" do
      before do
        override.override_lock_at(7.days.from_now)
        override.set_type = "ADHOC"
        override.save!
      end

      it "works with an ADHOC context module override" do
        Account.site_admin.enable_feature!(:differentiated_modules)
        module1 = @course.context_modules.create!(name: "Module 1")
        overridable.context_module_tags.create! context_module: module1, context: @course, tag_type: "context_module"

        module_override = module1.assignment_overrides.create!
        override_student = module_override.assignment_override_students.build
        override_student.user = @student
        override_student.save!

        expect(overridable.overrides_for(@student, ensure_set_not_empty: true).size).to eq 1
      end

      it "returns adhoc overrides when active students enrolled in adhoc set" do
        override_student = override.assignment_override_students.build
        override_student.user = @student
        override_student.save!

        expect(overridable.overrides_for(@student, ensure_set_not_empty: true).size).to eq 1
      end

      it "returns nothing when no active students enrolled in adhoc set" do
        expect(overridable.overrides_for(@student, ensure_set_not_empty: true)).to be_empty
      end

      it "returns nothing when active students enrolled in adhoc set removed" do
        override_student = override.assignment_override_students.build
        override_student.user = @student
        override_student.save!

        expect(overridable.overrides_for(@student, ensure_set_not_empty: true).size).to eq 1

        override_student.user.enrollments.destroy_all

        expect(overridable.overrides_for(@student, ensure_set_not_empty: true)).to be_empty
      end
    end
  end

  describe "override teacher visibility" do
    context "when teacher restricted" do
      before do
        2.times { course.course_sections.create! }
        @section_invisible = course.active_course_sections[2]
        @section_visible = course.active_course_sections.second

        @student_invisible = student_in_section(@section_invisible)
        @student_visible = student_in_section(@section_visible, user: user_factory)
        @teacher = teacher_in_section(@section_visible, user: user_factory)

        enrollment = @teacher.enrollments.first
        enrollment.limit_privileges_to_course_section = true
        enrollment.save!
      end

      it "returns empty for overrides of student in other section" do
        override.set_type = "ADHOC"
        @override_student = override.assignment_override_students.build
        @override_student.user = @student_invisible
        @override_student.save!

        expect(overridable.overrides_for(@teacher)).to be_empty
      end

      it "returns not empty for overrides of student in same section" do
        override.set_type = "ADHOC"
        @override_student = override.assignment_override_students.build
        @override_student.user = @student_visible
        @override_student.save!

        expect(overridable.overrides_for(@teacher)).to_not be_empty
      end

      it "returns the correct student for override with students in same and different section" do
        override.set_type = "ADHOC"
        @override_student = override.assignment_override_students.build
        @override_student.user = @student_visible
        @override_student.save!

        @override_student = override.assignment_override_students.build
        @override_student.user = @student_invisible
        @override_student.save!

        expect(overridable.overrides_for(@teacher).size).to eq 1
        ov = overridable.overrides_for(@teacher).first
        s_id = ov.assignment_override_students.first.user_id
        expect(s_id).to eq @student_visible.id
      end
    end

    context "when teacher not restricted" do
      before do
        course.course_sections.create!
        course.course_sections.create!
        @section_invisible = course.active_course_sections[2]
        @section_visible = course.active_course_sections.second

        @student_invisible = student_in_section(@section_invisible)
        @student_visible = student_in_section(@section_visible, user: user_factory)
        @teacher = teacher_in_section(@section_visible, user: user_factory)
      end

      it "returns not empty for overrides of student in other section" do
        override.set_type = "ADHOC"
        @override_student = override.assignment_override_students.build
        @override_student.user = @student_invisible
        @override_student.save!

        expect(overridable.overrides_for(@teacher)).to_not be_empty
      end

      it "returns not empty for overrides of student in same section" do
        override.set_type = "ADHOC"
        @override_student = override.assignment_override_students.build
        @override_student.user = @student_visible
        @override_student.save!

        expect(overridable.overrides_for(@teacher)).to_not be_empty
      end

      it "returns single override for students in different sections" do
        override.set_type = "ADHOC"
        @override_student = override.assignment_override_students.build
        @override_student.user = @student_visible
        @override_student.save!

        @override_student = override.assignment_override_students.build
        @override_student.user = student_in_section(@section_visible)
        @override_student.save!

        @override_student = override.assignment_override_students.build
        @override_student.user = @student_invisible
        @override_student.save!

        expect(overridable.overrides_for(@teacher).size).to eq 1
      end
    end
  end

  describe "has_overrides?" do
    subject { overridable.has_overrides? }

    context "when it does" do
      before { override }

      it { is_expected.to be_truthy }
    end

    context "when it does but it's deleted" do
      before { override.destroy }

      it { is_expected.to be_falsey }
    end

    context "when it doesn't" do
      it { is_expected.to be_falsey }
    end
  end

  describe "has_active_overrides?" do
    context "has active overrides" do
      before { override }

      it "returns true" do
        expect(overridable.reload.has_active_overrides?).to be true
      end
    end

    context "when it has deleted overrides" do
      it "returns false" do
        override.destroy
        expect(overridable.reload.has_active_overrides?).to be false
      end
    end
  end

  describe "without_overrides" do
    it "returns an object with no overrides applied" do
      expect(overridable.without_overrides.overridden).to be_falsey
    end
  end

  describe "all_assignment_overrides" do
    before do
      Account.site_admin.enable_feature!(:differentiated_modules)
      student_in_course(course:)
      override.override_lock_at(7.days.from_now)
      override.set_type = "ADHOC"
      override.save!

      @module1 = @course.context_modules.create!(name: "Module 1")
      @tag1 = overridable.context_module_tags.create! context_module: @module1, context: @course, tag_type: "context_module"

      @module_override = @module1.assignment_overrides.create!
      override_student = @module_override.assignment_override_students.build
      override_student.user = @student
      override_student.save!
    end

    it "includes context module overrides" do
      expect(overridable.all_assignment_overrides).to include(@module_override)
    end

    it "includes unpublished context module overrides" do
      @module1.workflow_state = "unpublished"
      @module1.save!
      expect(overridable.all_assignment_overrides).to include(@module_override)
    end

    it "includes an assignment's quiz's context module overrides" do
      if overridable_type == :quiz || overridable_type == :wiki_page || overridable_type == :discussion_topic
        overridable.assignment = Assignment.new
        expect(overridable.assignment.all_assignment_overrides).to include(@module_override)
      end
      expect(overridable.all_assignment_overrides).to include(@module_override)
    end

    it "does not include deleted content tags" do
      @tag1.destroy
      expect(overridable.all_assignment_overrides).not_to include(@module_override)
    end

    it "does not include context module overrides without the flag" do
      Account.site_admin.disable_feature!(:differentiated_modules)
      expect(overridable.all_assignment_overrides).not_to include(@module_override)
    end
  end

  describe "visible_to_everyone" do
    before do
      Account.site_admin.enable_feature!(:differentiated_modules)
      student_in_course(course:)

      @module1 = @course.context_modules.create!(name: "Module 1")
      @module2 = @course.context_modules.create!(name: "Module 2")
    end

    context "only_visible_to_overrides is false" do
      before do
        overridable.only_visible_to_overrides = false
      end

      it "returns true when there are no related context modules" do
        expect(overridable.visible_to_everyone).to be_truthy
      end

      it "returns true when there are related context modules without overrides" do
        overridable.context_module_tags.create! context_module: @module1, context: @course, tag_type: "context_module"
        overridable.context_module_tags.create! context_module: @module2, context: @course, tag_type: "context_module"

        module_override = @module1.assignment_overrides.create!
        override_student = module_override.assignment_override_students.build
        override_student.user = @student
        override_student.save!

        expect(overridable.visible_to_everyone).to be_truthy
      end

      it "returns true when there are related context modules with only deleted overrides" do
        overridable.context_module_tags.create! context_module: @module1, context: @course, tag_type: "context_module"

        module_override = @module1.assignment_overrides.create!
        override_student = module_override.assignment_override_students.build
        override_student.user = @student
        override_student.save!

        expect(overridable.visible_to_everyone).to be_falsey

        module_override.destroy

        expect(overridable.visible_to_everyone).to be_truthy
      end

      it "returns false when all related context modules have overrides" do
        overridable.context_module_tags.create! context_module: @module1, context: @course, tag_type: "context_module"

        module_override = @module1.assignment_overrides.create!
        override_student = module_override.assignment_override_students.build
        override_student.user = @student
        override_student.save!

        expect(overridable.visible_to_everyone).to be_falsey
      end

      it "returns true when there is a course override" do
        overridable.context_module_tags.create! context_module: @module1, context: @course, tag_type: "context_module"

        module_override = @module1.assignment_overrides.create!
        override_student = module_override.assignment_override_students.build
        override_student.user = @student
        override_student.save!

        override.set_type = "Course"
        override.set = @course
        override.save!

        expect(overridable.visible_to_everyone).to be_truthy
      end
    end

    context "only_visible_to_overrides is true" do
      it "returns false" do
        overridable.only_visible_to_overrides = true
        expect(overridable.visible_to_everyone).to be_falsey
      end
    end
  end

  describe "overridden_for?" do
    before do
      course_with_student(course:)
    end

    context "when overridden for the user" do
      it "returns true" do
        expect(overridable.overridden_for(@teacher).overridden_for?(@teacher)).to be_truthy
      end
    end

    context "when overridden for a different user" do
      it "returns false" do
        expect(overridable.overridden_for(@teacher).overridden_for?(@student)).to be_falsey
      end
    end

    context "when overridden for a nil user" do
      it "returns true" do
        expect(overridable.overridden_for(nil).overridden_for?(nil)).to be_truthy
      end
    end

    context "when not overridden" do
      it "returns false" do
        expect(overridable.overridden_for?(nil)).to be_falsey
      end
    end
  end

  describe "differentiated_assignments_applies?" do
    before do
      course_with_student(course:)
    end

    it "returns false when there is no assignment" do
      if overridable_type == :quiz
        overridable.assignment = nil # a survey quiz
        expect(overridable.differentiated_assignments_applies?).to be_falsey
      end
    end

    it "returns the value of only_visible_to_overrides on the assignment" do
      if overridable_type == :quiz && overridable.try(:assignment) # not a survey quiz
        overridable.assignment.only_visible_to_overrides = true
        expect(overridable.differentiated_assignments_applies?).to be_truthy
        overridable.assignment.only_visible_to_overrides = false
        expect(overridable.differentiated_assignments_applies?).to be_falsey
      elsif overridable_type == :assignment
        overridable.only_visible_to_overrides = true
        expect(overridable.differentiated_assignments_applies?).to be_truthy
        overridable.only_visible_to_overrides = false
        expect(overridable.differentiated_assignments_applies?).to be_falsey
      end
    end
  end
end

describe Assignment do
  let(:overridable_type) { :assignment }
  let(:overridable) { assignment_model(due_at: 5.days.ago) }

  include_examples "learning object with due dates"
  include_examples "all learning objects"
end

describe Quizzes::Quiz do
  let(:overridable_type) { :quiz }
  let(:overridable) { quiz_model(due_at: 5.days.ago) }

  include_examples "learning object with due dates"
  include_examples "all learning objects"
end

describe WikiPage do
  let(:overridable_type) { :wiki_page }
  let(:overridable) { wiki_page_model(lock_at: 5.days.ago) }

  include_examples "all learning objects"
end

describe DiscussionTopic do
  let(:overridable_type) { :discussion_topic }
  let(:overridable) { discussion_topic_model(lock_at: 5.days.ago) }

  include_examples "all learning objects"
end
