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

describe DifferentiationTag::Converters::CheckpointedDiscussionOverrideConverter do
  def enable_differentiation_tags_for_context
    @course.account.enable_feature!(:assign_to_differentiation_tags)
    @course.account.settings[:allow_assign_to_differentiation_tags] = { value: true }
    @course.account.save!
  end

  def enable_discussion_checkpoints_for_context
    @course.account.enable_feature!(:discussion_checkpoints)
    @course.account.save!
  end

  def create_checkpointed_discussion(title:, course:, dates:, points_possible:)
    discussion = DiscussionTopic.create_graded_topic!(course:, title:)

    Checkpoints::DiscussionCheckpointCreatorService.call(
      discussion_topic: discussion,
      checkpoint_label: CheckpointLabels::REPLY_TO_TOPIC,
      dates: dates[:topic_dates],
      points_possible:
    )
    Checkpoints::DiscussionCheckpointCreatorService.call(
      discussion_topic: discussion,
      checkpoint_label: CheckpointLabels::REPLY_TO_ENTRY,
      dates: dates[:entry_dates],
      points_possible:
    )

    discussion
  end

  def find_adhoc_override_for_student(checkpoint, student_id)
    checkpoint.assignment_overrides.find do |override|
      override.set_type == "ADHOC" && override.assignment_override_students.map(&:user_id).include?(student_id)
    end
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
      enable_discussion_checkpoints_for_context
      @diff_tag_category = @course.group_categories.create!(name: "Learning Level", non_collaborative: true)
      @honors_tag = @course.groups.create!(name: "Honors", group_category: @diff_tag_category, non_collaborative: true)
      @standard_tag = @course.groups.create!(name: "Standard", group_category: @diff_tag_category, non_collaborative: true)
      @remedial_tag = @course.groups.create!(name: "Remedial", group_category: @diff_tag_category, non_collaborative: true)

      # Place student 1 in "Honors" learning level
      @honors_tag.add_user(@student1, "accepted")

      # Place student 2 and 3 in "Standard" learning level
      @standard_tag.add_user(@student2, "accepted")
      @standard_tag.add_user(@student3, "accepted")

      # Place student 4 in "Remedial" learning level
      @remedial_tag.add_user(@student4, "accepted")
    end

    let(:converter) { DifferentiationTag::Converters::CheckpointedDiscussionOverrideConverter }

    it "converts tag overrides to adhoc overrides" do
      topic_dates = []
      entry_dates = []

      # Learning Level overrides
      topic_dates.push({ type: "override", set_type: "Group", set_id: @honors_tag.id, due_at: 1.day.from_now, unlock_at: 1.day.ago, lock_at: 10.days.from_now })
      entry_dates.push({ type: "override", set_type: "Group", set_id: @honors_tag.id, due_at: 2.days.from_now, unlock_at: 1.day.ago, lock_at: 10.days.from_now })
      topic_dates.push({ type: "override", set_type: "Group", set_id: @standard_tag.id, due_at: 2.days.from_now, unlock_at: 1.day.ago, lock_at: 10.days.from_now })
      entry_dates.push({ type: "override", set_type: "Group", set_id: @standard_tag.id, due_at: 3.days.from_now, unlock_at: 1.day.ago, lock_at: 10.days.from_now })
      topic_dates.push({ type: "override", set_type: "Group", set_id: @remedial_tag.id, due_at: 3.days.from_now, unlock_at: 1.day.ago, lock_at: 10.days.from_now })
      entry_dates.push({ type: "override", set_type: "Group", set_id: @remedial_tag.id, due_at: 4.days.from_now, unlock_at: 1.day.ago, lock_at: 10.days.from_now })

      # Indexes for later reference
      honors_index = 0
      standard_index = 1
      remedial_index = 2

      discussion = create_checkpointed_discussion(
        title: "Checkpointed Discussion",
        course: @course,
        dates: { topic_dates:, entry_dates: },
        points_possible: 5
      )
      reply_to_topic = discussion.assignment.sub_assignments.find_by(sub_assignment_tag: CheckpointLabels::REPLY_TO_TOPIC)
      reply_to_entry = discussion.assignment.sub_assignments.find_by(sub_assignment_tag: CheckpointLabels::REPLY_TO_ENTRY)

      overrides = discussion.assignment.assignment_overrides.active
      expect(overrides.count).to eq(3)
      expect(overrides.all? { |o| o[:set_type] == "Group" }).to be true

      converter.convert_tags_to_adhoc_overrides(discussion.assignment, @course)

      overrides = discussion.assignment.assignment_overrides.active
      expect(overrides.count).to eq(3)
      expect(overrides.all? { |o| o[:set_type] == "ADHOC" }).to be true

      # Student 1 should be in the "honors" override
      student1_topic_override = find_adhoc_override_for_student(reply_to_topic, @student1.id)
      student1_entry_override = find_adhoc_override_for_student(reply_to_entry, @student1.id)

      expect(student1_topic_override[:due_at]).to eq(topic_dates[honors_index][:due_at])
      expect(student1_topic_override[:unlock_at]).to eq(topic_dates[honors_index][:unlock_at])
      expect(student1_topic_override[:lock_at]).to eq(topic_dates[honors_index][:lock_at])

      expect(student1_entry_override[:due_at]).to eq(entry_dates[honors_index][:due_at])
      expect(student1_entry_override[:unlock_at]).to eq(entry_dates[honors_index][:unlock_at])
      expect(student1_entry_override[:lock_at]).to eq(entry_dates[honors_index][:lock_at])

      # Student 2 should be in the "standard" override
      student2_topic_override = find_adhoc_override_for_student(reply_to_topic, @student2.id)
      student2_entry_override = find_adhoc_override_for_student(reply_to_entry, @student2.id)

      expect(student2_topic_override[:due_at]).to eq(topic_dates[standard_index][:due_at])
      expect(student2_topic_override[:unlock_at]).to eq(topic_dates[standard_index][:unlock_at])
      expect(student2_topic_override[:lock_at]).to eq(topic_dates[standard_index][:lock_at])

      expect(student2_entry_override[:due_at]).to eq(entry_dates[standard_index][:due_at])
      expect(student2_entry_override[:unlock_at]).to eq(entry_dates[standard_index][:unlock_at])
      expect(student2_entry_override[:lock_at]).to eq(entry_dates[standard_index][:lock_at])

      # Student 3 should be in the "standard" override
      student3_topic_override = find_adhoc_override_for_student(reply_to_topic, @student3.id)
      student3_entry_override = find_adhoc_override_for_student(reply_to_entry, @student3.id)

      expect(student3_topic_override[:due_at]).to eq(topic_dates[standard_index][:due_at])
      expect(student3_topic_override[:unlock_at]).to eq(topic_dates[standard_index][:unlock_at])
      expect(student3_topic_override[:lock_at]).to eq(topic_dates[standard_index][:lock_at])

      expect(student3_entry_override[:due_at]).to eq(entry_dates[standard_index][:due_at])
      expect(student3_entry_override[:unlock_at]).to eq(entry_dates[standard_index][:unlock_at])
      expect(student3_entry_override[:lock_at]).to eq(entry_dates[standard_index][:lock_at])

      # Student 4 should be in the "remedial" override
      student4_topic_override = find_adhoc_override_for_student(reply_to_topic, @student4.id)
      student4_entry_override = find_adhoc_override_for_student(reply_to_entry, @student4.id)

      expect(student4_topic_override[:due_at]).to eq(topic_dates[remedial_index][:due_at])
      expect(student4_topic_override[:unlock_at]).to eq(topic_dates[remedial_index][:unlock_at])
      expect(student4_topic_override[:lock_at]).to eq(topic_dates[remedial_index][:lock_at])

      expect(student4_entry_override[:due_at]).to eq(entry_dates[remedial_index][:due_at])
      expect(student4_entry_override[:unlock_at]).to eq(entry_dates[remedial_index][:unlock_at])
      expect(student4_entry_override[:lock_at]).to eq(entry_dates[remedial_index][:lock_at])
    end

    it "does not create adhoc overrides for students that already have an adhoc override" do
      topic_dates = []
      entry_dates = []

      # Learning Level overrides
      topic_dates.push({ type: "override", set_type: "Group", set_id: @honors_tag.id, due_at: 1.day.from_now })
      entry_dates.push({ type: "override", set_type: "Group", set_id: @honors_tag.id, due_at: 2.days.from_now })
      topic_dates.push({ type: "override", set_type: "Group", set_id: @standard_tag.id, due_at: 2.days.from_now })
      entry_dates.push({ type: "override", set_type: "Group", set_id: @standard_tag.id, due_at: 3.days.from_now })

      discussion = create_checkpointed_discussion(
        title: "Checkpointed Discussion",
        course: @course,
        dates: { topic_dates:, entry_dates: },
        points_possible: 5
      )
      reply_to_topic = discussion.assignment.sub_assignments.find_by(sub_assignment_tag: CheckpointLabels::REPLY_TO_TOPIC)
      reply_to_entry = discussion.assignment.sub_assignments.find_by(sub_assignment_tag: CheckpointLabels::REPLY_TO_ENTRY)

      overrides = discussion.assignment.assignment_overrides.active
      expect(overrides.count).to eq(2)

      # Create an adhoc override for student 1
      topic_adhoc_override = { type: "override", set_type: "ADHOC", student_ids: [@student1.id], due_at: 3.days.from_now }
      entry_adhoc_override = { type: "override", set_type: "ADHOC", student_ids: [@student1.id], due_at: 4.days.from_now }

      Checkpoints::AdhocOverrideCreatorService.call(checkpoint: reply_to_topic, override: topic_adhoc_override)
      Checkpoints::AdhocOverrideCreatorService.call(checkpoint: reply_to_entry, override: entry_adhoc_override)

      converter.convert_tags_to_adhoc_overrides(discussion.assignment, @course)

      overrides = discussion.assignment.assignment_overrides.active
      expect(overrides.count).to eq(2) # One for honors tag and one adhoc override for student 1

      # Student 1 should still have their adhoc override
      student1_topic_override = find_adhoc_override_for_student(reply_to_topic, @student1.id)
      student1_entry_override = find_adhoc_override_for_student(reply_to_entry, @student1.id)
      expect(student1_topic_override[:due_at]).to eq(topic_adhoc_override[:due_at])
      expect(student1_entry_override[:due_at]).to eq(entry_adhoc_override[:due_at])
    end

    context "students in multiple tags" do
      before do
        @food_category = @course.group_categories.create!(name: "Favorite Food", non_collaborative: true)
        @hot_dog_tag = @course.groups.create!(name: "Hot Dog", group_category: @food_category, non_collaborative: true)
        @hamburger_tag = @course.groups.create!(name: "Hamburger", group_category: @food_category, non_collaborative: true)

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

      it "Gives each student the latest possible due dates from their tags" do
        topic_dates = []
        entry_dates = []

        # Learning Level overrides
        topic_dates.push({ type: "override", set_type: "Group", set_id: @honors_tag.id, due_at: 1.day.from_now })
        entry_dates.push({ type: "override", set_type: "Group", set_id: @honors_tag.id, due_at: 2.days.from_now })
        topic_dates.push({ type: "override", set_type: "Group", set_id: @standard_tag.id, due_at: 2.days.from_now })
        entry_dates.push({ type: "override", set_type: "Group", set_id: @standard_tag.id, due_at: 3.days.from_now })
        topic_dates.push({ type: "override", set_type: "Group", set_id: @remedial_tag.id, due_at: 3.days.from_now })
        entry_dates.push({ type: "override", set_type: "Group", set_id: @remedial_tag.id, due_at: 4.days.from_now })

        # Favorite Food overrides
        topic_dates.push({ type: "override", set_type: "Group", set_id: @hot_dog_tag.id, due_at: 5.days.from_now })
        entry_dates.push({ type: "override", set_type: "Group", set_id: @hot_dog_tag.id, due_at: 7.days.from_now })
        topic_dates.push({ type: "override", set_type: "Group", set_id: @hamburger_tag.id, due_at: 6.days.from_now })
        entry_dates.push({ type: "override", set_type: "Group", set_id: @hamburger_tag.id, due_at: 8.days.from_now })

        # Favorite Color overrides
        topic_dates.push({ type: "override", set_type: "Group", set_id: @red_tag.id, due_at: 4.days.from_now })
        entry_dates.push({ type: "override", set_type: "Group", set_id: @red_tag.id, due_at: 6.days.from_now })
        topic_dates.push({ type: "override", set_type: "Group", set_id: @blue_tag.id, due_at: 10.days.from_now })
        entry_dates.push({ type: "override", set_type: "Group", set_id: @blue_tag.id, due_at: 12.days.from_now })

        # Indexes for later reference
        hot_dog_index = 3
        hamburger_index = 4
        blue_index = 6

        discussion = create_checkpointed_discussion(
          title: "Checkpointed Discussion",
          course: @course,
          dates: { topic_dates:, entry_dates: },
          points_possible: 5
        )
        reply_to_topic = discussion.assignment.sub_assignments.find_by(sub_assignment_tag: CheckpointLabels::REPLY_TO_TOPIC)
        reply_to_entry = discussion.assignment.sub_assignments.find_by(sub_assignment_tag: CheckpointLabels::REPLY_TO_ENTRY)

        overrides = discussion.assignment.assignment_overrides.active
        expect(overrides.count).to eq(7)
        expect(overrides.all? { |o| o[:set_type] == "Group" }).to be true

        converter.convert_tags_to_adhoc_overrides(discussion.assignment, @course)

        overrides = discussion.assignment.assignment_overrides.active
        expect(overrides.count).to eq(3)
        expect(overrides.all? { |o| o[:set_type] == "ADHOC" }).to be true

        # Student 1 should be in the "hot dog" override (latest dates for topic and entry)
        student1_topic_override = find_adhoc_override_for_student(reply_to_topic, @student1.id)
        student1_entry_override = find_adhoc_override_for_student(reply_to_entry, @student1.id)
        expect(student1_topic_override[:due_at]).to eq(topic_dates[hot_dog_index][:due_at])
        expect(student1_entry_override[:due_at]).to eq(entry_dates[hot_dog_index][:due_at])

        # Student 2 should be in the "blue" override (latest dates for topic and entry)
        student2_topic_override = find_adhoc_override_for_student(reply_to_topic, @student2.id)
        student2_entry_override = find_adhoc_override_for_student(reply_to_entry, @student2.id)
        expect(student2_topic_override[:due_at]).to eq(topic_dates[blue_index][:due_at])
        expect(student2_entry_override[:due_at]).to eq(entry_dates[blue_index][:due_at])

        # Student 3 should be in the "blue" override (latest dates for topic and entry)
        student3_topic_override = find_adhoc_override_for_student(reply_to_topic, @student3.id)
        student3_entry_override = find_adhoc_override_for_student(reply_to_entry, @student3.id)
        expect(student3_topic_override[:due_at]).to eq(topic_dates[blue_index][:due_at])
        expect(student3_entry_override[:due_at]).to eq(entry_dates[blue_index][:due_at])

        # Student 4 should be in the "hamburber" override (latest dates for topic and entry)
        student4_topic_override = find_adhoc_override_for_student(reply_to_topic, @student4.id)
        student4_entry_override = find_adhoc_override_for_student(reply_to_entry, @student4.id)
        expect(student4_topic_override[:due_at]).to eq(topic_dates[hamburger_index][:due_at])
        expect(student4_entry_override[:due_at]).to eq(entry_dates[hamburger_index][:due_at])
      end

      it "selects the latest due dates for students in multiple tags" do
        topic_dates = []
        entry_dates = []

        # Learning Level overrides
        topic_dates.push({ type: "override", set_type: "Group", set_id: @honors_tag.id, due_at: 7.days.from_now })
        entry_dates.push({ type: "override", set_type: "Group", set_id: @honors_tag.id, due_at: 8.days.from_now })

        # Favorite Food overrides
        topic_dates.push({ type: "override", set_type: "Group", set_id: @hot_dog_tag.id, due_at: 5.days.from_now })
        entry_dates.push({ type: "override", set_type: "Group", set_id: @hot_dog_tag.id, due_at: 10.days.from_now })

        # Indexes for later reference
        honors_index = 0
        hot_dog_index = 1

        discussion = create_checkpointed_discussion(
          title: "Checkpointed Discussion",
          course: @course,
          dates: { topic_dates:, entry_dates: },
          points_possible: 5
        )
        reply_to_topic = discussion.assignment.sub_assignments.find_by(sub_assignment_tag: CheckpointLabels::REPLY_TO_TOPIC)
        reply_to_entry = discussion.assignment.sub_assignments.find_by(sub_assignment_tag: CheckpointLabels::REPLY_TO_ENTRY)

        overrides = discussion.assignment.assignment_overrides.active
        expect(overrides.count).to eq(2)

        converter.convert_tags_to_adhoc_overrides(discussion.assignment, @course)

        discussion.assignment.assignment_overrides.active

        # Student 1 should have the topic date from the "honors" tag and the entry date from the "hot dog" tag
        student1_topic_override = find_adhoc_override_for_student(reply_to_topic, @student1.id)
        student1_entry_override = find_adhoc_override_for_student(reply_to_entry, @student1.id)
        expect(student1_topic_override[:due_at]).to eq(topic_dates[honors_index][:due_at])
        expect(student1_entry_override[:due_at]).to eq(entry_dates[hot_dog_index][:due_at])
      end

      it "treats nil as the latest possible date" do
        topic_dates = []
        entry_dates = []

        # Learning Level overrides
        topic_dates.push({ type: "override", set_type: "Group", set_id: @honors_tag.id, due_at: nil })
        entry_dates.push({ type: "override", set_type: "Group", set_id: @honors_tag.id, due_at: 3.days.from_now })

        # Favorite Food overrides
        topic_dates.push({ type: "override", set_type: "Group", set_id: @hot_dog_tag.id, due_at: 5.days.from_now })
        entry_dates.push({ type: "override", set_type: "Group", set_id: @hot_dog_tag.id, due_at: 10.days.from_now })

        # Indexes for later reference
        hot_dog_index = 1

        discussion = create_checkpointed_discussion(
          title: "Checkpointed Discussion",
          course: @course,
          dates: { topic_dates:, entry_dates: },
          points_possible: 5
        )
        reply_to_topic = discussion.assignment.sub_assignments.find_by(sub_assignment_tag: CheckpointLabels::REPLY_TO_TOPIC)
        reply_to_entry = discussion.assignment.sub_assignments.find_by(sub_assignment_tag: CheckpointLabels::REPLY_TO_ENTRY)

        overrides = discussion.assignment.assignment_overrides.active
        expect(overrides.count).to eq(2)

        converter.convert_tags_to_adhoc_overrides(discussion.assignment, @course)

        discussion.assignment.assignment_overrides.active

        # Student 1 should have the topic date from the "honors" tag and the entry date from the "hot dog" tag
        student1_topic_override = find_adhoc_override_for_student(reply_to_topic, @student1.id)
        student1_entry_override = find_adhoc_override_for_student(reply_to_entry, @student1.id)
        expect(student1_topic_override[:due_at]).to be_nil
        expect(student1_entry_override[:due_at]).to eq(entry_dates[hot_dog_index][:due_at])
      end
    end
  end
end
