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

describe Checkpoints::AdhocOverrideCreatorService do
  describe ".call" do
    before(:once) do
      course = course_model
      course.root_account.enable_feature!(:discussion_checkpoints)
      @student1 = student_in_course(course:, active_all: true).user
      @student2 = student_in_course(course:, active_all: true).user
      topic = DiscussionTopic.create_graded_topic!(course:, title: "graded topic")
      topic.create_checkpoints(reply_to_topic_points: 3, reply_to_entry_points: 7)
      @checkpoint = topic.reply_to_topic_checkpoint
    end

    let(:service) { Checkpoints::AdhocOverrideCreatorService }

    it "raises an error if student_ids is not provided" do
      override = { due_at: 2.days.from_now }
      expect do
        service.call(checkpoint: @checkpoint, override:)
      end.to raise_error(Checkpoints::StudentIdsRequiredError)
    end

    it "creates a parent adhoc override without dates set (but still overridden), if one doesn't already exist" do
      override = { due_at: 2.days.from_now, unlock_at: 2.days.ago, lock_at: 4.days.from_now, student_ids: [@student1.id, @student2.id] }
      service.call(checkpoint: @checkpoint, override:)
      parent_override = @checkpoint.parent_assignment.assignment_overrides.first

      aggregate_failures do
        expect(parent_override.set_type).to eq "ADHOC"
        expect(parent_override.due_at).to be_nil
        expect(parent_override.due_at_overridden).to be true
        expect(parent_override.unlock_at).to be_nil
        expect(parent_override.unlock_at_overridden).to be true
        expect(parent_override.lock_at).to be_nil
        expect(parent_override.lock_at_overridden).to be true
      end
    end

    it "creates override_students for the parent override" do
      override = { due_at: 2.days.from_now, student_ids: [@student1.id, @student2.id] }
      service.call(checkpoint: @checkpoint, override:)
      parent_override = @checkpoint.parent_assignment.assignment_overrides.first

      override_students = parent_override.assignment_override_students
      expect(override_students.where(user_id: [@student1.id, @student2.id]).count).to eq 2
    end

    it "doesn't create a new parent adhoc override if one already exists" do
      @checkpoint.parent_assignment.assignment_overrides.create!(set_type: "ADHOC")
      override = { due_at: 2.days.from_now, student_ids: [@student1.id, @student2.id] }
      expect do
        service.call(checkpoint: @checkpoint, override:)
      end.not_to change { @checkpoint.parent_assignment.assignment_overrides.count }.from(1)
    end

    it "only creates new parent adhoc override students if they don't already exist" do
      parent_override = @checkpoint.parent_assignment.assignment_overrides.create!(set_type: "ADHOC")
      parent_override.assignment_override_students.create!(user: @student1)
      override = { due_at: 2.days.from_now, student_ids: [@student1.id, @student2.id] }
      expect do
        service.call(checkpoint: @checkpoint, override:)
      end.to change { parent_override.assignment_override_students.count }.from(1).to(2)
    end

    describe "due_at" do
      it "creates an override with due_at set and overridden when provided a due_at" do
        due_at = 2.days.from_now
        override = { student_ids: [@student1.id, @student2.id], due_at: }
        created_override = service.call(checkpoint: @checkpoint, override:)

        aggregate_failures do
          expect(created_override.due_at).to eq due_at
          expect(created_override.due_at_overridden).to be true
          override_students = created_override.assignment_override_students
          expect(override_students.where(user_id: [@student1.id, @student2.id]).count).to eq 2
        end
      end

      it "overrides due_at when the due_at key is provided and the value is nil" do
        override = { student_ids: [@student1.id, @student2.id], due_at: nil }
        created_override = service.call(checkpoint: @checkpoint, override:)

        aggregate_failures do
          expect(created_override.due_at).to be_nil
          expect(created_override.due_at_overridden).to be true
          override_students = created_override.assignment_override_students
          expect(override_students.where(user_id: [@student1.id, @student2.id]).count).to eq 2
        end
      end
    end

    describe "unlock_at" do
      it "creates an override with unlock_at set and overridden when provided a unlock_at" do
        unlock_at = 2.days.from_now
        override = { student_ids: [@student1.id, @student2.id], unlock_at: }
        created_override = service.call(checkpoint: @checkpoint, override:)

        aggregate_failures do
          expect(created_override.unlock_at).to eq unlock_at
          expect(created_override.unlock_at_overridden).to be true
          override_students = created_override.assignment_override_students
          expect(override_students.where(user_id: [@student1.id, @student2.id]).count).to eq 2
        end
      end

      it "overrides unlock_at when the unlock_at key is provided and the value is nil" do
        override = { student_ids: [@student1.id, @student2.id], unlock_at: nil }
        created_override = service.call(checkpoint: @checkpoint, override:)

        aggregate_failures do
          expect(created_override.unlock_at).to be_nil
          expect(created_override.unlock_at_overridden).to be true
          override_students = created_override.assignment_override_students
          expect(override_students.where(user_id: [@student1.id, @student2.id]).count).to eq 2
        end
      end
    end

    describe "lock_at" do
      it "creates an override with lock_at set and overridden when provided a lock_at" do
        lock_at = 2.days.from_now
        override = { student_ids: [@student1.id, @student2.id], lock_at: }
        created_override = service.call(checkpoint: @checkpoint, override:)

        aggregate_failures do
          expect(created_override.lock_at).to eq lock_at
          expect(created_override.lock_at_overridden).to be true
          override_students = created_override.assignment_override_students
          expect(override_students.where(user_id: [@student1.id, @student2.id]).count).to eq 2
        end
      end

      it "overrides lock_at when the lock_at key is provided and the value is nil" do
        override = { student_ids: [@student1.id, @student2.id], lock_at: nil }
        created_override = service.call(checkpoint: @checkpoint, override:)

        aggregate_failures do
          expect(created_override.lock_at).to be_nil
          expect(created_override.lock_at_overridden).to be true
          override_students = created_override.assignment_override_students
          expect(override_students.where(user_id: [@student1.id, @student2.id]).count).to eq 2
        end
      end
    end
  end
end
