# frozen_string_literal: true

#
# Copyright (C) 2011 - present Instructure, Inc.
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

describe SubAccountsController do
  describe "POST 'create'" do
    it "creates sub-accounts with the right root account when inside the root account" do
      root_account = Account.default
      account_admin_user(active_all: true)
      user_session(@user)

      post "create", params: { account_id: root_account.id, account: { parent_account_id: root_account.id, name: "sub account" } }
      sub_account = assigns[:sub_account]
      expect(sub_account).not_to be_nil

      post "create", params: { account_id: root_account.id, account: { parent_account_id: sub_account.id, name: "sub sub account 1" } }
      sub_sub_account_1 = assigns[:sub_account]
      expect(sub_sub_account_1).not_to be_nil
      expect(sub_sub_account_1.name).to eq "sub sub account 1"
      expect(sub_sub_account_1.parent_account).to eq sub_account
      expect(sub_sub_account_1.root_account).to eq root_account
    end

    it "creates sub-accounts with the right root account when inside a sub account" do
      root_account = Account.default
      account_admin_user(active_all: true)
      user_session(@user)

      sub_account = root_account.sub_accounts.create(name: "sub account")

      post "create", params: { account_id: sub_account.id, account: { parent_account_id: sub_account.id, name: "sub sub account 2" } }
      sub_sub_account_2 = assigns[:sub_account]
      expect(sub_sub_account_2).not_to be_nil
      expect(sub_sub_account_2.name).to eq "sub sub account 2"
      expect(sub_sub_account_2.parent_account).to eq sub_account
      expect(sub_sub_account_2.root_account).to eq root_account
    end

    it "reports errors encountered while creating a sub account" do
      root_account = Account.default
      account_admin_user(active_all: true)
      user_session(@user)
      post "create", params: { account_id: root_account.id, account: { sis_account_id: "C001", name: "sub account 1" } }
      expect(response).to have_http_status(:ok)
      post "create", params: { account_id: root_account.id, account: { sis_account_id: "C001", name: "sub account 2" } }
      expect(response).to have_http_status(:bad_request)
      expect(response.parsed_body).to have_key("errors")
    end
  end

  describe "GET 'index'" do
    it "preloads all necessary information" do
      root_account = Account.create(name: "new account")
      account_admin_user(active_all: true, account: root_account)
      user_session(@user)

      # no sub accounts or courses
      sub_account_1 = root_account.sub_accounts.create!

      # 2 courses, 1 deleted
      sub_account_2 = root_account.sub_accounts.create!
      Course.create!(account: sub_account_2)
      Course.create!(account: sub_account_2) { |c| c.workflow_state = "deleted" }

      # 1 course, 2 sections
      sub_account_3 = root_account.sub_accounts.create!
      course = Course.create!(account: sub_account_3)
      course.course_sections.create!
      course.course_sections.create!

      # deeply nested sub account; sub_sub_account won't be visible
      sub_account_4 = root_account.sub_accounts.create!
      sub_sub_account = sub_account_4.sub_accounts.create!
      sub_sub_sub_account = sub_sub_account.sub_accounts.create!
      # add one more, then delete it; the count should remain the same
      sub_sub_account.sub_accounts.create! { |sa| sa.workflow_state = "deleted" }

      # 150 sub_accounts; these sub_accounts won't be visible
      sub_account_5 = root_account.sub_accounts.create!
      150.times { sub_account_5.sub_accounts.create! }
      # give one of them a course (which previously triggered a bug)
      Course.create!(account: sub_account_5.sub_accounts.last)
      # add one more, then delete it; count should remain unchanged
      sub_account_5.sub_accounts.create! { |sa| sa.workflow_state = "deleted" }

      other_account = Account.create!
      other_course = other_account.courses.create!

      section = course.course_sections.create!
      section.crosslist_to_course(other_course)

      get "index", params: { account_id: root_account.id }

      @accounts = assigns[:accounts]
      expect(@accounts[root_account.id][:sub_account_count]).to eq 5
      expect(@accounts[root_account.id][:course_count]).to eq 0
      expect(@accounts[root_account.id][:sub_account_ids].sort).to eq [sub_account_1.id, sub_account_2.id, sub_account_3.id, sub_account_4.id, sub_account_5.id].sort

      expect(@accounts[sub_account_1.id][:sub_account_count]).to eq 0
      expect(@accounts[sub_account_1.id][:course_count]).to eq 0
      expect(@accounts[sub_account_1.id][:sub_account_ids]).to eq []

      expect(@accounts[sub_account_2.id][:sub_account_count]).to eq 0
      expect(@accounts[sub_account_2.id][:course_count]).to eq 1

      expect(@accounts[sub_account_3.id][:sub_account_count]).to eq 0
      expect(@accounts[sub_account_3.id][:course_count]).to eq 1

      expect(@accounts[sub_account_4.id][:sub_account_count]).to eq 1
      expect(@accounts[sub_account_4.id][:sub_account_ids]).to eq [sub_sub_account.id]
      expect(@accounts[sub_sub_account.id][:sub_account_count]).to eq 1
      expect(@accounts[sub_sub_account.id][:sub_account_ids]).to eq []
      expect(@accounts[sub_sub_sub_account.id]).to be_nil

      expect(@accounts[sub_account_5.id][:sub_account_count]).to eq 150
      expect(@accounts[sub_account_2.id][:sub_account_ids]).to eq []
    end

    it "includes a root account when searching if requested" do
      root_account = Account.create(name: "account")
      sub_account = root_account.sub_accounts.create!(name: "sub account")
      account_admin_user(active_all: true, account: root_account)
      user_session(@user)

      get "index", params: { account_id: root_account.id, term: "Acc" }, format: :json
      res = json_parse
      expect(res.count).to eq 1
      expect(res.first["id"]).to eq sub_account.id

      get "index", params: { account_id: root_account.id, term: "Acc", include_self: "1" }, format: :json
      res = json_parse
      expect(res.count).to eq 2
      expect(res.pluck("id")).to match_array [root_account.id, sub_account.id]
    end

    describe "permissions" do
      before :once do
        @root_account = Account.create!(name: "root")
        @sub_account = @root_account.sub_accounts.create!(name: "sub")
      end

      it "accepts :manage_courses permission if term query param is provided" do
        @root_account.disable_feature!(:granular_permissions_manage_courses)
        admin = account_admin_user_with_role_changes(role_changes: { manage_account_settings: false, manage_courses: true }, account: @root_account, role: Role.get_built_in_role("AccountMembership", root_account_id: @root_account))
        user_session(admin)
        get "index", params: { term: "sub-account", account_id: @root_account.id }
        expect(response).to have_http_status :ok
      end

      it "accepts :manage_courses_admin permission if term query param is provided (granular permissions)" do
        @root_account.enable_feature!(:granular_permissions_manage_courses)
        admin =
          account_admin_user_with_role_changes(
            role_changes: {
              manage_account_settings: false,
              manage_courses_admin: true
            },
            account: @root_account,
            role: Role.get_built_in_role("AccountMembership", root_account_id: @root_account)
          )
        user_session(admin)
        get "index", params: { term: "sub-account", account_id: @root_account.id }
        expect(response).to have_http_status :ok
      end

      it "requires account credentials" do
        course_with_teacher_logged_in(active_all: true)
        get "index", params: { account_id: @root_account.id }
        expect(response).to have_http_status :unauthorized
      end
    end
  end

  describe "DELETE 'destroy'" do
    before(:once) do
      @root_account = Account.create(name: "new account")
      account_admin_user(active_all: true, account: @root_account)
      @sub_account = @root_account.sub_accounts.create!
    end

    it "requires :manage_account_settings permission" do
      lame_admin = account_admin_user_with_role_changes(role_changes: { manage_account_settings: false, manage_courses: true }, account: @root_account, role: Role.get_built_in_role("AccountMembership", root_account_id: @root_account))
      user_session(lame_admin)
      delete "destroy", params: { account_id: @root_account, id: @sub_account }
      expect(response).to have_http_status :unauthorized
    end

    it "deletes a sub-account" do
      user_session(@user)
      delete "destroy", params: { account_id: @root_account, id: @sub_account }
      expect(response).to have_http_status(:ok)
      expect(@sub_account.reload).to be_deleted
    end

    it "deletes a sub-account that contains a deleted course" do
      @sub_account.courses.create!
      @sub_account.courses.first.destroy
      user_session(@user)
      delete "destroy", params: { account_id: @root_account, id: @sub_account }
      expect(response).to have_http_status(:ok)
      expect(@sub_account.reload).to be_deleted
    end

    it "does not delete a sub-account that contains a course" do
      @sub_account.courses.create!
      user_session(@user)
      delete "destroy", params: { account_id: @root_account, id: @sub_account }
      expect(response).to have_http_status(:conflict)
      expect(@sub_account.reload).not_to be_deleted
    end

    it "does not delete a sub-account that contains a sub-account that contains a course" do
      @sub_sub_account = @sub_account.sub_accounts.create!
      @sub_sub_account.courses.create!
      user_session(@user)
      delete "destroy", params: { account_id: @root_account, id: @sub_account }
      expect(response).to have_http_status(:conflict)
      expect(@sub_account.reload).not_to be_deleted
    end

    it "does not delete a sub-account that contains a sub-account" do
      @sub_sub_account = @sub_account.sub_accounts.create!
      user_session(@user)
      delete "destroy", params: { account_id: @root_account, id: @sub_account }
      expect(response).to have_http_status(:conflict)
      expect(@sub_account.reload).not_to be_deleted
    end

    it "removes assigned template course when deleting a sub-account" do
      @course = @root_account.courses.create!(template: "true")
      user_session(@user)
      @sub_account.course_template_id = @course.id
      @sub_account.save!
      expect(@sub_account.reload.course_template_id).to eq(@course.id)
      delete "destroy", params: { account_id: @root_account, id: @sub_account }
      expect(@sub_account.reload.course_template_id).to be_nil
    end
  end

  describe "GET 'show'" do
    before :once do
      @root_account = Account.create(name: "new account")
      account_admin_user(active_all: true, account: @root_account)
      @sub_account = @root_account.sub_accounts.create!
    end

    before do
      user_session @user
    end

    it "gets sub-accounts in alphabetical order" do
      names = %w[script bank cow program means]
      names.each { |name| Account.create!(name:, parent_account: @sub_account) }
      get "show", params: { account_id: @root_account, id: @sub_account }
      expect(response).to have_http_status :ok
      json = response.parsed_body
      expect(json["account"]["sub_accounts"].map { |sub| sub["account"]["name"] }).to eq names.sort
    end
  end
end
