#
# Copyright (C) 2011 Instructure, Inc.
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

require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe AssignmentsHelper do
  include AssignmentsHelper

  describe "#assignment_publishing_enabled?" do
    before(:once) do
      course_with_teacher(active_all: true)
      student_in_course(active_all: true)
      assignment_model(course: @course)
    end

    it "is false if the user cannot update the assignment" do
      expect(assignment_publishing_enabled?(@assignment, @student)).to be_falsey
    end

    it "is false if the assignment already has submissions" do
      @assignment.submissions.create!(user_id: @student, submission_type: 'online_url')
      expect(assignment_publishing_enabled?(@assignment, @teacher)).to be_falsey
    end

    it "is true otherwise" do
      expect(assignment_publishing_enabled?(@assignment, @teacher)).to be_truthy
    end
  end

  describe "#turnitin active?" do
    before(:once) do
      course_with_teacher(active_all: true)
      student_in_course(active_all: true)
      assignment_model(course: @course)
      @assignment.turnitin_enabled = true
      @context = @assignment.context
      @assignment.update_attributes!({
        submission_types: ["online_url"]
      })
      @context.account.update_attributes!({
        turnitin_account_id: 12345,
        turnitin_shared_secret: "the same combination on my luggage"
      })
    end

    it "returns true if turnitin is active on the assignment and account" do
      expect(turnitin_active?).to be_truthy
    end

    it "returns false if the assignment does not require submissions" do
      @assignment.update_attributes!({
        submission_types: ["none"]
      })
      expect(turnitin_active?).to be_falsey
    end

    it "returns false if turnitin is disabled on the account level" do
      @context.account.update_attributes!({
        turnitin_account_id: nil,
        turnitin_shared_secret: nil
      })
      expect(turnitin_active?).to be_falsey
    end
  end
end
