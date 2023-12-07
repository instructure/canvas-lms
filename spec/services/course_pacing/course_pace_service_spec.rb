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
    let(:update_params) { { exclude_weekends: false } }

    context "the update is successful" do
      it "returns the updated pace" do
        expect do
          expect(
            CoursePacing::CoursePaceService.update_pace(course_pace, update_params)
          ).to eq course_pace
        end.to change {
          course_pace.exclude_weekends
        }.to false
      end
    end

    context "the update failed" do
      it "returns false" do
        allow(course_pace).to receive(:update).and_return false
        expect(
          CoursePacing::CoursePaceService.update_pace(course_pace, update_params)
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
