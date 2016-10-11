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
require_relative '../spec_helper'

describe GradebookCsv do
  context "given a course with a teacher" do
    def csv(course:, user:, force_failure: false)
      attachment = course.attachments.create!(uploaded_data: default_uploaded_data)
      progress = @course.progresses.new(tag: 'gradebook_export')
      progress.workflow_state = 'failed' if force_failure
      progress.save!
      course.gradebook_csvs.create!(user: user, progress: progress, attachment: attachment)
    end

    before(:once) do
      course_with_teacher(active_all: true)
    end

    describe ".last_successful_export" do
      it "returns the last exported gradebook CSV for the given user" do
        csv = csv(course: @course, user: @teacher)
        last_csv = GradebookCsv.last_successful_export(course: @course, user: @teacher)
        expect(last_csv).to eq csv
      end

      it "returns nil if the last exported gradebook CSV failed for the given user" do
        csv(course: @course, user: @teacher, force_failure: true)
        last_csv = GradebookCsv.last_successful_export(course: @course, user: @teacher)
        expect(last_csv).to be_nil
      end

      it "returns nil if the user hasn't exported any gradebook CSVs" do
        last_csv = GradebookCsv.last_successful_export(course: @course, user: @teacher)
        expect(last_csv).to be_nil
      end
    end

    describe "#failed?" do
      it "returns true if the associated progress object has failed" do
        csv = csv(course: @course, user: @teacher, force_failure: true)
        expect(csv).to be_failed
      end

      it "returns false if the associated progress object has not failed" do
        csv = csv(course: @course, user: @teacher)
        expect(csv).to_not be_failed
      end
    end
  end
end