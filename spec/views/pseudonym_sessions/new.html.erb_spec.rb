#
# Copyright (C) 2011 Instructure, Inc.
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

require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')
require File.expand_path(File.dirname(__FILE__) + '/../views_helper')

describe "/pseudonym_sessions/new" do
  it "should render" do
    assigns[:domain_root_account] = Account.default
    render "pseudonym_sessions/new"
    expect(response).not_to be_nil
    doc = Nokogiri::HTML(response.body)
    expect(doc.at_css('form#login_form')['action']).to eq '/login?nonldap=true'
  end

  it "should not add nonldap param to login form with ldap" do
    account_model
    config = @account.account_authorization_configs.create(:auth_type => 'cas')
    config.auth_type = 'ldap'
    config.save
    assigns[:domain_root_account] = @account
    render "pseudonym_sessions/new"
    expect(response).not_to be_nil
    doc = Nokogiri::HTML(response.body)
    expect(doc.at_css('form#login_form')['action']).to eq '/login'
  end
end

