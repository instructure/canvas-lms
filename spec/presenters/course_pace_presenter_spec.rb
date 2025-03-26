# frozen_string_literal: true

#
# Copyright (C) 2021 - present Instructure, Inc.
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

require_relative "../conditional_release_spec_helper"

RSpec::Matchers.define :docx_includes do |expected|
  match do |actual|
    doc = Docx::Document.open(actual)

    doc.paragraphs.each do |p|
      p.each_text_run do |tr|
        return true if tr.to_s.include?(expected)
      end
    end

    doc.tables.each do |t|
      t.rows.each do |r|
        r.cells.each do |c|
          return true if c.to_s.include?(expected)
        end
      end
    end

    false
  end
end

describe CoursePacePresenter do
  before :once do
    course_with_teacher(active_all: true)
    @course.enable_course_paces = true
    @course.save!
    student_in_course(active_all: true)
    course_pace_model(course: @course)

    @mod1 = @course.context_modules.create! name: "M1"
    @a1 = @course.assignments.create! name: "A1", points_possible: 100, workflow_state: "active", submission_types: "text"
    @ct1 = @mod1.add_item id: @a1.id, type: "assignment"

    @mod2 = @course.context_modules.create! name: "M2"
    @a2 = @course.assignments.create! name: "A2", points_possible: 50, workflow_state: "unpublished", submission_types: "text"
    @ct2 = @mod2.add_item id: @a2.id, type: "assignment"
    @a3 = @course.assignments.create! name: "A3", workflow_state: "active"
    @ct3 = @mod2.add_item id: @a3.id, type: "assignment", submission_types: "text"
  end

  describe "#as_json" do
    it "returns all necessary data for the course pace" do
      formatted_plan = CoursePacePresenter.new(@course_pace).as_json

      expect(formatted_plan[:id]).to eq(@course_pace.id)
      expect(formatted_plan[:context_id]).to eq(@course_pace.course_id)
      expect(formatted_plan[:context_type]).to eq("Course")
      expect(formatted_plan[:course_id]).to eq(@course_pace.course_id)
      expect(formatted_plan[:course_section_id]).to eq(@course_pace.course_section_id)
      expect(formatted_plan[:user_id]).to eq(@course_pace.user_id)
      expect(formatted_plan[:workflow_state]).to eq(@course_pace.workflow_state)
      expect(formatted_plan[:end_date]).to eq(@course_pace.end_date)
      expect(formatted_plan[:exclude_weekends]).to eq(@course_pace.exclude_weekends)
      expect(formatted_plan[:selected_days_to_skip]).to eq(@course_pace.selected_days_to_skip)
      expect(formatted_plan[:hard_end_dates]).to eq(@course_pace.hard_end_dates)
      expect(formatted_plan[:created_at]).to eq(@course_pace.created_at)
      expect(formatted_plan[:updated_at]).to eq(@course_pace.updated_at)
      expect(formatted_plan[:published_at]).to eq(@course_pace.published_at)
      expect(formatted_plan[:root_account_id]).to eq(@course_pace.root_account_id)
      expect(formatted_plan[:modules].size).to eq(2)

      first_module = formatted_plan[:modules].first
      expect(first_module[:name]).to eq(@mod1.name)
      expect(first_module[:position]).to eq(1)
      expect(first_module[:items].size).to eq(1)
      first_module_item = first_module[:items].first
      expect(first_module_item[:assignment_title]).to eq(@a1.name)
      expect(first_module_item[:position]).to eq(1)
      expect(first_module_item[:points_possible]).to eq(100)
      expect(first_module_item[:assignment_link]).to eq("/courses/#{@course.id}/modules/items/#{@ct1.id}")
      expect(first_module_item[:module_item_type]).to eq("Assignment")
      expect(first_module_item[:published]).to be(true)

      second_module = formatted_plan[:modules].second
      expect(second_module[:name]).to eq(@mod2.name)
      expect(second_module[:position]).to eq(2)
      expect(second_module[:items].size).to eq(2)
      first_module_item = second_module[:items].first
      expect(first_module_item[:assignment_title]).to eq(@a2.name)
      expect(first_module_item[:position]).to eq(1)
      expect(first_module_item[:points_possible]).to eq(50)
      expect(first_module_item[:assignment_link]).to eq("/courses/#{@course.id}/modules/items/#{@ct2.id}")
      expect(first_module_item[:module_item_type]).to eq("Assignment")
      expect(first_module_item[:published]).to be(false)
      second_module_item = second_module[:items].second
      expect(second_module_item[:assignment_title]).to eq(@a3.name)
      expect(second_module_item[:position]).to eq(2)
      expect(second_module_item[:points_possible]).to be_nil
      expect(second_module_item[:assignment_link]).to eq("/courses/#{@course.id}/modules/items/#{@ct3.id}")
      expect(second_module_item[:module_item_type]).to eq("Assignment")
      expect(second_module_item[:published]).to be(true)
    end

    it "returns necessary data if the course pace is only instantiated" do
      course_pace = @course.course_paces.new
      @course.context_module_tags.each do |module_item|
        course_pace.course_pace_module_items.new module_item:, duration: 0
      end
      formatted_plan = CoursePacePresenter.new(course_pace).as_json

      expect(formatted_plan[:id]).to eq(course_pace.id)
      expect(formatted_plan[:context_id]).to eq(course_pace.course_id)
      expect(formatted_plan[:context_type]).to eq("Course")
      expect(formatted_plan[:course_id]).to eq(course_pace.course_id)
      expect(formatted_plan[:course_section_id]).to eq(course_pace.course_section_id)
      expect(formatted_plan[:user_id]).to eq(course_pace.user_id)
      expect(formatted_plan[:workflow_state]).to eq(course_pace.workflow_state)
      expect(formatted_plan[:end_date]).to eq(course_pace.end_date)
      expect(formatted_plan[:exclude_weekends]).to eq(@course_pace.exclude_weekends)
      expect(formatted_plan[:selected_days_to_skip]).to eq(course_pace.selected_days_to_skip)
      expect(formatted_plan[:hard_end_dates]).to eq(course_pace.hard_end_dates)
      expect(formatted_plan[:created_at]).to eq(course_pace.created_at)
      expect(formatted_plan[:updated_at]).to eq(course_pace.updated_at)
      expect(formatted_plan[:published_at]).to eq(course_pace.published_at)
      expect(formatted_plan[:root_account_id]).to eq(course_pace.root_account_id)
      expect(formatted_plan[:modules].size).to eq(2)

      first_module = formatted_plan[:modules].first
      expect(first_module[:name]).to eq(@mod1.name)
      expect(first_module[:position]).to eq(1)
      expect(first_module[:items].size).to eq(1)
      first_module_item = first_module[:items].first
      expect(first_module_item[:assignment_title]).to eq(@a1.name)
      expect(first_module_item[:position]).to eq(1)
      expect(first_module_item[:points_possible]).to eq(100)
      expect(first_module_item[:assignment_link]).to eq("/courses/#{@course.id}/modules/items/#{@ct1.id}")
      expect(first_module_item[:module_item_type]).to eq("Assignment")
      expect(first_module_item[:published]).to be(true)

      second_module = formatted_plan[:modules].second
      expect(second_module[:name]).to eq(@mod2.name)
      expect(second_module[:position]).to eq(2)
      expect(second_module[:items].size).to eq(2)
      first_module_item = second_module[:items].first
      expect(first_module_item[:assignment_title]).to eq(@a2.name)
      expect(first_module_item[:position]).to eq(1)
      expect(first_module_item[:points_possible]).to eq(50)
      expect(first_module_item[:assignment_link]).to eq("/courses/#{@course.id}/modules/items/#{@ct2.id}")
      expect(first_module_item[:module_item_type]).to eq("Assignment")
      expect(first_module_item[:published]).to be(false)
      second_module_item = second_module[:items].second
      expect(second_module_item[:assignment_title]).to eq(@a3.name)
      expect(second_module_item[:position]).to eq(2)
      expect(second_module_item[:points_possible]).to be_nil
      expect(second_module_item[:assignment_link]).to eq("/courses/#{@course.id}/modules/items/#{@ct3.id}")
      expect(second_module_item[:module_item_type]).to eq("Assignment")
      expect(second_module_item[:published]).to be(true)
    end

    context "with mastery paths for enrollment paces" do
      before do
        @course.root_account.enable_feature!(:course_pace_pacing_with_mastery_paths)
        @course.update(conditional_release: true)
        setup_course_with_native_conditional_release(course: @course)
        course_pace_model(course: @course, user: @student)
      end

      it "sets 'unreleased' attribute true for conditionally released but not yet released module items" do
        formatted_plan = CoursePacePresenter.new(@course_pace).as_json

        last_module = formatted_plan[:modules].last
        first_module_item = last_module[:items].first

        expect(first_module_item[:unreleased]).to be true
      end
    end
  end

  describe "#as_docx" do
    describe "for default course paces" do
      let(:docx_string) { CoursePacePresenter.new(@course_pace).as_docx(@course).string }

      it "includes course name" do
        expect(docx_string).to docx_includes(@course.name)
      end

      it "uses today as the course start date" do
        expect(docx_string).to docx_includes(I18n.l(Time.zone.today, format: CoursePacePresenter::DATE_FORMAT))
      end

      it "includes each module and module item" do
        expect(docx_string).to docx_includes(@mod1.name)
        expect(docx_string).to docx_includes(@mod2.name)

        expect(docx_string).to docx_includes(@a1.name)
        expect(docx_string).to docx_includes(@a2.name)
        expect(docx_string).to docx_includes(@a3.name)
      end

      it "reflects the skipped days of week" do
        expect(docx_string).to docx_includes(@course_pace.selected_days_to_skip.map(&:capitalize).join("/"))
      end
    end

    describe "for section course paces" do
      before do
        add_section("S1")
        section_pace_model(section: @course_section)
      end

      let(:docx_string) { CoursePacePresenter.new(@section_pace).as_docx(@course_section).string }

      it "includes section name" do
        expect(docx_string).to docx_includes(@course_section.name)
      end

      it "includes number of students in the section" do
        expect(docx_string).to docx_includes("#{@course_section.students.count} students in this section")
      end
    end

    describe "for enrollment course paces" do
      before do
        @enrollment.update(start_at: 3.days.ago)
        student_enrollment_pace_model(student_enrollment: @enrollment)
      end

      let(:docx_string) { CoursePacePresenter.new(@student_enrollment_pace).as_docx(@enrollment).string }

      it "includes docx_string name" do
        expect(docx_string).to docx_includes(@student.name)
      end

      it "uses enrollment start_at as start date" do
        expect(docx_string).to docx_includes(I18n.l(@enrollment.start_at, format: CoursePacePresenter::DATE_FORMAT))
      end
    end

    describe "on/off pace determination" do
      it "marks student as off pace" do
        @enrollment.update(start_at: 30.days.ago)
        student_enrollment_pace_model(student_enrollment: @enrollment)
        @student_enrollment_pace.publish

        docx_string = CoursePacePresenter.new(@student_enrollment_pace).as_docx(@enrollment).string

        expect(docx_string).to docx_includes("Off Pace")
      end

      it "marks student as on pace" do
        @enrollment.update(start_at: 0.days.ago)
        student_enrollment_pace_model(student_enrollment: @enrollment)
        @student_enrollment_pace.publish
        docx_string = CoursePacePresenter.new(@student_enrollment_pace).as_docx(@enrollment).string

        expect(docx_string).to docx_includes("On Pace")
      end
    end
  end
end
