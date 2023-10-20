# frozen_string_literal: true

#
# Copyright (C) 2020 - present Instructure, Inc.
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

require_relative "../spec_helper"

describe UserNotesController do
  before :once do
    Account.default.update_attribute :enable_user_notes, true
  end

  describe "create" do
    let_once(:target) { user_factory }

    context "when the deprecate_faculty_journal feature flag is disabled" do
      before { Account.site_admin.disable_feature!(:deprecate_faculty_journal) }

      it "passes along the root_account_id when a note is created" do
        course_with_teacher(active_all: true)
        @course.enroll_user(target, "StudentEnrollment").accept!

        user_session(@teacher)
        post "create", params: {
          user_id: target.id,
          user_note: {
            note: "this is a note",
            title: "this is a title",
            user_id: target.id
          }
        }
        note = UserNote.last
        expect(note.root_account_id).to eql Account.default.id
      end
    end

    context "when the deprecate_faculty_journal feature flag is enabled" do
      it "does not create a user note" do
        course_with_teacher(active_all: true)
        @course.enroll_user(target, "StudentEnrollment").accept!

        user_session(@teacher)
        expect do
          post "create", params: {
            user_id: target.id,
            user_note: {
              note: "this is a note",
              title: "this is a title",
              user_id: target.id
            }
          }
        end.to_not change { UserNote.count }
      end
    end
  end
end
