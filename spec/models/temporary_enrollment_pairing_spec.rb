# frozen_string_literal: true

#
# Copyright (C) 2023 - present Instructure, Inc.
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
require "spec_helper"

describe TemporaryEnrollmentPairing do
  before_once do
    Account.default.enable_feature!(:temporary_enrollments)
    source_user = user_factory(active_all: true)
    temporary_enrollment_recipient = user_factory(active_all: true)
    course_with_teacher(active_all: true, user: source_user)
    @recipient_temp_enrollment = @course.enroll_user(
      temporary_enrollment_recipient,
      "TeacherEnrollment",
      { role: teacher_role, temporary_enrollment_source_user_id: source_user.id }
    )
  end

  before do
    @pairing = TemporaryEnrollmentPairing.create!(root_account: @course.root_account, created_by: account_admin_user)
    @recipient_temp_enrollment.update!(temporary_enrollment_pairing_id: @pairing.id)
  end

  context "associations" do
    it "has enrollments association" do
      expect(@pairing.enrollments.take).to eq @recipient_temp_enrollment
    end
  end

  context "validations" do
    it "requires root_account_id, created_by_id to be present" do
      expect(TemporaryEnrollmentPairing.create.valid?).to be_falsey
      expect(TemporaryEnrollmentPairing.create.errors.full_messages).to include("Root account can't be blank")
      expect(TemporaryEnrollmentPairing.create.errors.full_messages).to include("Created by can't be blank")
    end

    it "sets the workflow_state to active by default" do
      expect(@pairing).to be_active
    end
  end

  context "deletions" do
    it "soft deletes the record" do
      @pairing.destroy
      expect(@pairing.workflow_state).to eq("deleted")
      expect(@pairing.active?).to be_falsey
      expect(@pairing.deleted?).to be_truthy
    end

    it "nullifies the temporary_enrollment_pairing_id of associated enrollments upon soft deletion" do
      expect { @pairing.destroy }.to change { @recipient_temp_enrollment.reload.temporary_enrollment_pairing_id }.from(@pairing.id).to(nil)
    end
  end
end
