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

describe DifferentiationTag::AdhocOverrideCreatorService do
  describe "create_adhoc_override" do
    before(:once) do
      @course = course_model

      @teacher = teacher_in_course(course: @course, active_all: true).user
      @student1 = student_in_course(course: @course, active_all: true).user
      @student2 = student_in_course(course: @course, active_all: true).user
      @student3 = student_in_course(course: @course, active_all: true).user
    end

    let(:service) { DifferentiationTag::AdhocOverrideCreatorService }

    context "validate parameters" do
      before do
        @module = @course.context_modules.create!
      end

      it "raises an error if learning object is not provided" do
        errors = service.create_adhoc_override(@course, nil, { student_ids: [@student1.id] }, @teacher)
        expect(errors[0]).to eq("Invalid learning object provided")
      end

      it "raises an error if student_ids are not provided" do
        errors = service.create_adhoc_override(@course, @module, {}, @teacher)
        expect(errors[0]).to eq("Invalid override data provided")
      end

      it "raises an error if course is not provided" do
        errors = service.create_adhoc_override(nil, @module, { student_ids: [@student1.id] }, @teacher)
        expect(errors[0]).to eq("Invalid course provided")
      end

      it "raises an error if course is not a course" do
        errors = service.create_adhoc_override(@course.account, @module, { student_ids: [@student1.id] }, @teacher)
        expect(errors[0]).to eq("Invalid course provided")
      end

      it "raises an error if executing user is not provided" do
        errors = service.create_adhoc_override(@course, @module, { student_ids: [@student1.id] }, nil)
        expect(errors[0]).to eq("Invalid user provided")
      end

      it "raises an error if executing user is not a user" do
        errors = service.create_adhoc_override(@course, @module, { student_ids: [@student1.id] }, @course)
        expect(errors[0]).to eq("Invalid user provided")
      end

      it "can raise multiple errors at once" do
        errors = service.create_adhoc_override(nil, nil, {}, nil)
        expect(errors).to match_array([
                                        "Invalid course provided",
                                        "Invalid learning object provided",
                                        "Invalid override data provided",
                                        "Invalid user provided"
                                      ])
      end
    end

    context "module overrides" do
      before do
        @module = @course.context_modules.create!
      end

      it "creates adhoc overrides for context modules" do
        override_data = {
          student_ids: [@student1.id, @student2.id, @student3.id]
        }

        service.create_adhoc_override(@course, @module, override_data, @teacher)

        expect(@module.assignment_overrides.count).to eq(1)
        expect(@module.assignment_overrides.first.set_type).to eq("ADHOC")
        expect(@module.assignment_overrides.first.assignment_override_students.pluck(:user_id)).to match_array([@student1.id, @student2.id, @student3.id])
      end
    end
  end
end
