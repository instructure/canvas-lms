#
# Copyright (C) 2018 - present Instructure, Inc.
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

require_relative '../helpers/developer_keys_rewrite_common'

describe 'Developer Keys' do
  include_context 'in-process server selenium tests'
  include DeveloperKeysRewriteCommon

  # We want to force the usage of the fallback scope mapper here, not the generated version
  Object.const_set("ApiScopeMapper", ApiScopeMapperLoader.api_scope_mapper_fallback)

  describe 'with developer key management UI rewrite feature flag' do
    before(:each) do
      admin_logged_in
      Setting.set(Setting::SITE_ADMIN_ACCESS_TO_NEW_DEV_KEY_FEATURES, 'true')
      Account.default.enable_feature!(:developer_key_management_ui_rewrite)
      Account.site_admin.allow_feature!(:api_token_scoping)
      Account.default.enable_feature!(:api_token_scoping)
    end

    let(:root_developer_key) do
      Account.default.developer_keys.create!(
        name: 'Cool Tool',
        email: 'admin@example.com',
        redirect_uris: ['http://example.com'],
        icon_url: '/images/delete.png'
      )
    end

    let(:site_admin_developer_key) do
      DeveloperKey.create!(
        name: 'Site Admin Dev Key',
        email: 'siteadmin@example.com',
        redirect_uris: ['http://example.com'],
        icon_url: '/images/delete.png'
      )
    end

    it "allows creation through 'add developer key button'", test_id: 344077 do
      get "/accounts/#{Account.default.id}/developer_keys"

      find_button("Developer Key").click
      f("input[name='developer_key[name]']").send_keys("Cool Tool")
      f("input[name='developer_key[email]']").send_keys("admin@example.com")
      f("textarea[name='developer_key[redirect_uris]']").send_keys("http://example.com")
      f("input[name='developer_key[icon_url]']").send_keys("/images/delete.png")
      click_enforce_scopes
      click_scope_group_checkbox
      find_button("Save Key").click
      expect(ff("#reactContent tbody tr").length).to eq 1
      expect(Account.default.developer_keys.count).to eq 1
      key = Account.default.developer_keys.last
      expect(key.name).to eq "Cool Tool"
      expect(key.email).to eq "admin@example.com"
      expect(key.redirect_uris).to eq ["http://example.com"]
      expect(key.icon_url).to eq "/images/delete.png"
    end

    it "allows update through 'edit this key button'", test_id: 344078 do
      root_developer_key
      get "/accounts/#{Account.default.id}/developer_keys"
      click_edit_icon
      wait_for_ajaximations
      replace_content(f("input[name='developer_key[name]']"), "Cooler Tool")
      replace_content(f("input[name='developer_key[email]']"), "admins@example.com")
      replace_content(f("textarea[name='developer_key[redirect_uris]']"), "http://b/")
      replace_content(f("input[name='developer_key[icon_url]']"), "/images/add.png")
      click_enforce_scopes
      click_scope_group_checkbox
      find_button("Save Key").click

      expect(ff("#reactContent tbody tr").length).to eq 1
      expect(Account.default.developer_keys.count).to eq 1
      key = Account.default.developer_keys.last
      expect(key.name).to eq "Cooler Tool"
      expect(key.email).to eq "admins@example.com"
      expect(key.redirect_uris).to eq ["http://b/"]
      expect(key.icon_url).to eq "/images/add.png"
    end

    it 'allows editing of legacy redirect URI', test_id: 3469351 do
      dk = root_developer_key
      dk.update_attribute(:redirect_uri, "http://a/")
      get "/accounts/#{Account.default.id}/developer_keys"
      click_edit_icon
      wait_for_ajaximations
      replace_content(f("input[name='developer_key[name]']"), "Cooler Tool")
      replace_content(f("input[name='developer_key[email]']"), "admins@example.com")
      replace_content(f("input[name='developer_key[redirect_uri]']"), "https://b/")
      replace_content(f("input[name='developer_key[icon_url]']"), "/images/add.png")
      click_enforce_scopes
      click_scope_group_checkbox
      find_button("Save Key").click

      expect(ff("#reactContent tbody tr").length).to eq 1
      expect(Account.default.developer_keys.count).to eq 1
      key = Account.default.developer_keys.last
      expect(key.name).to eq "Cooler Tool"
      expect(key.email).to eq "admins@example.com"
      expect(key.redirect_uri).to eq "https://b/"
      expect(key.icon_url).to eq "/images/add.png"
    end

    it "allows deletion through 'delete this key button'", test_id: 344079 do
      skip_if_safari(:alert)
      root_developer_key
      get "/accounts/#{Account.default.id}/developer_keys"
      click_edit_icon
      f("input[name='developer_key[icon_url]']").clear
      click_enforce_scopes
      click_scope_group_checkbox
      find_button("Save Key").click

      expect(ff("#reactContent tbody tr").length).to eq 1
      expect(Account.default.developer_keys.count).to eq 1
      key = Account.default.developer_keys.last
      expect(key.icon_url).to eq nil

      fj("table[data-automation='devKeyAdminTable'] tbody tr.key button:has(svg[name='IconTrash'])").click
      driver.switch_to.alert.accept
      driver.switch_to.default_content
      expect(f("table[data-automation='devKeyAdminTable']")).not_to contain_css("tbody tr")
      expect(Account.default.developer_keys.nondeleted.count).to eq 0
    end

    it "allows for pagination on account tab", test_id: 344532 do
      11.times { |i| Account.default.developer_keys.create!(name: "tool #{i}") }
      get "/accounts/#{Account.default.id}/developer_keys"
      expect(ff("table[data-automation='devKeyAdminTable'] tbody tr")).to have_size(10)
      find_button("Show All Keys").click
      expect(ff("table[data-automation='devKeyAdminTable'] tbody tr")).to have_size(11)
    end

    it "allows for pagination on inherited tab", test_id: 344532 do
      site_admin_logged_in
      11.times { |i| DeveloperKey.create!(name: "tool #{i}") }
      DeveloperKey.all.each { |key| key.update(visible: true) }
      get "/accounts/#{Account.default.id}/developer_keys"
      click_inherited_tab
      expect(ff("table[data-automation='devKeyAdminTable'] tbody tr")).to have_size(10)
      find_button("Show All Keys").click
      expect(ff("table[data-automation='devKeyAdminTable'] tbody tr")).to have_size(11)
    end

    it "renders the key not visible by default upon creation", test_id: 3485785 do
      site_admin_developer_key
      site_admin_logged_in
      get "/accounts/site_admin/developer_keys"
      expect(f("table[data-automation='devKeyAdminTable'] tr.key")).to contain_css("svg[name='IconOff']")
      expect(site_admin_developer_key.reload.visible).to eq false
    end

    it "renders the key visible", test_id: 3485785 do
      site_admin_developer_key
      site_admin_logged_in
      get "/accounts/site_admin/developer_keys"
      fj("table[data-automation='devKeyAdminTable'] button:has(svg[name='IconOff'])").click
      expect(f("table[data-automation='devKeyAdminTable'] tr.key")).not_to contain_css("svg[name='IconOff']")
      expect(site_admin_developer_key.reload.visible).to eq true
    end

    context "Account Binding" do
      it "creates an account binding with default workflow_state 'off'", test_id: 3482823 do
        site_admin_developer_key
        expect(DeveloperKeyAccountBinding.last.workflow_state).to eq 'off'
        expect(DeveloperKeyAccountBinding.last.account_id).to eq Account.site_admin.id
      end

      it "site admin dev key is visible and set to 'off' in root account", test_id: 3482823 do
        site_admin_developer_key.update(visible: true)
        get "/accounts/#{Account.default.id}/developer_keys"
        click_inherited_tab
        expect(fj("input[type='radio']:checked").attribute('value')).to eq 'off'
        expect(DeveloperKeyAccountBinding.last.reload.workflow_state).to eq 'off'
      end

      it "root account inherits 'on' binding workflow state from site admin key", test_id: 3482823 do
        site_admin_logged_in
        site_admin_developer_key.update(visible: true)
        get "/accounts/site_admin/developer_keys"
        fj("span:contains('On'):last").click
        get "/accounts/#{Account.default.id}/developer_keys"
        click_inherited_tab
        expect(fj("fieldset:last").attribute('aria-disabled')).to eq 'true'
        expect(DeveloperKeyAccountBinding.last.reload.workflow_state).to eq 'on'
      end

      it "root account inherits 'off' binding workflow state from site admin key", test_id: 3482823 do
        site_admin_logged_in
        site_admin_developer_key.update(visible: true)
        get "/accounts/site_admin/developer_keys"
        fj("span:contains('Off'):last").click
        get "/accounts/#{Account.default.id}/developer_keys"
        click_inherited_tab
        # checks that the state toggle is disabled from interaction
        expect(fj("fieldset:last").attribute('aria-disabled')).to eq 'true'
        expect(DeveloperKeyAccountBinding.last.reload.workflow_state).to eq 'off'
      end

      it "root account keeps self binding workflow state if site admin key state is 'allow'", test_id: 3482823 do
        site_admin_logged_in
        site_admin_developer_key.update!(visible: true)
        site_admin_developer_key.developer_key_account_bindings.first.update!(workflow_state: 'allow')
        get "/accounts/#{Account.default.id}/developer_keys"
        click_inherited_tab
        fj("span:contains('On'):last").click
        get "/accounts/site_admin/developer_keys"
        fj("span:contains('Off'):last").click
        expect(DeveloperKeyAccountBinding.where(account_id: Account.site_admin.id).first.workflow_state).to eq 'off'
        fj("span:contains('Allow'):last").click
        get "/accounts/#{Account.default.id}/developer_keys"
        click_inherited_tab
        expect(DeveloperKeyAccountBinding.where(account_id: Account.default.id).first.workflow_state).to eq 'on'
        # checks that the state toggle is enabled for interaction
        expect(fj("fieldset:last")).not_to have_attribute('aria-disabled')
      end

      it "allows for root account dev key status 'on'", test_id: 3482823 do
        root_developer_key
        get "/accounts/#{Account.default.id}/developer_keys"
        fj("span:contains('On'):last").click
        keep_trying_until { expect(current_active_element.attribute('value')).to eq 'on' }
        expect(DeveloperKeyAccountBinding.last.reload.workflow_state).to eq 'on'
      end

      it "allows for root account dev key status 'off'", test_id: 3482823 do
        root_developer_key
        DeveloperKeyAccountBinding.last.update(workflow_state: 'on')
        get "/accounts/#{Account.default.id}/developer_keys"
        fj("span:contains('Off'):last").click
        keep_trying_until { expect(current_active_element.attribute('value')).to eq 'off' }
        expect(DeveloperKeyAccountBinding.last.reload.workflow_state).to eq 'off'
      end

      it "persists state when switching between account and inheritance tabs", test_id: 3488599 do
        root_developer_key
        get "/accounts/#{Account.default.id}/developer_keys"
        fj("span:contains('On'):last").click
        click_inherited_tab
        click_account_tab
        expect(fxpath("//*[@data-automation='devKeyAdminTable']/tbody/tr/td[5]/fieldset/span/span/span/span[2]/span/span/span[1]/div/label/span[1]").css_value('background-color')).to be_truthy
      end

      it "persists state when switching between inheritance and account tabs", test_id: 3488600 do
        site_admin_developer_key
        DeveloperKey.find(site_admin_developer_key.id).update(visible: true)
        DeveloperKeyAccountBinding.first.update(workflow_state: 'allow')
        get "/accounts/#{Account.default.id}/developer_keys"
        click_inherited_tab
        fj("span:contains('Off'):last").click
        click_account_tab
        click_inherited_tab
        expect(fj("fieldset:last")).not_to have_attribute('aria-disabled')
        expect(fxpath("//*[@data-automation='devKeyAdminTable']/tbody/tr[1]/td[3]/fieldset/span/span/span/span[2]/span/span/span[2]/div/label/span[2]").css_value('background-color')).to be_truthy
      end

      it "only show create developer key button for account tab panel" do
        get "/accounts/#{Account.default.id}/developer_keys"
        expect(fj("#reactContent span:contains('Developer Key')")).to be_truthy
        click_inherited_tab
        expect(f("#reactContent")).not_to contain_jqcss("span:contains('Developer Key')")
      end
    end

    context "scopes" do
      let(:expected_scopes) do
        [
          "url:GET|/api/v1/courses/:course_id/assignment_groups/:assignment_group_id",
          "url:POST|/api/v1/courses/:course_id/assignment_groups",
          "url:PUT|/api/v1/courses/:course_id/assignment_groups/:assignment_group_id",
          "url:DELETE|/api/v1/courses/:course_id/assignment_groups/:assignment_group_id"
        ]
      end

      it "does not have enforce scopes toggle activated on initial dev key creation" do
        get "/accounts/#{Account.default.id}/developer_keys"
        find_button("Developer Key").click
        expect(f("span[data-automation='enforce_scopes']")).to contain_css("svg[name='IconXSolid']")
        expect(f("form")).to contain_jqcss("h2:contains('When scope enforcement is disabled, tokens have access to all endpoints available to the authorizing user.')")
      end

      it "enforce scopes toggle allows scope creation" do
        expand_scope_group_by_filter('assignment_groups_api', Account.default.id)
        click_scope_group_checkbox
        expect(f("span[data-automation='enforce_scopes']")).to contain_css("svg[name='IconCheckSolid']")
        find_button("Save Key").click
        wait_for_ajaximations
        expect(DeveloperKey.last.require_scopes).to eq true
      end

      it "allows filtering by scope group name" do
        expand_scope_group_by_filter('assignment_groups_api', Account.default.id)
        expect(ff(".toggle-scope-group")).to have_size(1)
      end

      it "expands scope group when group name is selected" do
        expand_scope_group_by_filter('assignment_groups_api', Account.default.id)
        expect(f(".toggle-scope-group button").attribute('aria-expanded')).to eq 'true'
        expect(ff(".toggle-scope-group .developer-key-scope")).to have_size(4)
      end

      it "includes proper scopes for scope group" do
        expand_scope_group_by_filter('assignment_groups_api', Account.default.id)
        scope_group = f(".toggle-scope-group")
        expect(scope_group).to contain_css("span[title='GET']")
        expect(scope_group).to contain_css("span[title='POST']")
        expect(scope_group).to contain_css("span[title='PUT']")
        expect(scope_group).to contain_css("span[title='DELETE']")
      end

      it "scope group select all checkbox adds all associated scopes" do
        expand_scope_group_by_filter('assignment_groups_api', Account.default.id)
        click_scope_group_checkbox
        # checks that all UI pills have been added to scope group if selected
        expect(ff(".toggle-scope-group span[title='GET']")).to have_size(2)
        expect(ff(".toggle-scope-group span[title='POST']")).to have_size(2)
        expect(ff(".toggle-scope-group span[title='PUT']")).to have_size(2)
        expect(ff(".toggle-scope-group span[title='DELETE']")).to have_size(2)
      end

      it "scope group individual checkbox adds only associated scope" do
        expand_scope_group_by_filter('assignment_groups_api', Account.default.id)
        click_scope_checkbox
        # adds a UI pill to scope group with http verb if scope selected
        expect(ff(".toggle-scope-group span[title='GET']")).to have_size(2)
        expect(ff(".toggle-scope-group span[title='POST']")).to have_size(1)
        expect(ff(".toggle-scope-group span[title='PUT']")).to have_size(1)
        expect(ff(".toggle-scope-group span[title='DELETE']")).to have_size(1)
      end

      it "adds scopes to backend developer key via UI" do
        expand_scope_group_by_filter('assignment_groups_api', Account.default.id)
        click_scope_group_checkbox
        find_button("Save Key").click
        wait_for_ajaximations
        expect(DeveloperKey.last.scopes).to eq expected_scopes
      end

      it "adds scopes to backend developer key via UI in site admin" do
        site_admin_logged_in
        expand_scope_group_by_filter('assignment_groups_api', Account.site_admin.id)
        click_scope_group_checkbox
        find_button("Save Key").click
        wait_for_ajaximations
        expect(DeveloperKey.last.scopes).to eq expected_scopes
      end

      it "removes scopes from backend developer key via UI" do
        skip 'will be fixed in PLAT-3391'
        expand_scope_group_by_filter('assignment_groups_api', Account.default.id)
        click_scope_group_checkbox
        find_button("Save Key").click
        click_edit_icon
        filter_scopes_by_name 'assignment_groups_api'
        click_scope_group_checkbox
        dk = DeveloperKey.last
        find_button("Save Key").click
        wait_for_ajaximations
        expect(dk.reload.scopes).not_to eq expected_scopes
      end

      it "keeps all endpoints read only checkbox checked after save" do
        skip 'will be fixed in PLAT-3391'
        get "/accounts/#{Account.default.id}/developer_keys"
        find_button("Developer Key").click
        click_enforce_scopes
        select_all_readonly_checkbox.click
        find_button("Save Key").click
        click_edit_icon
        expect(all_endpoints_readonly_checkbox_selected?).to eq true
      end

      it "keeps all endpoints read only checkbox checked if check/unchecking another http method" do
        expand_scope_group_by_filter('assignment_groups_api', Account.default.id)
        select_all_readonly_checkbox.click
        click_scope_checkbox
        expect(f(".toggle-scope-group input[type='checkbox']").selected?).to eq false
        click_scope_checkbox
        expect(all_endpoints_readonly_checkbox_selected?).to eq true
      end
    end
  end

end
