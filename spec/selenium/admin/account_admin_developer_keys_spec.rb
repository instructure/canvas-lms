#
# Copyright (C) 2012 - present Instructure, Inc.
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

describe 'developer keys' do
  include_context 'in-process server selenium tests'

  before(:each) do
    admin_logged_in
  end

  let(:developer_key) do
    Account.default.developer_keys.create!(
      name: 'Cool Tool',
      email: 'admin@example.com',
      redirect_uris: ['http://example.com'],
      icon_url: '/images/delete.png'
    )
  end

  it "allows creation through 'add developer key button'", test_id: 344077 do
    get "/accounts/#{Account.default.id}/developer_keys"
    expect(f("#keys")).not_to contain_css("tbody tr")

    f(".add_key").click
    expect(f("#edit_dialog")).to be_displayed
    f("#key_name").send_keys("Cool Tool")
    f("#email").send_keys("admin@example.com")
    f("#redirect_uris").send_keys("http://example.com")
    f("#icon_url").send_keys("/images/delete.png")
    submit_dialog("#edit_dialog", '.submit')
    wait_for_ajaximations

    expect(f("#edit_dialog")).not_to be_displayed
    expect(Account.default.developer_keys.count).to eq 1
    key = Account.default.developer_keys.last
    expect(key.name).to eq "Cool Tool"
    expect(key.email).to eq "admin@example.com"
    expect(key.redirect_uris).to eq ["http://example.com"]
    expect(key.icon_url).to eq "/images/delete.png"
    expect(ff("#keys tbody tr").length).to eq 1
  end

  it "allows update through 'edit this key button'", test_id: 344078 do
    developer_key
    get "/accounts/#{Account.default.id}/developer_keys"
    f("#keys tbody tr.key .edit_link").click
    expect(f("#edit_dialog")).to be_displayed
    replace_content(f("#key_name"), "Cooler Tool")
    replace_content(f("#email"), "admins@example.com")
    replace_content(f("#redirect_uris"), "http://b/")
    replace_content(f("#icon_url"), "/images/add.png")
    submit_dialog("#edit_dialog", '.submit')
    wait_for_ajaximations

    expect(f("#edit_dialog")).not_to be_displayed
    expect(Account.default.developer_keys.count).to eq 1
    key = Account.default.developer_keys.last
    expect(key.name).to eq "Cooler Tool"
    expect(key.email).to eq "admins@example.com"
    expect(key.redirect_uris).to eq ["http://b/"]
    expect(key.icon_url).to eq "/images/add.png"
    expect(ff("#keys tbody tr").length).to eq 1
  end

  it 'allows editing of legacy redirect URI', test_id: 3469351 do
    dk = developer_key
    dk.update_attribute(:redirect_uri, "http://a/")
    get "/accounts/#{Account.default.id}/developer_keys"
    f("#keys tbody tr.key .edit_link").click
    expect(f("#edit_dialog")).to be_displayed
    replace_content(f("#key_name"), "Cooler Tool")
    replace_content(f("#email"), "admins@example.com")
    expect(f(".key_form")).to contain_css("#redirect_uri")
    replace_content(f("#redirect_uri"), "https://b/")
    replace_content(f("#icon_url"), "/images/add.png")
    submit_dialog("#edit_dialog", '.submit')
    wait_for_ajaximations

    expect(f("#edit_dialog")).not_to be_displayed
    expect(Account.default.developer_keys.count).to eq 1
    key = Account.default.developer_keys.last
    expect(key.name).to eq "Cooler Tool"
    expect(key.email).to eq "admins@example.com"
    expect(key.redirect_uri).to eq "https://b/"
    expect(key.icon_url).to eq "/images/add.png"
    expect(ff("#keys tbody tr").length).to eq 1
  end

  it "allows deactivation through 'deactivate this key button'", test_id: 3469389 do
    developer_key
    get "/accounts/#{Account.default.id}/developer_keys"
    f("#keys tbody tr.key .icon-lock").click
    expect(f("#keys tbody")).to contain_css(".key.inactive")
    expect(developer_key.reload.workflow_state).to eq 'inactive'
  end

  it "allows activation through 'activate this key button'", test_id: 3469390 do
    developer_key.update(workflow_state: 'inactive')
    get "/accounts/#{Account.default.id}/developer_keys"
    f("#keys tbody tr.key .icon-unlock").click
    expect(f("#keys tbody")).not_to contain_css(".key.inactive")
    expect(developer_key.reload.workflow_state).to eq 'active'
  end

  it "allows deletion through 'delete this key button'", test_id: 344079 do
    skip_if_safari(:alert)
    developer_key
    get "/accounts/#{Account.default.id}/developer_keys"
    f("#keys tbody tr.key .edit_link").click
    expect(f("#edit_dialog")).to be_displayed
    f("#icon_url").clear
    submit_dialog("#edit_dialog", '.submit')
    wait_for_ajaximations

    expect(f("#edit_dialog")).not_to be_displayed
    expect(Account.default.developer_keys.count).to eq 1
    key = Account.default.developer_keys.last
    expect(key.icon_url).to eq nil
    expect(ff("#keys tbody tr").length).to eq 1

    f("#keys tbody tr.key .delete_link").click
    driver.switch_to.alert.accept
    driver.switch_to.default_content
    expect(f("#keys")).not_to contain_css("tbody tr")
    expect(Account.default.developer_keys.nondeleted.count).to eq 0
  end

  it "allows for pagination", test_id: 344532 do
    11.times { |i| Account.default.developer_keys.create!(name: "tool #{i}") }
    get "/accounts/#{Account.default.id}/developer_keys"
    expect(f("#loading")).not_to have_class('loading')
    expect(ff("#keys tbody tr")).to have_size(10)
    expect(f('#loading')).to have_class('show_more')
    f("#loading .show_all").click
    expect(f("#loading")).not_to have_class('loading')
    expect(ff("#keys tbody tr")).to have_size(11)
  end
end
