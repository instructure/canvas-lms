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
require_relative 'pages/admin_developer_keys_page.rb'

describe 'developer keys' do
  include_context 'in-process server selenium tests'
  include AdminDeveloperKeysPage

  before(:each) do
    admin_logged_in
  end

  context "with new key" do
    it "key settings dialog is displayed when opened" do
      visit_developer_page(Account.default.id)

      add_key_button.click
      expect(f("body")).to contain_css(".ui-dialog[aria-hidden='false']")
      close_dialog_button.click
      expect(f("body")).to contain_css(".ui-dialog[aria-hidden='true']")
    end

    it "allows creation through 'add developer key button'", test_id: 344077 do
      visit_developer_page(Account.default.id)
      expect(keys_table).not_to contain_css("tbody tr")

      add_key_button.click
      edit_key_name("Cool Tool")
      edit_key_email("admin@example.com")
      edit_key_redirect_uris("http://example.com")
      edit_key_icon_url("/images/delete.png")
      submit_dialog(key_settings_dialog_selector, '.submit')
      wait_for_ajaximations

      expect(Account.default.developer_keys.count).to eq 1
      key = Account.default.developer_keys.last
      expect(key.name).to eq "Cool Tool"
      expect(key.email).to eq "admin@example.com"
      expect(key.redirect_uris).to eq ["http://example.com"]
      expect(key.icon_url).to eq "/images/delete.png"
      expect(all_keys.count).to eq 1
    end
  end

  context "with existing key" do
    before(:each) do
      @new_key = Account.default.developer_keys.create!(
        name: 'Cool Tool',
        email: 'admin@example.com',
        redirect_uris: ['http://example.com'],
        icon_url: '/images/delete.png'
      )
    end

    it "edit key settings dialog is displayed when opened" do
      visit_developer_page(Account.default.id)

      edit_key_button(@new_key.id).click
      expect(f("body")).to contain_css(".ui-dialog[aria-hidden='false']")
      close_dialog_button.click
      expect(f("body")).to contain_css(".ui-dialog[aria-hidden='true']")
    end

    it "allows update through 'edit this key button'", test_id: 344078 do
      visit_developer_page(Account.default.id)

      edit_key_button(@new_key.id).click
      edit_key_name("Cooler Tool")
      edit_key_email("admins@example.com")
      edit_key_redirect_uris("http://b/")
      edit_key_icon_url("/images/add.png")
      submit_dialog(key_settings_dialog_selector, '.submit')
      wait_for_ajaximations

      expect(Account.default.developer_keys.count).to eq 1
      key = Account.default.developer_keys.last
      expect(key.name).to eq "Cooler Tool"
      expect(key.email).to eq "admins@example.com"
      expect(key.redirect_uris).to eq ["http://b/"]
      expect(key.icon_url).to eq "/images/add.png"
      expect(all_keys.count).to eq 1
    end

    it "allows editing of legacy redirect URI", test_id: 3469351 do
      @new_key.update_attribute(:redirect_uri, "http://a/")
      visit_developer_page(Account.default.id)
      edit_key_button(@new_key.id).click
      edit_key_name("Cooler Tool")
      edit_key_email("admins@example.com")
      edit_key_legacy_redirect_uri("http://b/")
      edit_key_icon_url("/images/add.png")
      submit_dialog(key_settings_dialog_selector, '.submit')
      wait_for_ajaximations

      expect(Account.default.developer_keys.count).to eq 1
      key = Account.default.developer_keys.last
      expect(key.name).to eq "Cooler Tool"
      expect(key.email).to eq "admins@example.com"
      expect(key.redirect_uri).to eq "http://b/"
      expect(key.icon_url).to eq "/images/add.png"
      expect(all_keys.count).to eq 1
    end

    it "allows deactivation through 'deactivate this key button'", test_id: 3469389 do
      visit_developer_page(Account.default.id)

      deactivate_key_button(@new_key.id).click
      wait_for_ajaximations
      expect(key_row(@new_key.id)).to include_text 'inactive'
      expect(@new_key.reload.workflow_state).to eq 'inactive'
    end

    it "allows activation through 'activate this key button'", test_id: 3469390 do
      @new_key.update(workflow_state: 'inactive')
      visit_developer_page(Account.default.id)

      activate_key_button(@new_key.id).click
      expect(key_row(@new_key.id)).not_to include_text 'inactive'
      expect(@new_key.reload.workflow_state).to eq 'active'
    end

    it "allows deletion through 'delete this key button'", test_id: 344079 do
      skip_if_safari(:alert)
      visit_developer_page(Account.default.id)

      delete_key_button(@new_key.id).click
      driver.switch_to.alert.accept
      driver.switch_to.default_content
      expect(keys_table).not_to contain_css("tbody tr")
      expect(Account.default.developer_keys.nondeleted.count).to eq 0
    end

    it "allows for pagination", test_id: 344532 do
      11.times { |i| Account.default.developer_keys.create!(name: "tool #{i}") }
      visit_developer_page(Account.default.id)

      expect(loading_div).not_to contain_css('.loading')
      expect(all_keys.count).to eq 10
      scroll_to(all_keys.last)
      show_all_keys_button.click

      expect(loading_div).not_to have_class('loading')
      expect(all_keys.count).to eq 12
    end
  end
end
