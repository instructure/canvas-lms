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

require_relative "../../spec_helper"

describe CoursePacing::PaceContextsPresenter do
  describe ".as_json" do
    before :once do
      @course = course_factory(active_all: true)
      @course_section = @course.course_sections.create!(name: "Test Section")

      @student = user_factory
      @student_enrollment = StudentEnrollment.create!(
        user: @student,
        course: @course,
        workflow_state: "active"
      )

      @overdue_items_by_user = {}
    end

    context "when the context is a CourseSection" do
      it "returns on_pace as null" do
        json = described_class.as_json(@course_section, @overdue_items_by_user)
        expect(json[:on_pace]).to be_nil
        expect(json[:type]).to eq("CourseSection")
        expect(json[:name]).to eq(@course_section.name)
        expect(json[:item_id]).to eq(@course_section.id)
      end
    end

    context "when the context is a StudentEnrollment and overdue_items is empty" do
      before do
        @overdue_items_by_user = {}
      end

      it "returns on_pace as true" do
        json = described_class.as_json(@student_enrollment, @overdue_items_by_user)
        expect(json[:type]).to eq("StudentEnrollment")
        expect(json[:name]).to eq(@student.name)
        expect(json[:on_pace]).to be(true)
        expect(json[:item_id]).to eq(@student_enrollment.id)
      end
    end

    context "when the context is a StudentEnrollment and overdue_items is not empty" do
      before do
        @overdue_items_by_user[@student.id] = [:overdue_item]
      end

      it "returns on_pace as false" do
        json = described_class.as_json(@student_enrollment, @overdue_items_by_user)
        expect(json[:on_pace]).to be(false)
      end
    end
  end
end
