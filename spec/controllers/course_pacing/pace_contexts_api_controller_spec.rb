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
#

require_relative "../../spec_helper"

describe CoursePacing::PaceContextsApiController do
  before :once do
    Account.site_admin.enable_feature!(:course_paces_redesign)
    @course = course_factory(active_all: true)
    @course.root_account.enable_feature!(:course_paces)
    @course.update!(enable_course_paces: true)

    @student = user_factory
    @student_enrollment = StudentEnrollment.create!(
      user: @student,
      course: @course,
      workflow_state: "active"
    )

    @section = @course.course_sections.create!(name: "Test Section")

    @teacher = user_factory
    @course.enroll_teacher(@teacher, workflow_state: "active")
  end

  before do
    user_session(@teacher)
  end

  describe "#fetch_overdue_items_by_user" do
    context "when contexts array is empty" do
      it "returns an empty hash" do
        result = controller.send(:fetch_overdue_items_by_user, [])
        expect(result).to eq({})
      end
    end

    context "when contexts contain a non student_enrollment item" do
      it "skips them and returns an empty hash" do
        result = controller.send(:fetch_overdue_items_by_user, [@section])
        expect(result).to eq({})
      end
    end

    context "when contexts contain multiple enrollment contexts" do
      before do
        @student2 = user_factory
        @student_enrollment2 = StudentEnrollment.create!(user: @student2, course: @course)

        @mock_pace1 = double("CoursePace")
        @mock_pace2 = double("CoursePace")

        allow(CoursePace).to receive(:pace_for_context)
          .with(@course, @student_enrollment)
          .and_return(@mock_pace1)
        allow(@mock_pace1).to receive(:overdue_unsubmitted_student_module_items_by_student)
          .with([@student.id])
          .and_return({ @student.id => [:item1] })

        allow(CoursePace).to receive(:pace_for_context)
          .with(@course, @student_enrollment2)
          .and_return(@mock_pace2)
        allow(@mock_pace2).to receive(:overdue_unsubmitted_student_module_items_by_student)
          .with([@student2.id])
          .and_return({ @student2.id => [:item2] })
      end

      it "processes the StudentEnrollments and gathers results by user_id" do
        contexts = [@student_enrollment, @student_enrollment2]
        result = controller.send(:fetch_overdue_items_by_user, contexts)

        expect(result).to eq({ @student.id => [:item1], @student2.id => [:item2] })
      end
    end
  end
end
