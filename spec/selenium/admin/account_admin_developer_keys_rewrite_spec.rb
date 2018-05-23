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

require File.expand_path(File.dirname(__FILE__) + '/../common')

describe 'Developer Keys' do
  include_context 'in-process server selenium tests'

  describe 'with developer key management UI rewrite feature flag' do
    before(:each) do
      admin_logged_in
      Account.default.enable_feature!(:developer_key_management_ui_rewrite)
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

    def click_inherited_tab
      fj("span:contains('Inherited'):last").click
      wait_for_ajaximations
    end

    def click_account_tab
      fj("#reactContent span[role='tablist'] span:contains('Account')").click
      wait_for_ajaximations
    end

    it "allows creation through 'add developer key button'", test_id: 344077 do
      get "/accounts/#{Account.default.id}/developer_keys"

      find_button("Developer Key").click
      f("input[name='developer_key[name]']").send_keys("Cool Tool")
      f("input[name='developer_key[email]']").send_keys("admin@example.com")
      f("textarea[name='developer_key[redirect_uris]']").send_keys("http://example.com")
      f("input[name='developer_key[icon_url]']").send_keys("/images/delete.png")
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
      fj("#keys tbody tr.key button:has(svg[name='IconEditLine'])").click
      replace_content(f("input[name='developer_key[name]']"), "Cooler Tool")
      replace_content(f("input[name='developer_key[email]']"), "admins@example.com")
      replace_content(f("textarea[name='developer_key[redirect_uris]']"), "http://b/")
      replace_content(f("input[name='developer_key[icon_url]']"), "/images/add.png")
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
      fj("#keys tbody tr.key button:has(svg[name='IconEditLine'])").click
      replace_content(f("input[name='developer_key[name]']"), "Cooler Tool")
      replace_content(f("input[name='developer_key[email]']"), "admins@example.com")
      replace_content(f("input[name='developer_key[redirect_uri]']"), "https://b/")
      replace_content(f("input[name='developer_key[icon_url]']"), "/images/add.png")
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
      fj("#keys tbody tr.key button:has(svg[name='IconEditLine'])").click
      f("input[name='developer_key[icon_url]']").clear
      find_button("Save Key").click

      expect(ff("#reactContent tbody tr").length).to eq 1
      expect(Account.default.developer_keys.count).to eq 1
      key = Account.default.developer_keys.last
      expect(key.icon_url).to eq nil

      fj("#keys tbody tr.key button:has(svg[name='IconTrashLine'])").click
      driver.switch_to.alert.accept
      driver.switch_to.default_content
      expect(f("#keys")).not_to contain_css("tbody tr")
      expect(Account.default.developer_keys.nondeleted.count).to eq 0
    end

    it "allows for pagination on account tab", test_id: 344532 do
      11.times { |i| Account.default.developer_keys.create!(name: "tool #{i}") }
      get "/accounts/#{Account.default.id}/developer_keys"
      expect(ff("#keys tbody tr")).to have_size(10)
      find_button("Show All Keys").click
      expect(ff("#keys tbody tr")).to have_size(11)
    end

    it "allows for pagination on inherited tab", test_id: 344532 do
      site_admin_logged_in
      11.times { |i| DeveloperKey.create!(name: "tool #{i}") }
      DeveloperKey.all.each { |key| key.update(visible: true) }
      get "/accounts/#{Account.default.id}/developer_keys"
      click_inherited_tab
      expect(ff("#keys tbody tr")).to have_size(10)
      find_button("Show All Keys").click
      expect(ff("#keys tbody tr")).to have_size(11)
    end

    it "renders the key not visible", test_id: 3485785 do
      root_developer_key
      get "/accounts/#{Account.default.id}/developer_keys"
      fj("#keys tbody tr.key button:has(svg[name='IconEyeLine'])").click
      expect(f("#keys tbody tr.key")).to contain_css("svg[name='IconOffLine']")
      expect(root_developer_key.reload.visible).to eq false
    end

    it "renders the key visible", test_id: 3485785 do
      root_developer_key.update(visible: false)
      get "/accounts/#{Account.default.id}/developer_keys"
      fj("#keys tbody tr.key button:has(svg[name='IconOffLine'])").click
      expect(f("#keys tbody tr.key")).not_to contain_css("svg[name='IconOffLine']")
      expect(root_developer_key.reload.visible).to eq true
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
        pending 'This test will be valid once the "new developer keys" site admin setting exists'
        site_admin_logged_in
        site_admin_developer_key.update(visible: true)
        get "/accounts/#{Account.site_admin.id}/developer_keys"
        fj("span:contains('On'):last").click
        get "/accounts/#{Account.default.id}/developer_keys"
        click_inherited_tab
        expect(fj("fieldset:last").attribute('aria-disabled')).to eq 'true'
        expect(DeveloperKeyAccountBinding.last.reload.workflow_state).to eq 'on'
      end

      it "root account inherits 'off' binding workflow state from site admin key", test_id: 3482823 do
        pending 'This test will be valid once the "new developer keys" site admin setting exists'
        site_admin_logged_in
        site_admin_developer_key.update(visible: true)
        get "/accounts/#{Account.site_admin.id}/developer_keys"
        fj("span:contains('Off'):last").click
        get "/accounts/#{Account.default.id}/developer_keys"
        click_inherited_tab
        expect(fj("fieldset:last").attribute('aria-disabled')).to eq 'true'
        expect(DeveloperKeyAccountBinding.last.reload.workflow_state).to eq 'off'
      end

      it "root account keeps self binding workflow state if site admin key state is 'allow'", test_id: 3482823 do
        pending 'This test will be valid once the "new developer keys" site admin setting exists'
        site_admin_logged_in
        site_admin_developer_key.update!(visible: true)
        site_admin_developer_key.developer_key_account_bindings.first.update!(workflow_state: 'allow')
        get "/accounts/#{Account.default.id}/developer_keys"
        click_inherited_tab
        fj("span:contains('On'):last").click
        get "/accounts/#{Account.site_admin.id}/developer_keys"
        fj("span:contains('Off'):last").click
        expect(DeveloperKeyAccountBinding.where(account_id: Account.site_admin.id).first.workflow_state).to eq 'off'
        fj("span:contains('Allow'):last").click
        get "/accounts/#{Account.default.id}/developer_keys"
        click_inherited_tab
        expect(DeveloperKeyAccountBinding.where(account_id: Account.default.id).first.workflow_state).to eq 'on'
        expect(fj("fieldset:last")).not_to have_attribute('aria-disabled')
      end

      it "allows for root account dev key status 'allow'", test_id: 3482823 do
        root_developer_key
        DeveloperKeyAccountBinding.last.update(workflow_state: 'off')
        get "/accounts/#{Account.default.id}/developer_keys"
        fj("span:contains('Allow'):last").click
        keep_trying_until { expect(current_active_element.attribute('value')).to eq 'allow' }
        expect(DeveloperKeyAccountBinding.last.reload.workflow_state).to eq 'allow'
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
        expect(fxpath("//*[@id='keys']/tbody/tr/td[5]/fieldset/span/span/span/span[2]/span/span/span[1]/div/label/span[1]").css_value('background-color')).to be_truthy
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
        expect(fxpath("//*[@id='keys']/tbody/tr[1]/td[3]/fieldset/span/span/span/span[2]/span/span/span[3]/div/label/span[1]").css_value('background-color')).to be_truthy
      end

      it "only show create developer key button for account tab panel" do
        get "/accounts/#{Account.default.id}/developer_keys"
        expect(fj("#reactContent span:contains('Developer Key')")).to be_truthy
        click_inherited_tab
        expect(f("#reactContent")).not_to contain_jqcss("span:contains('Developer Key')")
      end

    end
  end

end
