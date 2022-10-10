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

describe CoursePacing::PaceContextsService do
  subject { CoursePacing::PaceContextsService.new(course) }

  let(:course) { course_model(name: "My Course") }

  describe ".contexts_of_type" do
    context "for type 'course'" do
      it "returns the course" do
        expect(subject.contexts_of_type("course")).to match_array [course]
      end
    end

    context "for type 'section'" do
      it "requires implementation" do
        expect do
          subject.contexts_of_type("section")
        end.to raise_error(NotImplementedError)
      end
    end

    context "for type 'student_enrollment'" do
      it "requires implementation" do
        expect do
          subject.contexts_of_type("student_enrollment")
        end.to raise_error(NotImplementedError)
      end
    end

    context "for anything else" do
      it "captures the invalid type" do
        expect(Canvas::Errors).to receive(:capture_exception).with(:pace_contexts_service, "Expected a value of 'course', 'section', or 'student_enrollment', got 'foobar'")
        subject.contexts_of_type("foobar")
      end
    end
  end
end
