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

describe CoursePacing::StudentEnrollmentPacePresenter do
  let(:course) { course_model }
  let(:student) { user_model(name: "Foo Bar") }
  let(:student_enrollment) { course.enroll_student(student, enrollment_state: "active") }
  let(:pace) { student_enrollment_pace_model(student_enrollment:) }
  let(:presenter) { CoursePacing::StudentEnrollmentPacePresenter.new(pace) }

  describe "#as_json" do
    it "returns the json presentation of the pace" do
      json = presenter.as_json
      expect(json[:id]).to eq pace.id
      expect(json[:student][:name]).to eq student.name
    end
  end

  describe "private methods" do
    describe "context_id" do
      it "returns the id of the student enrollment" do
        expect(presenter.send(:context_id)).to eq student_enrollment.id
      end
    end

    describe "context_type" do
      it "specifies 'StudentEnrollment'" do
        expect(presenter.send(:context_type)).to eq "StudentEnrollment"
      end
    end
  end
end
