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

describe CoursePacing::PaceServiceFactory do
  describe ".for" do
    let(:course) { course_model }

    it "returns a reference to CoursePacing::CoursePaceService for a Course" do
      expect(
        CoursePacing::PaceServiceFactory.for(course)
      ).to eq CoursePacing::CoursePaceService
    end

    it "returns a reference to CoursePacing::SectionPaceService for a CourseSection" do
      expect(
        CoursePacing::PaceServiceFactory.for(add_section("Section", course:))
      ).to eq CoursePacing::SectionPaceService
    end

    it "returns a reference to CoursePacing::StudentEnrollmentPaceService for a StudentEnrollment" do
      expect(
        CoursePacing::PaceServiceFactory.for(course.enroll_student(user_model, enrollment_state: "active"))
      ).to eq CoursePacing::StudentEnrollmentPaceService
    end

    it "captures anything else" do
      expect(Canvas::Errors).to receive(:capture_exception).with(:pace_service_factory, "Expected an object of type 'Course', 'CourseSection', or 'StudentEnrollment', got String: 'foobar'")
      CoursePacing::PaceServiceFactory.for("foobar")
    end
  end
end
