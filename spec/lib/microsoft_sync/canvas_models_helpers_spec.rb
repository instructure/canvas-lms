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

require "microsoft_sync/membership_diff"

describe MicrosoftSync::CanvasModelsHelpers do
  let(:course) { course_with_student.course }

  describe "max_enrollment_members_reached?" do
    subject { described_class.max_enrollment_members_reached?(course) }

    before do
      2.times { student_in_course(course:, active_enrollment: true) }
      student_in_course(course:).update! workflow_state: "completed"
    end

    context "when the max number of members has been surpassed (not including inactive users)" do
      before { stub_const("MicrosoftSync::MembershipDiff::MAX_ENROLLMENT_MEMBERS", 2) }

      it { is_expected.to be true }
    end

    context "when the max number of members has not been surpassed" do
      before { stub_const("MicrosoftSync::MembershipDiff::MAX_ENROLLMENT_MEMBERS", 3) }

      it { is_expected.to be false }
    end
  end

  describe "max_enrollment_owners_reached?" do
    subject { described_class.max_enrollment_owners_reached?(course) }

    before do
      3.times { teacher_in_course(course:, active_enrollment: true) }
      teacher_in_course(course:).update! workflow_state: "invited"
    end

    context "when the max number of owners has been surpassed" do
      before { stub_const("MicrosoftSync::MembershipDiff::MAX_ENROLLMENT_OWNERS", 2) }

      it { is_expected.to be true }
    end

    context "when the max number of owners has not been surpassed" do
      before { stub_const("MicrosoftSync::MembershipDiff::MAX_ENROLLMENT_OWNERS", 4) }

      it { is_expected.to be false }
    end
  end
end
