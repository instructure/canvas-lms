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

describe CoursePacing::SectionPaceService do
  let(:course) { course_model }
  let(:section) { add_section("Section One", course:) }
  let(:section_two) { add_section("Section Two", course:) }
  let!(:section_pace) { section_pace_model(section:) }
  let!(:course_pace) { course_pace_model(course:) }

  describe ".paces_in_course" do
    it "returns the paces for the provided course" do
      expect(
        CoursePacing::SectionPaceService.paces_in_course(course)
      ).to match_array [section_pace]
    end

    it "does not include deleted paces" do
      section_pace.destroy!
      expect(
        CoursePacing::SectionPaceService.paces_in_course(course)
      ).to be_empty
    end
  end

  describe ".pace_in_context" do
    it "returns the matching pace" do
      expect(
        CoursePacing::SectionPaceService.pace_in_context(section)
      ).to eq section_pace
    end

    it "returns nil" do
      expect(CoursePacing::SectionPaceService.pace_in_context(section_two)).to be_nil
    end
  end

  describe ".template_pace_for" do
    context "when the course does not have a pace" do
      before { section.course.course_paces.primary.destroy_all }

      it "returns nil" do
        expect(CoursePacing::SectionPaceService.template_pace_for(section)).to be_nil
      end
    end

    context "when the course has a pace" do
      it "returns the course pace" do
        expect(CoursePacing::SectionPaceService.template_pace_for(section)).to eq course_pace
      end
    end
  end

  describe ".create_in_context" do
    context "when the context already has a pace" do
      it "returns the pace" do
        expect(CoursePacing::SectionPaceService.create_in_context(section)).to eq section_pace
      end
    end

    context "when the context does not have a pace" do
      let(:new_section) { add_section("New Section", course:) }

      it "creates a pace in the context" do
        expect do
          CoursePacing::SectionPaceService.create_in_context(new_section)
        end.to change {
          new_section.course_paces.count
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
            CoursePacing::SectionPaceService.update_pace(section_pace, update_params)
          ).to eq section_pace
        end.to change {
          section_pace.exclude_weekends
        }.to false
      end
    end

    context "the update failed" do
      it "returns false" do
        allow(section_pace).to receive(:update).and_return false
        expect(
          CoursePacing::SectionPaceService.update_pace(section_pace, update_params)
        ).to be false
      end
    end
  end

  describe ".delete_in_context" do
    it "deletes the matching pace" do
      expect do
        CoursePacing::SectionPaceService.delete_in_context(section)
      end.to change {
        section.course_paces.not_deleted.count
      }.by(-1)
    end

    it "raises RecordNotFound when the pace is not found" do
      expect do
        CoursePacing::SectionPaceService.delete_in_context(section_two)
      end.to raise_error ActiveRecord::RecordNotFound
    end
  end
end
