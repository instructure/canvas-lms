# frozen_string_literal: true

#
# Copyright (C) 2022 - present Instructure, Inc.
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

describe CoursePacing::CoursePaceService do
  let(:course) { course_model }
  let!(:course_pace) { course_pace_model(course:) }

  describe ".off_pace_counts_by_user" do
    let(:student) { user_factory }
    let(:student2) { user_factory }
    let!(:student_enrollment) { StudentEnrollment.create!(user: student, course:, workflow_state: "active") }
    let!(:student_enrollment2) { StudentEnrollment.create!(user: student2, course:) }
    let(:section) { course.course_sections.create!(name: "Test Section") }

    before do
      @course.enable_course_paces = true
      @course.save!

      @mod1 = @course.context_modules.create! name: "M1"
      @a1 = @course.assignments.create! name: "A1", points_possible: 100, workflow_state: "active", submission_types: "text"
      @ct1 = @mod1.add_item id: @a1.id, type: "assignment"

      @mod2 = @course.context_modules.create! name: "M2"
      @a2 = @course.assignments.create! name: "A2", points_possible: 50, workflow_state: "unpublished", submission_types: "text"
      @ct2 = @mod2.add_item id: @a2.id, type: "assignment"
      @a3 = @course.assignments.create! name: "A3", workflow_state: "active"
      @ct3 = @mod2.add_item id: @a3.id, type: "assignment", submission_types: "text"

      course_pace.publish
    end

    context "when contexts array is empty" do
      it "returns an empty hash" do
        result = CoursePacing::CoursePaceService.off_pace_counts_by_user([])
        expect(result).to eq({})
      end
    end

    context "when contexts contain a non student_enrollment item" do
      it "skips them and returns an empty hash" do
        result = CoursePacing::CoursePaceService.off_pace_counts_by_user([section])
        expect(result).to eq({})
      end
    end

    context "when contexts contain multiple enrollment contexts" do
      before do
        student_enrollment.update(start_at: 10.days.ago)
        student_enrollment2.update(start_at: 10.days.ago)
        course_pace.publish
      end

      it "processes the StudentEnrollments and gathers results by user_id" do
        contexts = [student_enrollment, student_enrollment2]
        result = CoursePacing::CoursePaceService.off_pace_counts_by_user(contexts)
        expect(result).to eq({ student.id => 2, student2.id => 2 })
      end
    end
  end

  describe ".paces_in_course" do
    it "returns the primary paces for the provided course" do
      expect(
        CoursePacing::CoursePaceService.paces_in_course(course)
      ).to match_array [course_pace]
    end
  end

  describe ".pace_in_context" do
    it "returns the matching pace" do
      expect(
        CoursePacing::CoursePaceService.pace_in_context(course)
      ).to eq course_pace
    end

    it "returns nil when the pace is not found" do
      expect(CoursePacing::CoursePaceService.pace_in_context(course_model)).to be_nil
    end
  end

  describe ".template_pace_for" do
    it "returns nil" do
      expect(CoursePacing::CoursePaceService.template_pace_for(course)).to be_nil
    end
  end

  describe ".create_in_context" do
    context "when the context already has a pace" do
      it "returns the pace" do
        expect(CoursePacing::CoursePaceService.create_in_context(course)).to eq course_pace
      end
    end

    context "when the context does not have a pace" do
      let(:new_course) { course_model }

      it "creates a pace in the context" do
        expect do
          CoursePacing::CoursePaceService.create_in_context(new_course)
        end.to change {
          new_course.course_paces.count
        }.by 1
      end
    end
  end

  describe ".update_pace" do
    context "the update is successful" do
      context "when add_selected_days_to_skip_param is enabled" do
        before do
          stub_const("SKIP_SELECTED_DAYS", %w[mon tue wed thu])
          @course.root_account.enable_feature!(:course_paces_skip_selected_days)
        end

        it "returns the updated pace" do
          expect do
            expect(
              CoursePacing::CoursePaceService.update_pace(course_pace, { selected_days_to_skip: SKIP_SELECTED_DAYS })
            ).to eq course_pace
          end.to change {
            course_pace.selected_days_to_skip
          }.to SKIP_SELECTED_DAYS
        end
      end

      context "when add_selected_days_to_skip_param is disabled" do
        before do
          @course.root_account.disable_feature!(:course_paces_skip_selected_days)
        end

        it "returns the updated pace" do
          expect do
            expect(
              CoursePacing::CoursePaceService.update_pace(course_pace, { exclude_weekends: false })
            ).to eq course_pace
          end.to change {
            course_pace.exclude_weekends
          }.to false
        end
      end
    end

    context "the update failed" do
      it "returns false" do
        allow(course_pace).to receive(:update).and_return false
        expect(
          CoursePacing::CoursePaceService.update_pace(course_pace, { exclude_weekends: false })
        ).to be false
      end
    end
  end

  describe ".delete_in_context" do
    it "deletes the matching pace" do
      expect do
        CoursePacing::CoursePaceService.delete_in_context(course)
      end.to change {
        course.course_paces.not_deleted.count
      }.by(-1)
    end

    it "raises RecordNotFound when the pace is not found" do
      expect do
        CoursePacing::CoursePaceService.delete_in_context(course_model)
      end.to raise_error ActiveRecord::RecordNotFound
    end
  end
end
