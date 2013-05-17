#
# Copyright (C) 2012 Instructure, Inc.
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
require 'lib/data_fixup/initialize_submission_lateness.rb'

describe 'DataFixup::InitializeSubmissionLateness' do
  describe "up" do
    let(:early) { 3.minutes.ago }
    let(:ontime) { 2.minutes.ago }
    let(:late) { 1.minutes.ago }

    def create_submission(assignment, student, submitted_at)
      submission = submission_model(:assignment => assignment, :user => student)
      submission.update_attribute(:submitted_at, submitted_at)
      submission
    end

    before do
      student_in_course
    end

    context "for an assignment without a due date" do
      let(:assignment) { assignment_model(:due_at => nil, :course => @course) }

      it "does not mark submissions as late" do
        submission = create_submission(assignment, @student, late)
        DataFixup::InitializeSubmissionLateness.run
        submission.reload.should_not be_late
      end
    end

    context "for an assignment with a due date" do
      let(:assignment) { assignment_model(:due_at => ontime, :course => @course) }

      it "does not mark early submissions as late" do
        submission = create_submission(assignment, @student, early)
        DataFixup::InitializeSubmissionLateness.run
        submission.reload.should_not be_late
      end

      it "does not mark on time submissions as late" do
        submission = create_submission(assignment, @student, ontime)
        DataFixup::InitializeSubmissionLateness.run
        submission.reload.should_not be_late
      end

      it "does mark late submissions as late" do
        submission = create_submission(assignment, @student, late)
        DataFixup::InitializeSubmissionLateness.run
        submission.reload.should be_late
      end
    end
  end
end