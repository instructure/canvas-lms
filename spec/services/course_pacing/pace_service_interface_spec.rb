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

describe CoursePacing::PaceServiceInterface do
  describe ".paces_in_course" do
    it "requires implementation" do
      expect do
        CoursePacing::PaceServiceInterface.paces_in_course(double)
      end.to raise_error NotImplementedError
    end
  end

  describe ".pace_in_context" do
    it "requires implementation" do
      expect do
        CoursePacing::PaceServiceInterface.pace_in_context(double)
      end.to raise_error NotImplementedError
    end
  end

  describe ".create_in_context" do
    context "when the context already has a pace" do
      let(:context) { double(course_paces: double(not_deleted: double(take: "foobar"))) }

      it "returns the pace" do
        expect(CoursePacing::PaceServiceInterface.create_in_context(context)).to eq "foobar"
      end
    end

    context "when the context does not have a pace" do
      let(:context) { double(course_paces: double(not_deleted: double(take: nil))) }

      it "requires implementation" do
        expect do
          CoursePacing::PaceServiceInterface.create_in_context(context)
        end.to raise_error NotImplementedError
      end
    end
  end

  describe ".update_pace" do
    let(:update_params) { { exclude_weekends: false } }

    context "the update is successful" do
      let(:pace) { course_pace_model }

      it "returns the updated pace" do
        expect do
          expect(
            CoursePacing::PaceServiceInterface.update_pace(pace, update_params)
          ).to eq pace
        end.to change {
          pace.exclude_weekends
        }.to false
      end
    end

    context "the update failed" do
      let(:pace) { double }

      it "returns false" do
        allow(pace).to receive(:update).and_return false
        expect(
          CoursePacing::PaceServiceInterface.update_pace(pace, update_params)
        ).to eq false
      end
    end
  end

  describe ".delete_in_context" do
    it "requires implementation" do
      expect do
        CoursePacing::PaceServiceInterface.delete_in_context(double)
      end.to raise_error NotImplementedError
    end
  end
end
