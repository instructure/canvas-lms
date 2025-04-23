# frozen_string_literal: true

#
# Copyright (C) 2025 - present Instructure, Inc.
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

describe DifferentiationTag::Converters::GeneralAssignmentOverrideConverter do
  def enable_differentiation_tags_for_context
    @course.account.enable_feature!(:assign_to_differentiation_tags)
    @course.account.settings[:allow_assign_to_differentiation_tags] = { value: true }
    @course.account.save!
  end

  def create_diff_tag_override_for_learning_object(learning_object, tag, dates)
    learning_object.assignment_overrides.create!(set_type: "Group", set: tag, due_at: dates[:due_at], unlock_at: dates[:unlock_at], lock_at: dates[:lock_at])
  end

  describe "convert_tags_to_adhoc_overrides" do
    before(:once) do
      @course = course_model

      @teacher = teacher_in_course(course: @course, active_all: true).user
      @student1 = student_in_course(course: @course, active_all: true).user
      @student2 = student_in_course(course: @course, active_all: true).user
      @student3 = student_in_course(course: @course, active_all: true).user
      @student4 = student_in_course(course: @course, active_all: true).user

      enable_differentiation_tags_for_context
      @diff_tag_category = @course.group_categories.create!(name: "Learning Level", non_collaborative: true)
      @honors_tag = @course.groups.create!(name: "Honors", group_category: @diff_tag_category, non_collaborative: true)
      @standard_tag = @course.groups.create!(name: "Standard", group_category: @diff_tag_category, non_collaborative: true)
      @remedial_tag = @course.groups.create!(name: "Remedial", group_category: @diff_tag_category, non_collaborative: true)

      # Place student 1 in "honors" learning level
      @honors_tag.add_user(@student1, "accepted")

      # Place students 2 and 3 in "standard" learning level
      @standard_tag.add_user(@student2, "accepted")
      @standard_tag.add_user(@student3, "accepted")

      # Place student 4 in "remedial" learning level
      @remedial_tag.add_user(@student4, "accepted")
    end

    let(:converter) { DifferentiationTag::Converters::GeneralAssignmentOverrideConverter }

    shared_examples_for "overridable learning object with due date" do
      it "converts tag overrides to adhoc overrides" do
        create_diff_tag_override_for_learning_object(learning_object, @honors_tag, { due_at: 1.day.from_now })
        create_diff_tag_override_for_learning_object(learning_object, @standard_tag, { due_at: 2.days.from_now })
        create_diff_tag_override_for_learning_object(learning_object, @remedial_tag, { due_at: 3.days.from_now })

        expect(learning_object.assignment_overrides.active.count).to eq(3)
        expect(learning_object.assignment_overrides.active.where(set_type: "Group").count).to eq(3)

        converter.convert_tags_to_adhoc_overrides(learning_object, @course)

        expect(learning_object.assignment_overrides.adhoc.count).to eq(3)
        expect(learning_object.assignment_overrides.active.where(set_type: "Group").count).to eq(0)
      end

      it "preserves due dates" do
        honors_dates = { due_at: 1.day.from_now, unlock_at: Time.zone.now, lock_at: 7.days.from_now }
        standard_dates = { due_at: 5.days.from_now, unlock_at: Time.zone.now, lock_at: 10.days.from_now }

        honors_override = create_diff_tag_override_for_learning_object(learning_object, @honors_tag, honors_dates)
        standard_override = create_diff_tag_override_for_learning_object(learning_object, @standard_tag, standard_dates)

        converter.convert_tags_to_adhoc_overrides(learning_object, @course)

        adhoc_overrides = learning_object.assignment_overrides.adhoc
        expect(adhoc_overrides.count).to eq(2)

        honors_adhoc_override = adhoc_overrides.where(due_at: honors_override.due_at, unlock_at: honors_override.unlock_at, lock_at: honors_override.lock_at).first
        expect(honors_adhoc_override.due_at_overridden?).to be true
        expect(honors_adhoc_override.unlock_at_overridden?).to be true
        expect(honors_adhoc_override.lock_at_overridden?).to be true

        standard_adhoc_override = adhoc_overrides.where(due_at: standard_override.due_at, unlock_at: standard_override.unlock_at, lock_at: standard_override.lock_at).first
        expect(standard_adhoc_override.due_at_overridden?).to be true
        expect(standard_adhoc_override.unlock_at_overridden?).to be true
        expect(standard_adhoc_override.lock_at_overridden?).to be true
      end

      it "removes tag override even if no students are in the tag" do
        diff_tag4 = @course.groups.create!(name: "No Students", group_category: @diff_tag_category, non_collaborative: true)
        create_diff_tag_override_for_learning_object(learning_object, diff_tag4, { due_at: 1.day.from_now })

        expect(learning_object.assignment_overrides.active.count).to eq(1)

        converter.convert_tags_to_adhoc_overrides(learning_object, @course)

        expect(learning_object.assignment_overrides.active.count).to eq(0)
      end

      it "does nothing if no differentiation tag overrides exist" do
        learning_object.assignment_overrides.create!(set_type: "Course", set: @course)

        expect(learning_object.assignment_overrides.active.count).to eq(1)

        converter.convert_tags_to_adhoc_overrides(learning_object, @course)

        expect(learning_object.assignment_overrides.active.count).to eq(1)
        expect(learning_object.assignment_overrides.adhoc.count).to eq(0)
      end

      it "does not create new ADHOC override for student if they already have one" do
        create_diff_tag_override_for_learning_object(learning_object, @standard_tag, { due_at: 1.day.from_now })

        adhoc_override1 = learning_object.assignment_overrides.create!(set_type: "ADHOC", due_at: 7.days.from_now)
        adhoc_override1.assignment_override_students.create!(user: @student2)

        expect(learning_object.assignment_overrides.active.count).to eq(2)

        converter.convert_tags_to_adhoc_overrides(learning_object, @course)

        expect(learning_object.assignment_overrides.active.count).to eq(2)
        expect(learning_object.assignment_overrides.adhoc.count).to eq(2)
      end

      context "students in multiple tags" do
        before do
          @food_category = @course.group_categories.create!(name: "Favorite Food", non_collaborative: true)
          @hot_dog_tag = @course.groups.create!(name: "Hot Dog", group_category: @diff_tag_category, non_collaborative: true)
          @hamburger_tag = @course.groups.create!(name: "Hamburger", group_category: @diff_tag_category, non_collaborative: true)

          @color_category = @course.group_categories.create!(name: "Favorite Color", non_collaborative: true)
          @red_tag = @course.groups.create!(name: "Red", group_category: @color_category, non_collaborative: true)
          @blue_tag = @course.groups.create!(name: "Blue", group_category: @color_category, non_collaborative: true)

          # Student 1 (honors, hot dog, red)
          @hot_dog_tag.bulk_add_users_to_differentiation_tag([@student1.id])
          @red_tag.bulk_add_users_to_differentiation_tag([@student1.id])

          # Student 2 (standard, hamburger, blue)
          @hamburger_tag.bulk_add_users_to_differentiation_tag([@student2.id])
          @blue_tag.bulk_add_users_to_differentiation_tag([@student2.id])

          # Student 3 (standard, hot dog, blue)
          @hot_dog_tag.bulk_add_users_to_differentiation_tag([@student3.id])
          @blue_tag.bulk_add_users_to_differentiation_tag([@student3.id])

          # Student 4 (remedial, hamburger, red)
          @hamburger_tag.bulk_add_users_to_differentiation_tag([@student4.id])
          @red_tag.bulk_add_users_to_differentiation_tag([@student4.id])
        end

        it "places student in adhoc override with the latest possible date" do
          # Learning Level overrides
          honors_dates = { due_at: 1.day.from_now, unlock_at: Time.zone.now, lock_at: 7.days.from_now }
          standard_dates = { due_at: 5.days.from_now, unlock_at: Time.zone.now, lock_at: 10.days.from_now }
          remedial_dates = { due_at: 12.days.from_now, unlock_at: 2.days.ago, lock_at: 14.days.from_now }
          create_diff_tag_override_for_learning_object(learning_object, @honors_tag, honors_dates)
          create_diff_tag_override_for_learning_object(learning_object, @standard_tag, standard_dates)
          create_diff_tag_override_for_learning_object(learning_object, @remedial_tag, remedial_dates)

          # Favorite Food overrides
          hot_dog_dates = { due_at: 3.days.from_now, unlock_at: Time.zone.now, lock_at: 10.days.from_now }
          hamburger_dates = { due_at: 10.days.from_now, unlock_at: Time.zone.now, lock_at: 14.days.from_now }
          create_diff_tag_override_for_learning_object(learning_object, @hot_dog_tag, hot_dog_dates)
          create_diff_tag_override_for_learning_object(learning_object, @hamburger_tag, hamburger_dates)

          # Favorite Color overrides
          red_dates = { due_at: 9.days.from_now, unlock_at: Time.zone.now, lock_at: 7.days.from_now }
          blue_dates = { due_at: 4.days.from_now, unlock_at: Time.zone.now, lock_at: 14.days.from_now }
          create_diff_tag_override_for_learning_object(learning_object, @red_tag, red_dates)
          create_diff_tag_override_for_learning_object(learning_object, @blue_tag, blue_dates)

          expect(learning_object.assignment_overrides.active.count).to eq(7)

          converter.convert_tags_to_adhoc_overrides(learning_object, @course)

          adhoc_overrides = learning_object.assignment_overrides.adhoc
          expect(adhoc_overrides.count).to eq(4)

          # Student 1 should be in the "red" override (latest date they belong to)
          red_adhoc_override = adhoc_overrides.find { |override| override.due_at == red_dates[:due_at] }
          expect(red_adhoc_override.assignment_override_students.map(&:user_id)).to include(@student1.id)

          # Student 2 should be in the "hamburger" override (latest date they belong to)
          hamburger_adhoc_override = adhoc_overrides.find { |override| override.due_at == hamburger_dates[:due_at] }
          expect(hamburger_adhoc_override.assignment_override_students.map(&:user_id)).to include(@student2.id)

          # Student 3 should be in the "standard" override (latest date they belong to)
          standard_adhoc_override = adhoc_overrides.find { |override| override.due_at == standard_dates[:due_at] }
          expect(standard_adhoc_override.assignment_override_students.map(&:user_id)).to include(@student3.id)

          # Student 4 should be in the "remedial" override (latest date they belong to)
          remedial_adhoc_override = adhoc_overrides.find { |override| override.due_at == remedial_dates[:due_at] }
          expect(remedial_adhoc_override.assignment_override_students.map(&:user_id)).to include(@student4.id)
        end

        it "treats 'nil' due date as latest possible date" do
          honors_dates = { due_at: 1.day.from_now, unlock_at: Time.zone.now, lock_at: 7.days.from_now }
          create_diff_tag_override_for_learning_object(learning_object, @honors_tag, honors_dates)

          red_dates = { due_at: nil, unlock_at: Time.zone.now, lock_at: 14.days.from_now }
          create_diff_tag_override_for_learning_object(learning_object, @red_tag, red_dates)

          converter.convert_tags_to_adhoc_overrides(learning_object, @course)

          adhoc_overrides = learning_object.assignment_overrides.adhoc
          expect(adhoc_overrides.count).to eq(1)

          # Students 1 and 4 should be in the "red" override (latest date they belong to)
          red_adhoc_override = adhoc_overrides.find { |override| override.due_at.nil? }
          expect(red_adhoc_override.assignment_override_students.map(&:user_id)).to eq([@student1.id, @student4.id])
        end
      end
    end

    shared_examples_for "overridable learning object with no due date" do
      it "converts tag overrides to adhoc overrides" do
        create_diff_tag_override_for_learning_object(learning_object, @honors_tag, { unlock_at: Time.zone.now, lock_at: 7.days.from_now })
        create_diff_tag_override_for_learning_object(learning_object, @standard_tag, { unlock_at: Time.zone.now, lock_at: 10.days.from_now })
        create_diff_tag_override_for_learning_object(learning_object, @remedial_tag, { unlock_at: Time.zone.now, lock_at: 14.days.from_now })

        expect(learning_object.assignment_overrides.active.count).to eq(3)
        expect(learning_object.assignment_overrides.active.where(set_type: "Group").count).to eq(3)

        converter.convert_tags_to_adhoc_overrides(learning_object, @course)

        expect(learning_object.assignment_overrides.adhoc.count).to eq(3)
        expect(learning_object.assignment_overrides.active.where(set_type: "Group").count).to eq(0)
      end

      it "preserves unlock_at and lock_at dates" do
        honors_dates = { unlock_at: Time.zone.now, lock_at: 7.days.from_now }
        standard_dates = { unlock_at: Time.zone.now, lock_at: 10.days.from_now }

        honors_override = create_diff_tag_override_for_learning_object(learning_object, @honors_tag, honors_dates)
        standard_override = create_diff_tag_override_for_learning_object(learning_object, @standard_tag, standard_dates)

        converter.convert_tags_to_adhoc_overrides(learning_object, @course)

        adhoc_overrides = learning_object.assignment_overrides.adhoc
        expect(adhoc_overrides.count).to eq(2)

        honors_adhoc_override = adhoc_overrides.where(unlock_at: honors_override.unlock_at, lock_at: honors_override.lock_at).first
        expect(honors_adhoc_override.unlock_at_overridden?).to be true
        expect(honors_adhoc_override.lock_at_overridden?).to be true

        standard_adhoc_override = adhoc_overrides.where(unlock_at: standard_override.unlock_at, lock_at: standard_override.lock_at).first
        expect(standard_adhoc_override.unlock_at_overridden?).to be true
        expect(standard_adhoc_override.lock_at_overridden?).to be true
      end

      it "removes tag override even if no students are in the tag" do
        diff_tag4 = @course.groups.create!(name: "No Students", group_category: @diff_tag_category, non_collaborative: true)
        create_diff_tag_override_for_learning_object(learning_object, diff_tag4, { unlock_at: Time.zone.now, lock_at: 7.days.from_now })

        expect(learning_object.assignment_overrides.active.count).to eq(1)

        converter.convert_tags_to_adhoc_overrides(learning_object, @course)

        expect(learning_object.assignment_overrides.active.count).to eq(0)
      end

      it "does nothing if no differentiation tag overrides exist" do
        learning_object.assignment_overrides.create!(set_type: "Course", set: @course)

        expect(learning_object.assignment_overrides.active.count).to eq(1)

        converter.convert_tags_to_adhoc_overrides(learning_object, @course)

        expect(learning_object.assignment_overrides.active.count).to eq(1)
        expect(learning_object.assignment_overrides.adhoc.count).to eq(0)
      end

      it "does not create new ADHOC override for student if they already have one" do
        create_diff_tag_override_for_learning_object(learning_object, @standard_tag, { unlock_at: Time.zone.now, lock_at: 7.days.from_now })

        adhoc_override1 = learning_object.assignment_overrides.create!(set_type: "ADHOC", unlock_at: 1.day.ago, lock_at: 7.days.from_now)
        adhoc_override1.assignment_override_students.create!(user: @student2)

        expect(learning_object.assignment_overrides.active.count).to eq(2)

        converter.convert_tags_to_adhoc_overrides(learning_object, @course)

        expect(learning_object.assignment_overrides.active.count).to eq(2)
        expect(learning_object.assignment_overrides.adhoc.count).to eq(2)
      end

      context "students in multiple tags" do
        before do
          @food_category = @course.group_categories.create!(name: "Favorite Food", non_collaborative: true)
          @hot_dog_tag = @course.groups.create!(name: "Hot Dog", group_category: @diff_tag_category, non_collaborative: true)
          @hamburger_tag = @course.groups.create!(name: "Hamburger", group_category: @diff_tag_category, non_collaborative: true)

          @color_category = @course.group_categories.create!(name: "Favorite Color", non_collaborative: true)
          @red_tag = @course.groups.create!(name: "Red", group_category: @color_category, non_collaborative: true)
          @blue_tag = @course.groups.create!(name: "Blue", group_category: @color_category, non_collaborative: true)

          # Student 1 (honors, hot dog, red)
          @hot_dog_tag.bulk_add_users_to_differentiation_tag([@student1.id])
          @red_tag.bulk_add_users_to_differentiation_tag([@student1.id])

          # Student 2 (standard, hamburger, blue)
          @hamburger_tag.bulk_add_users_to_differentiation_tag([@student2.id])
          @blue_tag.bulk_add_users_to_differentiation_tag([@student2.id])

          # Student 3 (standard, hot dog, blue)
          @hot_dog_tag.bulk_add_users_to_differentiation_tag([@student3.id])
          @blue_tag.bulk_add_users_to_differentiation_tag([@student3.id])

          # Student 4 (remedial, hamburger, red)
          @hamburger_tag.bulk_add_users_to_differentiation_tag([@student4.id])
          @red_tag.bulk_add_users_to_differentiation_tag([@student4.id])
        end

        it "places student in adhoc override with the latest possible date" do
          # Learning Level overrides
          honors_dates = { unlock_at: Time.zone.now, lock_at: 1.day.from_now }
          standard_dates = { unlock_at: Time.zone.now, lock_at: 5.days.from_now }
          remedial_dates = { unlock_at: 2.days.ago, lock_at: 12.days.from_now }
          create_diff_tag_override_for_learning_object(learning_object, @honors_tag, honors_dates)
          create_diff_tag_override_for_learning_object(learning_object, @standard_tag, standard_dates)
          create_diff_tag_override_for_learning_object(learning_object, @remedial_tag, remedial_dates)

          # Favorite Food overrides
          hot_dog_dates = { unlock_at: Time.zone.now, lock_at: 3.days.from_now }
          hamburger_dates = { unlock_at: Time.zone.now, lock_at: 10.days.from_now }
          create_diff_tag_override_for_learning_object(learning_object, @hot_dog_tag, hot_dog_dates)
          create_diff_tag_override_for_learning_object(learning_object, @hamburger_tag, hamburger_dates)

          # Favorite Color overrides
          red_dates = { unlock_at: Time.zone.now, lock_at: 9.days.from_now }
          blue_dates = { unlock_at: Time.zone.now, lock_at: 4.days.from_now }
          create_diff_tag_override_for_learning_object(learning_object, @red_tag, red_dates)
          create_diff_tag_override_for_learning_object(learning_object, @blue_tag, blue_dates)

          expect(learning_object.assignment_overrides.active.count).to eq(7)

          converter.convert_tags_to_adhoc_overrides(learning_object, @course)

          adhoc_overrides = learning_object.assignment_overrides.adhoc
          expect(adhoc_overrides.count).to eq(4)

          # Student 1 should be in the "red" override (latest date they belong to)
          red_adhoc_override = adhoc_overrides.find { |override| override.lock_at == red_dates[:lock_at] }
          expect(red_adhoc_override.assignment_override_students.map(&:user_id)).to include(@student1.id)

          # Student 2 should be in the "hamburger" override (latest date they belong to)
          hamburger_adhoc_override = adhoc_overrides.find { |override| override.lock_at == hamburger_dates[:lock_at] }
          expect(hamburger_adhoc_override.assignment_override_students.map(&:user_id)).to include(@student2.id)

          # Student 3 should be in the "standard" override (latest date they belong to)
          standard_adhoc_override = adhoc_overrides.find { |override| override.lock_at == standard_dates[:lock_at] }
          expect(standard_adhoc_override.assignment_override_students.map(&:user_id)).to include(@student3.id)

          # Student 4 should be in the "remedial" override (latest date they belong to)
          remedial_adhoc_override = adhoc_overrides.find { |override| override.lock_at == remedial_dates[:lock_at] }
          expect(remedial_adhoc_override.assignment_override_students.map(&:user_id)).to include(@student4.id)
        end

        it "treats 'nil' due date as latest possible date" do
          honors_dates = { unlock_at: Time.zone.now, lock_at: 3.days.from_now }
          create_diff_tag_override_for_learning_object(learning_object, @honors_tag, honors_dates)

          red_dates = { unlock_at: Time.zone.now, lock_at: nil }
          create_diff_tag_override_for_learning_object(learning_object, @red_tag, red_dates)

          converter.convert_tags_to_adhoc_overrides(learning_object, @course)

          adhoc_overrides = learning_object.assignment_overrides.adhoc
          expect(adhoc_overrides.count).to eq(1)

          # Students 1 and 4 should be in the "red" override (latest date they belong to)
          red_adhoc_override = adhoc_overrides.find { |override| override.lock_at.nil? }
          expect(red_adhoc_override.assignment_override_students.map(&:user_id)).to eq([@student1.id, @student4.id])
        end
      end
    end

    context "assignment" do
      it_behaves_like "overridable learning object with due date" do
        let(:learning_object) { @course.assignments.create!(title: "Test Assignment") }
      end
    end

    context "quiz" do
      it_behaves_like "overridable learning object with due date" do
        let(:learning_object) { @course.quizzes.create!(title: "Test Quiz") }
      end
    end

    context "discussion topic" do
      it_behaves_like "overridable learning object with no due date" do
        let(:learning_object) { @course.discussion_topics.create!(title: "Test Discussion Topic") }
      end
    end

    context "wiki page" do
      it_behaves_like "overridable learning object with no due date" do
        let(:learning_object) { @course.wiki_pages.create!(title: "Test Wiki Page") }
      end
    end
  end
end
