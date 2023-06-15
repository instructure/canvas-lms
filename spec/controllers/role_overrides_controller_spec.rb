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

describe RoleOverridesController do
  let(:parent_account) { Account.default }

  before do
    @account = account_model(parent_account:)
    account_admin_user(account: @account)
    user_session(@admin)
  end

  describe "add_role" do
    it "adds the role type to the account" do
      expect(@account.available_account_roles.map(&:name)).not_to include("NewRole")
      post "add_role", params: { account_id: @account.id, role_type: "NewRole" }
      @account.reload
      expect(@account.available_account_roles.map(&:name)).to include("NewRole")
    end

    it "requires a role type" do
      post "add_role", params: { account_id: @account.id }
      expect(flash[:error]).to eq "Role creation failed"
    end

    it "fails when given an existing role type" do
      role = @account.roles.build(name: "NewRole")
      role.base_role_type = Role::DEFAULT_ACCOUNT_TYPE
      role.workflow_state = "active"
      role.save!
      post "add_role", params: { account_id: @account.id, role_type: "NewRole" }
      expect(flash[:error]).to eq "Role creation failed"
    end
  end

  describe "remove_role" do
    it "deactivates a role" do
      role = @account.roles.build(name: "NewRole")
      role.base_role_type = Role::DEFAULT_ACCOUNT_TYPE
      role.workflow_state = "active"
      role.save!
      delete "remove_role", params: { account_id: @account.id, id: role.id }
      expect(@account.roles.where(name: "NewRole").first).to be_inactive
    end
  end

  describe "activate_role" do
    before do
      @role = @account.roles.build(name: "NewRole")
      @role.base_role_type = Role::DEFAULT_ACCOUNT_TYPE
      @role.workflow_state = "inactive"
      @role.save!
    end

    it "re-activates a role" do
      post "activate_role", params: { account_id: @account, id: @role }
      expect(@account.roles.where(name: "NewRole").first).to be_active
    end

    it "does not allow unauthorized users to re-activate a role" do
      unauthorized_user = user_factory(active_all: true)
      user_session(unauthorized_user)
      post "activate_role", params: { account_id: @account, id: @role }
      expect(response).to have_http_status :unauthorized
    end

    it "will only re-activate if specified role is inactive" do
      @role.update!(workflow_state: "deleted")
      post "activate_role", params: { account_id: @account, id: @role }
      expect(response).to have_http_status :not_found
      expect(response.body).to include("role not found")
    end

    it "will only re-activate if specified role name does not already exist" do
      @role.update!(workflow_state: "active")
      post "activate_role", params: { account_id: @account, id: @role }
      expect(response).to have_http_status :bad_request
      expect(response.body).to include("An active role already exists with that name")
    end
  end

  describe "update" do
    before do
      @role_name = "NewRole"
      @permission = "read_reports"
      @role = @account.roles.build(name: @role_name)
      @role.base_role_type = Role::DEFAULT_ACCOUNT_TYPE
      @role.workflow_state = "active"
      @role.save!
    end

    def update_permissions(permissions)
      put("update", params: { account_id: @account.id, id: @role.id, permissions: })
    end

    it "lets you update a permission" do
      update_permissions({ @permission => { enabled: true, explicit: true } })
      override = RoleOverride.last
      expect(override.permission).to eq @permission
      expect(override.role_id).to eq @role.id
      expect(override.enabled).to be true
    end

    it "returns an error if the updated permission is invalid" do
      resp = update_permissions({ @permission => { applies_to_descendants: false, applies_to_self: false } })
      expect(resp.status).to eq 400
      expect(resp.body).to include("Permission must be enabled for someone")
      expect(RoleOverride.count).to eq 0
    end

    it "does not commit any changes if any permission update fails" do
      updates = {
        manage_students: { enabled: true, explicit: true },
        read_reports: { applies_to_descendants: false, applies_to_self: false },
      }
      resp = update_permissions(updates)
      expect(resp.status).to eq 400
      expect(resp.body).to include("Permission must be enabled for someone")
      expect(RoleOverride.count).to eq 0
    end

    describe "grouped permissions" do
      before do
        @grouped_permission = "manage_wiki"
        @granular_permissions = %w[manage_wiki_create manage_wiki_delete manage_wiki_update]
      end

      it "updates all permissions in a group" do
        update_permissions({ @grouped_permission => { enabled: true, explicit: true } })
        expect(RoleOverride.count).to eq 3
        expect(RoleOverride.pluck(:permission)).to match_array @granular_permissions
        expect(RoleOverride.pluck(:role_id)).to match_array Array.new(3, @role.id)
        expect(RoleOverride.pluck(:enabled)).to match_array Array.new(3, true)
      end

      it "allows locking all permissions in a group" do
        update_permissions({ @grouped_permission => { locked: true } })
        expect(RoleOverride.count).to eq 3
        expect(RoleOverride.pluck(:locked)).to match_array Array.new(3, true)
      end

      it "preserves granular permission states when unlocking the group" do
        updates = {
          @grouped_permission => { enabled: true, locked: true, explicit: true },
          @granular_permissions[0] => { enabled: false, explicit: true },
        }
        update_permissions(updates)
        expect(RoleOverride.count).to eq 3
        update_permissions({ @grouped_permission => { locked: false, explicit: true } })
        expect(RoleOverride.pluck(:locked)).to match_array Array.new(3, false)
        expect(RoleOverride.pluck(:enabled)).to match_array [true, true, false]
      end

      it "allows updating an individual permissions that belongs to a group" do
        update_permissions({ @granular_permissions[0] => { enabled: true, explicit: true } })
        expect(RoleOverride.count).to eq 1

        override = RoleOverride.last
        expect(override.permission).to eq @granular_permissions[0]
        expect(override.role_id).to eq @role.id
        expect(override.enabled).to be true
      end

      it "does not allow locking an individual permissions that belongs to a group" do
        resp = update_permissions({ @granular_permissions[0] => { locked: true } })
        expect(resp.status).to eq 400
        expect(resp.body).to include("Cannot change locked status on granular permission")
        expect(RoleOverride.count).to eq 0
      end

      it "handles updating a group and individual permission in the same group in one request" do
        updates = {
          @grouped_permission => { enabled: true, explicit: true },
          @granular_permissions[0] => { enabled: false, explicit: true },
        }
        update_permissions(updates)
        expect(RoleOverride.count).to eq 3
        expect(RoleOverride.pluck(:permission)).to match_array @granular_permissions
        expect(RoleOverride.pluck(:role_id)).to match_array Array.new(3, @role.id)
        expect(RoleOverride.pluck(:enabled)).to match_array [true, true, false]
      end
    end
  end

  describe "create" do
    before do
      @role_name = "NewRole"
      @permission = "read_reports"
      @role = @account.roles.build(name: @role_name)
      @role.base_role_type = Role::DEFAULT_ACCOUNT_TYPE
      @role.workflow_state = "active"
      @role.save!
    end

    def post_with_settings(settings = {})
      post "create", params: { account_id: @account.id, account_roles: 1, permissions: { @permission => { @role.id => settings } } }
    end

    describe "override already exists" do
      before do
        @existing_override = @account.role_overrides.build(
          permission: @permission,
          role: @role
        )
        @existing_override.enabled = true
        @existing_override.locked = false
        @existing_override.save!
        @initial_count = @account.role_overrides.size
      end

      it "updates an existing override if override has a value" do
        post_with_settings(override: "unchecked")
        expect(@account.role_overrides.reload.size).to eq @initial_count
        @existing_override.reload
        expect(@existing_override.enabled).to be_falsey
      end

      it "updates an existing override if override is nil but locked is truthy" do
        post_with_settings(locked: "true")
        expect(@account.role_overrides.reload.size).to eq @initial_count
        @existing_override.reload
        expect(@existing_override.locked).to be_truthy
      end

      it "only updates unchecked" do
        post_with_settings(override: "unchecked")
        @existing_override.reload
        expect(@existing_override.locked).to be_falsey
      end

      it "only updates enabled" do
        @existing_override.enabled = true
        @existing_override.save

        post_with_settings(locked: "true")
        @existing_override.reload
        expect(@existing_override.enabled).to be_truthy
      end

      it "deletes an existing override if override is nil and locked is not truthy" do
        post_with_settings(locked: "0")
        expect(@account.role_overrides.reload.size).to eq @initial_count - 1
        expect(RoleOverride.where(id: @existing_override).first).to be_nil
      end
    end

    describe "no override yet" do
      before do
        @initial_count = @account.role_overrides.size
      end

      it "does not create an override if override is nil and locked is not truthy" do
        post_with_settings(locked: "0")
        expect(@account.role_overrides.reload.size).to eq @initial_count
      end

      it "creates the override if override has a value" do
        post_with_settings(override: "unchecked")
        expect(@account.role_overrides.reload.size).to eq @initial_count + 1
        override = @account.role_overrides.where(permission: @permission, role_id: @role.id).first
        expect(override).not_to be_nil
        expect(override.enabled).to be_falsey
      end

      it "creates the override if override is nil but locked is truthy" do
        post_with_settings(locked: "true")
        expect(@account.role_overrides.reload.size).to eq @initial_count + 1
        override = @account.role_overrides.where(permission: @permission, role_id: @role.id).first
        expect(override).not_to be_nil
        expect(override.locked).to be_truthy
      end

      it "sets override as false when override is unchecked" do
        post_with_settings(override: "unchecked")
        override = @account.role_overrides.where(permission: @permission, role_id: @role.id).first
        expect(override).not_to be_nil
        expect(override.enabled).to be false
        expect(override.locked).to be false
        override.destroy
      end

      it "sets the override to locked when specifiying locked" do
        post_with_settings(locked: "true")
        override = @account.role_overrides.where(permission: @permission, role_id: @role.id).first
        expect(override).not_to be_nil
        expect(override.enabled).to be true
        expect(override.locked).to be true
      end
    end
  end

  describe "check_account_permission" do
    let(:json) { json_parse(response.body) }

    describe "manage_catalog permission" do
      context "when catalog is enabled" do
        before do
          a = Account.default
          a.settings[:catalog_enabled] = true
          a.save!
        end

        context "for an admin" do
          it "is true" do
            get "check_account_permission", params: { account_id: @account.id, permission: "manage_catalog" }
            expect(json["granted"]).to be(true)
          end
        end

        context "for a non-admin" do
          it "is false" do
            user_session(user_factory(account: @account))
            get "check_account_permission", params: { account_id: @account.id, permission: "manage_catalog" }
            expect(json["granted"]).to be(false)
          end
        end
      end

      context "when catalog is not enabled" do
        context "for an admin" do
          it "is false" do
            get "check_account_permission", params: { account_id: @account.id, permission: "manage_catalog" }
            expect(json["granted"]).to be(false)
          end
        end
      end
    end

    describe "other permissions" do
      it "returns 400 with an error message" do
        get "check_account_permission", params: { account_id: @account.id, permission: "manage_content" }
        expect(response.code.to_i).to eq(400)
        expect(json["message"]).to be
      end
    end

    describe "GET index" do
      it "loads new bundle for new permissions flag" do
        get "index", params: { account_id: @account.id }
        expect(response).to be_successful
        expect(assigns[:js_bundles].length).to eq 1
        expect(assigns[:js_bundles].first).to include :permissions
      end

      it "does not load the manage_developer_keys role on sub account" do
        get "index", params: { account_id: @account.id }
        expect(assigns.dig(:js_env, :ACCOUNT_ROLES).first[:permissions].keys).to_not include(:manage_developer_keys)
        expect(assigns.dig(:js_env, :ACCOUNT_PERMISSIONS, 0, :group_permissions).any? { |g| g[:permission_name] == :manage_developer_keys }).to be false
      end

      context "in root_account" do
        let(:parent_account) { nil }

        it "does load the manage_developer_keys role on root account" do
          get "index", params: { account_id: @account.id }
          expect(assigns.dig(:js_env, :ACCOUNT_ROLES).first[:permissions].keys).to include(:manage_developer_keys)
          expect(assigns.dig(:js_env, :ACCOUNT_PERMISSIONS, 0, :group_permissions).any? { |g| g[:permission_name] == :manage_developer_keys }).to be true
        end
      end

      context "with granular permissions" do
        before do
          @grouped_permission = "manage_wiki"
          @granular_permissions = %w[manage_wiki_create manage_wiki_delete manage_wiki_update]
        end

        it "sets granular permissions information in the js_env" do
          get "index", params: { account_id: @account.id }

          wiki_permissions = []
          [:ACCOUNT_PERMISSIONS, :COURSE_PERMISSIONS].each do |js_env_key|
            assigns[:js_env][js_env_key].each_with_object(wiki_permissions) do |permission_group, list|
              permission_group[:group_permissions].each do |permission|
                list << permission if permission[:permission_name].to_s.start_with?("manage_wiki")
              end
            end
          end

          expect(wiki_permissions.pluck(:granular_permission_group).uniq).to eq ["manage_wiki"]
          expect(wiki_permissions.pluck(:granular_permission_group_label).uniq).to eq ["Manage Pages"]
        end
      end
    end
  end
end
