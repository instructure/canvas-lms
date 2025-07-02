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

describe DifferentiationTag::Jobs::Workers::TagOverrideConverterWorker do
  let(:course) { course_factory(active_all: true) }
  let(:teacher) { teacher_in_course(active_all: true, course:).user }
  let(:first_student) { student_in_course(active_all: true, course:).user }
  let(:second_student) { student_in_course(active_all: true, course:).user }

  def enable_differentiation_tags_for_context
    course.account.enable_feature!(:assign_to_differentiation_tags)
    course.account.settings[:allow_assign_to_differentiation_tags] = { value: true }
    course.account.save!
  end

  def enable_discussion_checkpoints_for_context
    course.account.enable_feature!(:discussion_checkpoints)
    course.account.save!
  end

  def create_diff_tag_override_for(learning_object, tag, dates = {})
    if dates.empty?
      learning_object.assignment_overrides.create!(set_type: "Group", set: tag)
    else
      learning_object.assignment_overrides.create!(
        set_type: "Group",
        set: tag,
        due_at: dates[:due_at],
        unlock_at: dates[:unlock_at],
        lock_at: dates[:lock_at]
      )
    end
  end

  def create_checkpointed_discussion(title:, course:)
    discussion = DiscussionTopic.create_graded_topic!(course:, title:)

    Checkpoints::DiscussionCheckpointCreatorService.call(
      discussion_topic: discussion,
      checkpoint_label: CheckpointLabels::REPLY_TO_TOPIC,
      dates: [],
      points_possible: 0
    )
    Checkpoints::DiscussionCheckpointCreatorService.call(
      discussion_topic: discussion,
      checkpoint_label: CheckpointLabels::REPLY_TO_ENTRY,
      dates: [],
      points_possible: 0
    )

    discussion
  end

  def create_tag_override_for_checkpointed_discussion(discussion, tag, dates)
    topic_override = { type: "override", set_type: "Group", set_id: tag.id, due_at: dates[:topic_due_at], unlock_at: dates[:unlock_at], lock_at: dates[:lock_at] }
    entry_override = { type: "override", set_type: "Group", set_id: tag.id, due_at: dates[:entry_due_at], unlock_at: dates[:unlock_at], lock_at: dates[:lock_at] }

    Checkpoints::DiscussionCheckpointUpdaterService.call(
      discussion_topic: discussion,
      checkpoint_label: CheckpointLabels::REPLY_TO_TOPIC,
      dates: [topic_override],
      points_possible: 0
    )
    Checkpoints::DiscussionCheckpointUpdaterService.call(
      discussion_topic: discussion,
      checkpoint_label: CheckpointLabels::REPLY_TO_ENTRY,
      dates: [entry_override],
      points_possible: 0
    )

    discussion
  end

  def get_user_ids_from_adhoc_override(override)
    override.assignment_override_students.pluck(:user_id)
  end

  describe "#perform" do
    before do
      enable_differentiation_tags_for_context
      enable_discussion_checkpoints_for_context

      # Create one type of learning object for course
      @assignment = course.assignments.create!(title: "Test Assignment")
      @discussion_topic = course.discussion_topics.create!(title: "Test Discussion")
      @graded_discussion_topic = course.discussion_topics.create_graded_topic!(title: "Test Graded Discussion", course:)
      @checkpointed_discussion = create_checkpointed_discussion(title: "Test Checkpointed Discussion", course:)
      @quiz = course.quizzes.create!(title: "Test Quiz")
      @wiki_page = course.wiki_pages.create!(title: "Test Wiki Page")

      # Create tags
      @learning_level_category = course.group_categories.create!(name: "Learning Level", non_collaborative: true)
      @honors_tag = course.groups.create!(name: "Honors", group_category: @learning_level_category, non_collaborative: true)
      @regular_tag = course.groups.create!(name: "Regular", group_category: @learning_level_category, non_collaborative: true)

      # Place student 1 in "Honors" tag
      @honors_tag.add_user(first_student, "accepted")

      # Place student 2 in "Regular" tag
      @regular_tag.add_user(second_student, "accepted")

      # Create tag overrides for each learning object
      honors_dates = { due_at: 2.days.from_now, unlock_at: 1.day.from_now, lock_at: 3.days.from_now }
      regular_dates = { due_at: 3.days.from_now, unlock_at: 2.days.from_now, lock_at: 4.days.from_now }
      create_diff_tag_override_for(@assignment, @honors_tag, honors_dates)
      create_diff_tag_override_for(@assignment, @regular_tag, regular_dates)

      create_diff_tag_override_for(@discussion_topic, @honors_tag)
      create_diff_tag_override_for(@discussion_topic, @regular_tag)

      create_diff_tag_override_for(@graded_discussion_topic.assignment, @honors_tag, honors_dates)
      create_diff_tag_override_for(@graded_discussion_topic.assignment, @regular_tag, regular_dates)

      create_diff_tag_override_for(@quiz, @honors_tag, honors_dates)
      create_diff_tag_override_for(@quiz, @regular_tag, regular_dates)

      create_diff_tag_override_for(@wiki_page, @honors_tag)
      create_diff_tag_override_for(@wiki_page, @regular_tag)

      # for simplicity we are only doing one tag override for the checkpointed discussion
      honors_checkpoint_dates = { topic_due_at: 2.days.from_now, entry_due_at: 3.days.from_now, unlock_at: 1.day.from_now, lock_at: 4.days.from_now }
      create_tag_override_for_checkpointed_discussion(@checkpointed_discussion, @honors_tag, honors_checkpoint_dates)
    end

    it "converts tag overrides for course" do
      job_progress = Progress.create!(context_type: "Course", context_id: course.id, tag: DifferentiationTag::DELAYED_JOB_TAG)

      described_class.perform(course)

      job_progress.reload
      expect(job_progress.workflow_state).to eq("completed")
      expect(job_progress.completion).to eq(100)

      # Check that tag overrides were converted to adhoc overrides
      assignment_adhoc_overrides = @assignment.assignment_overrides.active.adhoc
      expect(assignment_adhoc_overrides.count).to eq(2)
      user_ids = assignment_adhoc_overrides.flat_map { |override| get_user_ids_from_adhoc_override(override) }
      expect(user_ids).to contain_exactly(first_student.id, second_student.id)
      expect(@assignment.assignment_overrides.active.where(set_type: "Group").count).to eq(0)

      discussion_adhoc_overrides = @discussion_topic.assignment_overrides.active.adhoc
      expect(discussion_adhoc_overrides.count).to eq(2)
      user_ids = discussion_adhoc_overrides.flat_map { |override| get_user_ids_from_adhoc_override(override) }
      expect(user_ids).to contain_exactly(first_student.id, second_student.id)
      expect(@discussion_topic.assignment_overrides.active.where(set_type: "Group").count).to eq(0)

      graded_discussion_overrides = @graded_discussion_topic.assignment.assignment_overrides.active.adhoc
      expect(graded_discussion_overrides.count).to eq(2)
      user_ids = graded_discussion_overrides.flat_map { |override| get_user_ids_from_adhoc_override(override) }
      expect(user_ids).to contain_exactly(first_student.id, second_student.id)
      expect(@graded_discussion_topic.assignment.assignment_overrides.active.where(set_type: "Group").count).to eq(0)

      quiz_overrides = @quiz.assignment_overrides.active.adhoc
      expect(quiz_overrides.count).to eq(2)
      user_ids = quiz_overrides.flat_map { |override| get_user_ids_from_adhoc_override(override) }
      expect(user_ids).to contain_exactly(first_student.id, second_student.id)
      expect(@quiz.assignment_overrides.active.where(set_type: "Group").count).to eq(0)

      wiki_page_overrides = @wiki_page.assignment_overrides.active.adhoc
      expect(wiki_page_overrides.count).to eq(2)
      user_ids = wiki_page_overrides.flat_map { |override| get_user_ids_from_adhoc_override(override) }
      expect(user_ids).to contain_exactly(first_student.id, second_student.id)
      expect(@wiki_page.assignment_overrides.active.where(set_type: "Group").count).to eq(0)

      # Check checkpointed discussion overrides
      reply_to_topic = @checkpointed_discussion.assignment.sub_assignments.find_by(sub_assignment_tag: CheckpointLabels::REPLY_TO_TOPIC)
      reply_to_entry = @checkpointed_discussion.assignment.sub_assignments.find_by(sub_assignment_tag: CheckpointLabels::REPLY_TO_ENTRY)

      topic_adhoc_overrides = reply_to_topic.assignment_overrides.active.adhoc
      expect(topic_adhoc_overrides.count).to eq(1)
      user_ids = topic_adhoc_overrides.flat_map { |override| get_user_ids_from_adhoc_override(override) }
      expect(user_ids).to contain_exactly(first_student.id)
      expect(reply_to_topic.assignment_overrides.active.where(set_type: "Group").count).to eq(0)

      entry_adhoc_overrides = reply_to_entry.assignment_overrides.active.adhoc
      expect(entry_adhoc_overrides.count).to eq(1)
      user_ids = entry_adhoc_overrides.flat_map { |override| get_user_ids_from_adhoc_override(override) }
      expect(user_ids).to contain_exactly(first_student.id)
      expect(reply_to_entry.assignment_overrides.active.where(set_type: "Group").count).to eq(0)
    end

    it "handles errors correctly" do
      job_progress = Progress.create!(context_type: "Course", context_id: course.id, tag: DifferentiationTag::DELAYED_JOB_TAG)

      # Simulate an error in the conversion process
      allow(DifferentiationTag::OverrideConverterService).to receive(:convert_tags_to_adhoc_overrides_for)
        .and_return(["Simulated conversion error"])

      expect { described_class.perform(course) }.to raise_error(DifferentiationTag::DifferentiationTagServiceError)

      job_progress.reload
      expect(job_progress.workflow_state).to eq("failed")
    end
  end
end
