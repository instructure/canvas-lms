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

describe CoursePacing::PaceService do
  describe ".for" do
    let(:course) { course_model }

    it "returns a reference to CoursePacing::CoursePaceService for a Course" do
      expect(
        CoursePacing::PaceService.for(course)
      ).to be CoursePacing::CoursePaceService
    end

    it "returns a reference to CoursePacing::SectionPaceService for a CourseSection" do
      expect(
        CoursePacing::PaceService.for(add_section("Section", course:))
      ).to be CoursePacing::SectionPaceService
    end

    it "returns a reference to CoursePacing::StudentEnrollmentPaceService for a StudentEnrollment" do
      expect(
        CoursePacing::PaceService.for(course.enroll_student(user_model, enrollment_state: "active"))
      ).to be CoursePacing::StudentEnrollmentPaceService
    end

    it "raises for an invalid type" do
      expect { CoursePacing::PaceService.for("foobar") }.to raise_error(ArgumentError)
    end
  end

  describe ".paces_in_course" do
    it "requires implementation" do
      expect { CoursePacing::PaceService.paces_in_course(double) }.to raise_error(NotImplementedError)
    end
  end

  describe ".pace_for" do
    context "when context is invalid" do
      before do
        allow(CoursePacing::PaceService).to receive_messages(valid_context?: false, pace_in_context: "invalid context")
      end

      it "returns nil if invalid context" do
        expect(CoursePacing::PaceService.pace_for(double)).to be_nil
      end
    end

    context "when there is an existing pace within the context" do
      before { allow(CoursePacing::PaceService).to receive(:pace_in_context).and_return("foobar") }

      it "returns the pace in the context" do
        expect(CoursePacing::PaceService.pace_for(double)).to eq "foobar"
      end
    end

    context "when there is no existing pace within the context" do
      before do
        allow(CoursePacing::PaceService).to receive_messages(pace_in_context: nil, template_pace_for: nil)
      end

      it "returns nil" do
        expect(CoursePacing::PaceService.pace_for(double)).to be_nil
      end

      context "when there is an existing template to fall back to" do
        let(:template) { double }

        before { allow(CoursePacing::PaceService).to receive(:template_pace_for).and_return(template) }

        it "returns the existing template" do
          expect(CoursePacing::PaceService.pace_for(double)).to eq template
        end

        context "when the should_duplicate option is set to true" do
          it "duplicates the template within the context" do
            expect(template).to receive(:duplicate)
            CoursePacing::PaceService.pace_for(double, should_duplicate: true)
          end
        end
      end
    end
  end

  describe ".pace_in_context" do
    it "requires implementation" do
      expect do
        CoursePacing::PaceService.pace_in_context(double)
      end.to raise_error NotImplementedError
    end
  end

  describe ".create_in_context" do
    context "when context is invalid" do
      before { allow(CoursePacing::PaceService).to receive(:valid_context?).and_return(false) }

      let(:context) { double(course_paces: double(not_deleted: double(take: "invalid context"))) }

      it "returns nil if invalid context" do
        expect(CoursePacing::PaceService.create_in_context(context)).to be_nil
      end
    end

    context "when the context already has a pace" do
      let(:context) { double(course_paces: double(not_deleted: double(take: "foobar"))) }

      it "returns the pace" do
        expect(CoursePacing::PaceService.create_in_context(context)).to eq "foobar"
      end
    end

    context "when the context does not have a pace" do
      let(:context) { double(course_paces: double(not_deleted: double(take: nil))) }

      it "requires implementation" do
        expect do
          CoursePacing::PaceService.create_in_context(context)
        end.to raise_error NotImplementedError
      end

      it "starts off publishing progress" do
        allow(CoursePacing::PaceService).to receive(:course_for).and_return(course_factory)

        expect(Progress).to receive(:create!)
          .with({ context: instance_of(CoursePace), tag: "course_pace_publish" })
          .and_return(double(process_job: nil))

        CoursePacing::PaceService.create_in_context(context)
      end
    end
  end

  describe ".update_pace" do
    let(:update_params) { { exclude_weekends: false } }

    context "the update is successful" do
      let(:pace) { course_pace_model }

      it "returns the updated pace" do
        expect(Progress).to receive(:create!)
          .with({ context: pace, tag: "course_pace_publish" })
          .and_return(double(process_job: nil))
        expect do
          expect(
            CoursePacing::PaceService.update_pace(pace, update_params)
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
          CoursePacing::PaceService.update_pace(pace, update_params)
        ).to be false
      end
    end
  end

  describe ".delete_in_context" do
    it "requires implementation" do
      expect do
        CoursePacing::PaceService.delete_in_context(double)
      end.to raise_error NotImplementedError
    end
  end
end
