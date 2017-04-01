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

require_relative '../../../spec_helper'
require_relative '../../views_helper'

describe "login/canvas/new.html.erb" do
  before do
    assign(:domain_root_account, Account.default)
  end

  it "uses canvas route by default" do
    render
    expect(response).not_to be_nil
    doc = Nokogiri::HTML(response.body)
    expect(doc.at_css('form#login_form')['action']).to eq '/login/canvas'
  end

  it "uses ldap route for the ldap 'controller'" do
    Account.default.authentication_providers.create!(:auth_type => 'ldap')

    controller.request.path_parameters[:controller] = 'login/ldap'
    render
    expect(response).not_to be_nil
    doc = Nokogiri::HTML(response.body)
    expect(doc.at_css('form#login_form')['action']).to eq '/login/ldap'
  end

  it "should use internal forgot password mechanism by default" do
    render
    page = Nokogiri(response.body)
    expect(page.css("#login_forgot_password")[0]['href']).to eq '#'
  end

  context "with external mechanism specified" do
    let(:account){ Account.default }
    let(:config){ account.authentication_providers.build }

    before do
      config.auth_type = 'ldap'
      config.save!
      account.change_password_url = "http://www.instructure.com"
      account.save!
      assign(:domain_root_account, account)
    end

    it "should use external forgot password mechanism" do
      render
      page = Nokogiri(response.body)
      expect(page.css("#login_forgot_password")[0]['href']).
        to eq(account.change_password_url)
    end
  end
end
