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

describe DifferentiationTag::OverrideConverterService do
  describe "convert_tags_to_adhoc_overrides_for" do
    def enable_differentiation_tags_for_context
      @course.account.enable_feature!(:assign_to_differentiation_tags)
      @course.account.settings[:allow_assign_to_differentiation_tags] = { value: true }
      @course.account.save!
    end

    def create_diff_tag_override_for(learning_object, tag, dates)
      learning_object.assignment_overrides.create!(set_type: "Group", set: tag, due_at: dates[:due_at], unlock_at: dates[:unlock_at], lock_at: dates[:lock_at])
    end

    before(:once) do
      @course = course_model

      @teacher = teacher_in_course(course: @course, active_all: true).user
      @student1 = student_in_course(course: @course, active_all: true).user
      @student2 = student_in_course(course: @course, active_all: true).user
      @student3 = student_in_course(course: @course, active_all: true).user

      enable_differentiation_tags_for_context
      @diff_tag_category = @course.group_categories.create!(name: "Learning Level", non_collaborative: true)
      @diff_tag1 = @course.groups.create!(name: "Honors", group_category: @diff_tag_category, non_collaborative: true)
      @diff_tag2 = @course.groups.create!(name: "Standard", group_category: @diff_tag_category, non_collaborative: true)

      # Put student 1 in "honors" learning level
      @diff_tag1.add_user(@student1, "accepted")

      # Put students 2 and 3 in "standard" learning level
      @diff_tag2.add_user(@student2, "accepted")
      @diff_tag2.add_user(@student3, "accepted")
    end

    let(:service) { DifferentiationTag::OverrideConverterService }

    context "validate parameters" do
      before do
        @module = @course.context_modules.create!
      end

      it "raises an error if learning object is not provided" do
        errors = service.convert_tags_to_adhoc_overrides_for(learning_object: nil, course: @course)
        expect(errors[0]).to eq("Invalid learning object provided")
      end

      it "raises an error if the learning object type is not supported" do
        errors = service.convert_tags_to_adhoc_overrides_for(learning_object: @course, course: @course)
        expect(errors[0]).to eq("Invalid learning object provided")
      end

      it "raises an error if course is not provided" do
        errors = service.convert_tags_to_adhoc_overrides_for(learning_object: @module, course: nil)
        expect(errors[0]).to eq("Invalid course provided")
      end

      it "raises multiple errors if learning object and course are not provided" do
        errors = service.convert_tags_to_adhoc_overrides_for(learning_object: nil, course: nil)
        expect(errors.count).to eq(2)
        expect(errors[0]).to eq("Invalid course provided")
        expect(errors[1]).to eq("Invalid learning object provided")
      end
    end

    context "context module" do
      before do
        @module = @course.context_modules.create!
      end

      it "converts tag overrides to adhoc overrides" do
        create_diff_tag_override_for(@module, @diff_tag1, {})
        create_diff_tag_override_for(@module, @diff_tag2, {})

        expect(@module.assignment_overrides.active.count).to eq(2)
        expect(@module.assignment_overrides.active.where(set_type: "Group").count).to eq(2)

        service.convert_tags_to_adhoc_overrides_for(learning_object: @module, course: @course)

        adhoc_overrides = @module.assignment_overrides.adhoc
        expect(adhoc_overrides.count).to eq(1)

        expect(@module.assignment_overrides.active.where(set_type: "Group").count).to eq(0)
      end
    end

    shared_examples_for "overridable learning object with dates" do
      it "converts tag overrides to adhoc overrides" do
        create_diff_tag_override_for(learning_object, @diff_tag1, honors_dates)
        create_diff_tag_override_for(learning_object, @diff_tag2, standard_dates)

        expect(learning_object.assignment_overrides.active.count).to eq(2)
        expect(learning_object.assignment_overrides.active.where(set_type: "Group").count).to eq(2)

        service.convert_tags_to_adhoc_overrides_for(learning_object:, course: @course)

        expect(learning_object.assignment_overrides.active.where(set_type: "Group").count).to eq(0)

        adhoc_overrides = learning_object.assignment_overrides.adhoc
        expect(adhoc_overrides.count).to eq(2)

        # Check that the overrides have the correct dates
        expect(adhoc_overrides.where(due_at: honors_dates[:due_at], unlock_at: honors_dates[:unlock_at], lock_at: honors_dates[:lock_at]).count).to eq(1)
        expect(adhoc_overrides.where(due_at: standard_dates[:due_at], unlock_at: standard_dates[:unlock_at], lock_at: standard_dates[:lock_at]).count).to eq(1)
      end
    end

    context "assignment" do
      it_behaves_like "overridable learning object with dates" do
        let(:learning_object) { @course.assignments.create!(title: "Test Assignment") }
        let(:honors_dates) { { due_at: 1.day.from_now, unlock_at: Time.zone.now, lock_at: 3.days.from_now } }
        let(:standard_dates) { { due_at: 2.days.from_now, unlock_at: Time.zone.now, lock_at: 4.days.from_now } }
      end
    end

    context "quiz" do
      it_behaves_like "overridable learning object with dates" do
        let(:learning_object) { @course.quizzes.create!(title: "Test Quiz") }
        let(:honors_dates) { { due_at: 1.day.from_now, unlock_at: Time.zone.now, lock_at: 3.days.from_now } }
        let(:standard_dates) { { due_at: 2.days.from_now, unlock_at: Time.zone.now, lock_at: 4.days.from_now } }
      end
    end

    context "wiki page" do
      it_behaves_like "overridable learning object with dates" do
        let(:learning_object) { @course.wiki_pages.create!(title: "Test Wiki Page") }
        let(:honors_dates) { { unlock_at: Time.zone.now, lock_at: 3.days.from_now } }
        let(:standard_dates) { { unlock_at: Time.zone.now, lock_at: 4.days.from_now } }
      end
    end

    context "discussion topic" do
      it_behaves_like "overridable learning object with dates" do
        let(:learning_object) { @course.discussion_topics.create!(title: "Test Discussion Topic") }
        let(:honors_dates) { { unlock_at: Time.zone.now, lock_at: 3.days.from_now } }
        let(:standard_dates) { { unlock_at: Time.zone.now, lock_at: 4.days.from_now } }
      end
    end

    context "checkpointed discussion" do
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

      it "checkpointed discussion" do
        enable_discussion_checkpoints_for_context

        topic_dates = []
        entry_dates = []

        topic_dates.push({ type: "override", set_type: "Group", set_id: @diff_tag1.id, due_at: 1.day.from_now })
        entry_dates.push({ type: "override", set_type: "Group", set_id: @diff_tag1.id, due_at: 2.days.from_now })

        topic_dates.push({ type: "override", set_type: "Group", set_id: @diff_tag2.id, due_at: 3.days.from_now })
        entry_dates.push({ type: "override", set_type: "Group", set_id: @diff_tag2.id, due_at: 4.days.from_now })

        discussion = create_checkpointed_discussion(
          title: "Test Checkpointed Discussion",
          course: @course,
          dates: { topic_dates:, entry_dates: },
          points_possible: 10
        )

        expect(discussion.assignment.assignment_overrides.active.count).to eq(2)
        expect(discussion.assignment.assignment_overrides.active.where(set_type: "Group").count).to eq(2)

        service.convert_tags_to_adhoc_overrides_for(learning_object: discussion.assignment, course: @course)

        expect(discussion.assignment.assignment_overrides.active.count).to eq(2)
        expect(discussion.assignment.assignment_overrides.active.where(set_type: "ADHOC").count).to eq(2)
      end
    end
  end
end
