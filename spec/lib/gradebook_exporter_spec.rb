#
# Copyright (C) 2015 Instructure, Inc.
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

require File.expand_path(File.dirname(__FILE__) + '/../spec_helper.rb')

require 'csv'

describe GradebookExporter do
  describe ".initialize" do
    it "raises an error without a course argument" do
      expect { subject.new }.to raise_error ArgumentError
    end
  end

  describe "#to_csv" do
    let(:course)    { Course.create }
    describe "default output with blank course" do
      let(:exporter)  { GradebookExporter.new(course) }
      subject(:csv)   { exporter.to_csv }

      it "produces a String" do
        expect(subject).to be_a String
      end

      it "is a csv with two rows" do
        expect(CSV.parse(subject).count).to be 2
      end

      it "is a csv with seven columns" do
        expect(CSV.parse(subject).transpose.count).to be 7
      end

      describe "default headers order" do
        let(:headers)   { CSV.parse(subject, headers: true).headers }

        it("first column")    { expect(headers[0]).to eq "Student" }
        it("second column")   { expect(headers[1]).to eq "ID" }
        it("third column")    { expect(headers[2]).to eq "Section"  }
        it("fourth column")   { expect(headers[3]).to eq "Current Points" }
        it("fifth column")    { expect(headers[4]).to eq "Final Points" }
        it("sixth column")    { expect(headers[5]).to eq "Current Score" }
        it("seventh column")  { expect(headers[6]).to eq "Final Score" }
      end
    end

    context "a course has assignments with due dates" do
      let(:assignments) { course.assignments }

      let!(:no_due_date_assignment) { assignments.create title: "no due date" }
      let!(:past_assignment) do
        assignments.create due_at: 5.weeks.ago, title: "past"
      end

      let!(:current_assignment) do
        assignments.create due_at: 1.weeks.from_now, title: "current"
      end

      let!(:future_assignment) do
        assignments.create due_at: 8.weeks.from_now, title: "future"
      end

      let(:csv)     { GradebookExporter.new(course).to_csv }
      let(:headers) { CSV.parse(csv, headers: true).headers }

      describe "when multiple grading periods is on" do
        describe "only current assignments are exported" do
          let!(:enable_mgp) do
            course.enable_feature!(:multiple_grading_periods)
          end

          let!(:period) do
            group = course.grading_period_groups.create!
            args = {
              start_date: 3.weeks.ago,
              end_date: 3.weeks.from_now,
              title: "present day, present time"
            }

            group.grading_periods.create! args
          end

          it "exports current assignments" do
            expect(headers).to include no_due_date_assignment.title_with_id
          end

          it "exports assignments without due dates" do
            expect(headers).to include current_assignment.title_with_id
          end

          it "does not export past assignments" do
            expect(headers).to_not include past_assignment.title_with_id
          end

          it "does not export future assignments" do
            expect(headers).to_not include future_assignment.title_with_id
          end
        end
      end

      describe "when multiple grading periods is off" do
        describe "all assignments are exported" do
          let!(:disable_mgp) do
            course.disable_feature!(:multiple_grading_periods)
          end

          it "exports current assignments" do
            expect(headers).to include no_due_date_assignment.title_with_id
          end

          it "exports assignments without due dates" do
            expect(headers).to include current_assignment.title_with_id
          end

          it "exports past assignments" do
            expect(headers).to include past_assignment.title_with_id
          end

          it "exports future assignments" do
            expect(headers).to include future_assignment.title_with_id
          end
        end
      end
    end
  end
end