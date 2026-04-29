# frozen_string_literal: true

#
# Copyright (C) 2025 - present Instructure, Inc.
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

require_relative "../api_spec_helper"

describe PermissionsHelpController, type: :request do
  describe "help" do
    it "requires a user" do
      api_call(:get,
               "/api/v1/permissions/account/temporary_enrollments_add/help",
               { controller: "permissions_help",
                 action: "help",
                 format: "json",
                 context_type: "account",
                 permission: "temporary_enrollments_add" },
               {},
               {},
               { expected_status: 401 })
    end

    context "as an admin user" do
      before :once do
        account_admin_user
      end

      before do
        user_session(@admin)
      end

      it "returns information about an account permission" do
        json = api_call(:get,
                        "/api/v1/permissions/account/become_user/help",
                        { controller: "permissions_help",
                          action: "help",
                          format: "json",
                          context_type: "account",
                          permission: "become_user" })
        expect(json["details"][0]["title"]).to include "People"
        expect(json["details"][0]["description"]).to include "act as"
        expect(json["considerations"][-1]["title"]).to include "Subaccounts"
        expect(json["considerations"][-1]["description"]).to include "Not available at the subaccount level"
      end

      it "returns information about a course permission" do
        json = api_call(:get,
                        "/api/v1/permissions/course/manage_tags_add/help",
                        { controller: "permissions_help",
                          action: "help",
                          format: "json",
                          context_type: "course",
                          permission: "manage_tags_add" })
        expect(json["details"][-1]["title"]).to include "Warning"
        expect(json["details"][-1]["description"]).to include "edit a differentiation tag"
      end

      it "returns information about an account permission group" do
        json = api_call(:get,
                        "/api/v1/permissions/account/manage_temporary_enrollments/help",
                        { controller: "permissions_help",
                          action: "help",
                          format: "json",
                          context_type: "account",
                          permission: "manage_temporary_enrollments" })
        expect(json["details"][0]["title"]).to include "Temporary Enrollments"
        expect(json["details"][0]["description"]).to include "Temporarily enroll a user"
      end

      it "returns information about a course permission group" do
        json = api_call(:get,
                        "/api/v1/permissions/course/manage_differentiation_tags/help",
                        { controller: "permissions_help",
                          action: "help",
                          format: "json",
                          context_type: "course",
                          permission: "manage_differentiation_tags" })
        expect(json["details"][-1]["title"]).to include "Warning"
        expect(json["details"][-1]["description"]).to include "data about differentiation tags"
      end
    end
  end
end
