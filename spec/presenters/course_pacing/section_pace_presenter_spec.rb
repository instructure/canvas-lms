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

describe CoursePacing::SectionPacePresenter do
  let(:course) { course_model }
  let(:section) { add_section("Section One", course:) }
  let(:pace) { section_pace_model(section:) }
  let(:presenter) { CoursePacing::SectionPacePresenter.new(pace) }

  describe "#as_json" do
    let(:teacher_enrollment) { course_with_teacher(active_all: true) }
    let(:course) { teacher_enrollment.course }

    before do
      2.times { multiple_student_enrollment(user_model, section, course:) }
    end

    it "returns the json presentation of the pace" do
      json = presenter.as_json
      expect(json[:id]).to eq pace.id
      expect(json[:section][:name]).to eq section.name
      expect(json[:section][:size]).to eq 2
    end
  end

  describe "private methods" do
    describe "context_id" do
      it "returns the id of the section" do
        expect(presenter.send(:context_id)).to eq section.id
      end
    end

    describe "context_type" do
      it "specifies 'Section'" do
        expect(presenter.send(:context_type)).to eq "Section"
      end
    end
  end
end
