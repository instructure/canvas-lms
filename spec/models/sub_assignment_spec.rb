# frozen_string_literal: true

#
# Copyright (C) 2023 - present Instructure, Inc.
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

describe SubAssignment do
  before do
    @course = course_factory(active_course: true)
    @parent_assignment = @course.assignments.create!
  end

  describe "validations" do
    before do
      @sub_assignment = @parent_assignment.sub_assignments.create!(context: @course, sub_assignment_tag: CheckpointLabels::REPLY_TO_TOPIC)
    end

    let(:validation_messages) do
      @sub_assignment.validate
      @sub_assignment.errors.full_messages
    end

    describe "has_sub_assignments" do
      it "must have has_sub_assignments set to false" do
        @sub_assignment.has_sub_assignments = true
        expect(validation_messages).to include "Has sub assignments cannot be true for sub assignments"
      end
    end

    describe "parent_assignment_id" do
      it "must have a parent_assignment_id" do
        @sub_assignment.parent_assignment_id = nil
        expect(validation_messages).to include "Parent assignment can't be blank"
      end

      it "must have a parent_assignment_id that is not self-referencing" do
        @sub_assignment.parent_assignment_id = @sub_assignment.id
        expect(validation_messages).to include "Parent assignment cannot reference self"
      end

      it "does not include a validation message about self-referencing parent_assignment_id when it is blank" do
        @sub_assignment = SubAssignment.new
        expect(validation_messages).not_to include "Parent assignment cannot reference self"
      end
    end

    describe "sub_assignment_tag" do
      it "must be present" do
        @sub_assignment.sub_assignment_tag = nil
        expect(validation_messages).to include "Sub assignment tag is not included in the list"
      end

      it "must be one of the predefined checkpoint labels" do
        @sub_assignment.sub_assignment_tag = "potato"
        expect(validation_messages).to include "Sub assignment tag is not included in the list"
      end
    end
  end

  describe "asset strings" do
    it "can be found via asset string" do
      sub_assignment = @parent_assignment.sub_assignments.create!(context: @course, sub_assignment_tag: CheckpointLabels::REPLY_TO_TOPIC)
      expect(ActiveRecord::Base.find_by_asset_string(sub_assignment.asset_string)).to eq sub_assignment
    end
  end

  describe "serialization" do
    before do
      @sub_assignment = @parent_assignment.sub_assignments.create!(context: @course, sub_assignment_tag: CheckpointLabels::REPLY_TO_TOPIC)
    end

    it "uses sub_assignment as the root key for as_json" do
      expect(@sub_assignment.as_json).to have_key "sub_assignment"
    end

    it "uses sub_assignment as the root key for to_json" do
      expect(JSON.parse(@sub_assignment.to_json)).to have_key "sub_assignment"
    end
  end

  describe "discussion checkpoints" do
    before do
      @parent_assignment.course.account.enable_feature!(:discussion_checkpoints)
      @parent_assignment.update!(title: "graded topic", submission_types: "discussion_topic")
      @topic = @parent_assignment.discussion_topic
      @topic.create_checkpoints(reply_to_topic_points: 3, reply_to_entry_points: 7)
      @checkpoint = @topic.reply_to_topic_checkpoint
    end

    it "updates the parent assignment when tracked attrs change on a checkpoint assignment" do
      expect { @checkpoint.update!(points_possible: 4) }.to change {
        @topic.assignment.reload.points_possible
      }.from(10).to(11)
    end

    it "does not update the parent assignment when attrs that changed are not tracked" do
      expect { @checkpoint.update!(title: "potato") }.not_to change {
        @topic.assignment.reload.updated_at
      }
    end

    it "does not update the parent assignment when the checkpoints flag is disabled" do
      @topic.course.account.disable_feature!(:discussion_checkpoints)
      expect { @checkpoint.update!(points_possible: 4) }.not_to change {
        @topic.assignment.reload.points_possible
      }
    end

    it "can access topic through associations" do
      expect(@checkpoint.discussion_topic).to eq @topic
    end
  end

  describe "scope: visible_to_students_in_course_with_da" do
    before do
      course_with_student(active_all: true)
      @course.account.enable_feature!(:discussion_checkpoints)
      @reply_to_topic, @reply_to_entry = graded_discussion_topic_with_checkpoints(context: @course)
    end

    it "returns sub_assignments visible to student in course" do
      result = SubAssignment.visible_to_students_in_course_with_da([@student.id], [@course.id])
      expect(result.size).to eq 2
      expect(result.pluck(:id)).to match_array([@reply_to_topic.id, @reply_to_entry.id])
    end

    it "does not return sub_assignments not visible to student in course" do
      course2 = course_factory(course_name: "other course", active_course: true)
      result = SubAssignment.visible_to_students_in_course_with_da([@student.id], [course2.id])
      expect(result).to be_empty
    end
  end

  describe "synchronization with parent assignment" do
    before do
      @course = course_factory(active_course: true)
      @parent_assignment = @course.assignments.create!(title: "Parent Assignment", has_sub_assignments: true)
      @sub_assignment = @parent_assignment.sub_assignments.create!(
        context: @course,
        sub_assignment_tag: CheckpointLabels::REPLY_TO_TOPIC,
        title: "Sub Assignment"
      )
    end

    it "updates the parent assignment when unlock_at changes" do
      new_unlock_at = 2.days.from_now
      expect do
        @sub_assignment.update!(unlock_at: new_unlock_at)
      end.to change { @parent_assignment.reload.unlock_at }.to(new_unlock_at)
    end

    it "updates the parent assignment when lock_at changes" do
      new_lock_at = 5.days.from_now
      expect do
        @sub_assignment.update!(lock_at: new_lock_at)
      end.to change { @parent_assignment.reload.lock_at }.to(new_lock_at)
    end

    it "does not update the parent assignment when workflow_state changes" do
      expect do
        @sub_assignment.update!(workflow_state: "deleted")
      end.not_to change { @parent_assignment.reload.workflow_state }
    end

    it "does not trigger a sync when updated by the parent assignment" do
      new_unlock_at = 3.days.from_now
      @parent_assignment.update!(unlock_at: new_unlock_at)

      expect(@sub_assignment).not_to receive(:sync_with_parent)
      @sub_assignment.reload.run_callbacks(:commit)
    end

    it "does not trigger a sync when updated by a transaction" do
      @sub_assignment.saved_by = :transaction
      expect(@parent_assignment).not_to receive(:update_from_sub_assignment)
      @sub_assignment.update!(unlock_at: 1.day.from_now)
    end
  end

  describe "synchronization from parent assignment" do
    before do
      @course = course_factory(active_course: true)
      @parent_assignment = @course.assignments.create!(has_sub_assignments: true, title: "Parent Assignment")
      @sub_assignment1 = @parent_assignment.sub_assignments.create!(
        context: @course,
        sub_assignment_tag: CheckpointLabels::REPLY_TO_TOPIC,
        title: "Sub Assignment 1"
      )
      @sub_assignment2 = @parent_assignment.sub_assignments.create!(
        context: @course,
        sub_assignment_tag: CheckpointLabels::REPLY_TO_ENTRY,
        title: "Sub Assignment 2"
      )
    end

    it "updates all active sub-assignments when parent's unlock_at changes" do
      new_unlock_at = 4.days.from_now
      @parent_assignment.update!(unlock_at: new_unlock_at)

      expect(@sub_assignment1.reload.unlock_at).to eq(new_unlock_at)
      expect(@sub_assignment2.reload.unlock_at).to eq(new_unlock_at)
    end

    it "updates all active sub-assignments when parent's lock_at changes" do
      new_lock_at = 6.days.from_now
      @parent_assignment.update!(lock_at: new_lock_at)

      expect(@sub_assignment1.reload.lock_at).to eq(new_lock_at)
      expect(@sub_assignment2.reload.lock_at).to eq(new_lock_at)
    end

    it "updates all active sub-assignments when parent's workflow_state changes" do
      @parent_assignment.update!(workflow_state: "unpublished")

      expect(@sub_assignment1.reload.workflow_state).to eq("unpublished")
      expect(@sub_assignment2.reload.workflow_state).to eq("unpublished")
    end

    it "does not update inactive sub-assignments" do
      @sub_assignment2.update!(workflow_state: "deleted")
      new_unlock_at = 5.days.from_now
      @parent_assignment.update!(unlock_at: new_unlock_at)

      expect(@sub_assignment1.reload.unlock_at).to eq(new_unlock_at)
      expect(@sub_assignment2.reload.unlock_at).not_to eq(new_unlock_at)
    end
  end

  describe "synchronization between sibling sub-assignments" do
    before do
      @course = course_factory(active_course: true)
      @parent_assignment = @course.assignments.create!(has_sub_assignments: true, title: "Parent Assignment")
      @sub_assignment1 = @parent_assignment.sub_assignments.create!(
        context: @course,
        sub_assignment_tag: CheckpointLabels::REPLY_TO_TOPIC,
        title: "Sub Assignment 1"
      )
      @sub_assignment2 = @parent_assignment.sub_assignments.create!(
        context: @course,
        sub_assignment_tag: CheckpointLabels::REPLY_TO_ENTRY,
        title: "Sub Assignment 2"
      )
      @sub_assignment3 = @parent_assignment.sub_assignments.create!(
        context: @course,
        sub_assignment_tag: CheckpointLabels::REPLY_TO_TOPIC,
        title: "Sub Assignment 3"
      )
    end

    it "updates all sibling sub-assignments when one sub-assignment's unlock_at changes" do
      new_unlock_at = 3.days.from_now
      expect do
        @sub_assignment1.update!(unlock_at: new_unlock_at)
      end.to change { [@sub_assignment2, @sub_assignment3].map { |sa| sa.reload.unlock_at } }
        .to([new_unlock_at, new_unlock_at])
    end

    it "updates all sibling sub-assignments when one sub-assignment's lock_at changes" do
      new_lock_at = 7.days.from_now
      expect do
        @sub_assignment2.update!(lock_at: new_lock_at)
      end.to change { [@sub_assignment1, @sub_assignment3].map { |sa| sa.reload.lock_at } }
        .to([new_lock_at, new_lock_at])
    end

    it "does not update sibling sub-assignments when one sub-assignment's workflow_state changes" do
      expect do
        @sub_assignment1.update!(workflow_state: "deleted")
      end.not_to change { [@sub_assignment2, @sub_assignment3].map { |sa| sa.reload.workflow_state } }
    end

    it "updates active sibling sub-assignments but not inactive ones" do
      @sub_assignment3.update!(workflow_state: "deleted")
      new_unlock_at = 4.days.from_now

      expect do
        @sub_assignment1.update!(unlock_at: new_unlock_at)
      end.to change { @sub_assignment2.reload.unlock_at }.to(new_unlock_at)

      expect(@sub_assignment3.reload.unlock_at).not_to eq(new_unlock_at)
    end

    it "updates the parent assignment and all siblings in a single transaction" do
      new_unlock_at = 5.days.from_now

      expect do
        @sub_assignment1.update!(unlock_at: new_unlock_at)
      end.to change { @parent_assignment.reload.unlock_at }.to(new_unlock_at)
                                                           .and change { @sub_assignment2.reload.unlock_at }.to(new_unlock_at)
                                                                                                            .and change { @sub_assignment3.reload.unlock_at }.to(new_unlock_at)
    end
  end

  describe "callback loop prevention" do
    before do
      @course = course_factory(active_course: true)
      @parent_assignment = @course.assignments.create!(has_sub_assignments: true, title: "Parent Assignment")
      @sub_assignment = @parent_assignment.sub_assignments.create!(
        context: @course,
        sub_assignment_tag: CheckpointLabels::REPLY_TO_TOPIC,
        title: "Sub Assignment"
      )
    end

    it "does not trigger infinite updates when sub-assignment is changed" do
      expect(@sub_assignment).to receive(:sync_with_parent).once.and_call_original
      expect(@parent_assignment).to receive(:update_from_sub_assignment).once.and_call_original
      expect(@parent_assignment).to receive(:update_sub_assignments).once.and_call_original

      @sub_assignment.update!(unlock_at: 1.day.from_now)
    end

    it "does not update parent when saved_by is set to :parent_assignment" do
      @sub_assignment.saved_by = :parent_assignment
      expect(@sub_assignment).not_to receive(:sync_with_parent)
      @sub_assignment.update!(unlock_at: 1.day.from_now)
    end
  end

  describe "callbacks: sync_parent_has_sub_flag" do
    let(:course)            { course_factory(active_course: true) }
    let(:parent)            { course.assignments.create!(title: "Parent", has_sub_assignments: false) }
    let(:attrs) do
      {
        context: course,
        sub_assignment_tag: CheckpointLabels::REPLY_TO_TOPIC,
        title: "A Sub"
      }
    end

    it "marks parent.has_sub_assignments = true on create" do
      expect(parent.has_sub_assignments).to be_falsey

      sub = parent.sub_assignments.create!(attrs)
      sub.send(:sync_parent_has_sub_flag)

      expect(parent.reload.has_sub_assignments).to be_truthy
    end

    it "marks parent.has_sub_assignments = false on destroy" do
      sub = parent.sub_assignments.create!(attrs)
      sub.send(:sync_parent_has_sub_flag)
      expect(parent.reload.has_sub_assignments).to be_truthy

      expect do
        sub.destroy!
        sub.send(:sync_parent_has_sub_flag)
      end.to change { parent.reload.has_sub_assignments }.from(true).to(false)
    end
  end

  describe "title_with_id" do
    before(:once) do
      @course = course_factory(active_course: true)
      @course.account.enable_feature!(:discussion_checkpoints)
      @reply_to_topic, @reply_to_entry = graded_discussion_topic_with_checkpoints(context: @course)
    end

    it "formats the title and id of a reply_to_topic checkpoint assignment" do
      expect(@reply_to_topic.title_with_id).to match("#{@reply_to_topic.title} Reply To Topic (#{@reply_to_topic.id})")
    end

    it "formats the title and id of a reply_to_entry checkpoint assignment" do
      expect(@reply_to_entry.title_with_id).to match("#{@reply_to_entry.title} Required Replies (#{@reply_to_entry.id})")
    end
  end

  describe "title_and_id" do
    it "extracts the title and id of the reply_to_topic checkpoint assignment" do
      expect(SubAssignment.title_and_id("Assignment 1 Reply To Topic (1)")).to eq(["Assignment 1", "1"])
    end

    it "extracts the title and id of the reply_to_entry checkpoint assignment" do
      expect(SubAssignment.title_and_id("Assignment 1 Required Replies (1)")).to eq(["Assignment 1", "1"])
    end

    it "handles extracting the title and id of checkpoints properly" do
      expect(SubAssignment.title_and_id("Reply To Topic Reply To Topic (1)")).to eq(["Reply To Topic", "1"])
      expect(SubAssignment.title_and_id("Required Replies Required Replies (1)")).to eq(["Required Replies", "1"])
    end
  end

  describe "to_atom" do
    before :once do
      course_model
      @course.account.enable_feature!(:discussion_checkpoints)
      @required_replies = 2
      @reply_to_topic, @reply_to_entry = graded_discussion_topic_with_checkpoints(
        context: @course,
        reply_to_entry_required_count: @required_replies
      )
    end

    it "generates correct feed titles for discussion checkpoints" do
      expect(@reply_to_topic.to_atom[:title]).to eq "Assignment: #{@topic.title} Reply to Topic"
      expect(@reply_to_entry.to_atom[:title]).to eq "Assignment: #{@topic.title} Required Replies (#{@required_replies})"
    end

    it "generates correct feed links for discussion checkpoints" do
      expect(@reply_to_topic.to_atom[:link]).to include @reply_to_topic.direct_link.to_s
      expect(@reply_to_entry.to_atom[:link]).to include @reply_to_entry.direct_link.to_s
    end
  end

  describe "title_with_required_replies" do
    before :once do
      course_model
      @course.account.enable_feature!(:discussion_checkpoints)
      @required_replies = 2
      @reply_to_topic, @reply_to_entry = graded_discussion_topic_with_checkpoints(
        context: @course,
        reply_to_entry_required_count: @required_replies
      )
    end

    it "generates correct title for reply to topic checkpoint" do
      expect(@reply_to_topic.title_with_required_replies).to eq "#{@reply_to_topic.title} Reply to Topic"
    end

    it "generates correct title for reply to entry checkpoint" do
      expect(@reply_to_entry.title_with_required_replies).to eq "#{@reply_to_entry.title} Required Replies (#{@required_replies})"
      @reply_to_entry.sub_assignment_tag = "invalid"
      expect(@reply_to_entry.title_with_required_replies).to eq @reply_to_entry.title.to_s
    end

    it "generates correct title for sub_assignment with invalid sub_assignment_tag" do
      @reply_to_topic.sub_assignment_tag = "invalid"
      expect(@reply_to_topic.title_with_required_replies).to eq @reply_to_topic.title.to_s
    end
  end
end
