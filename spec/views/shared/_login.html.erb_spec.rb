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

describe "/shared/_login" do
  before do
    assigns[:domain_root_account] = Account.default
  end

  it "should render" do
    course_with_student
    view_context
    render :partial => "shared/login"
    expect(response).not_to be_nil
  end
  
  it "should use internal forgot password mechanism by default" do
    render :partial => "shared/login"
    page = Nokogiri(response.body)
    expect(page.css("#login_forgot_password")[0]['href']).to eq '#'
  end
  
  it "should use external forgot password mechanism if specified" do
    @account = Account.default
    config = @account.account_authorization_configs.build
    config.auth_type = 'ldap'
    config.change_password_url = "http://www.instructure.com"
    config.save!
    expect(@account.forgot_password_external_url).to eq config.change_password_url
    assigns[:domain_root_account] = @account
    render :partial => "shared/login"
    page = Nokogiri(response.body)
    expect(page.css("#login_forgot_password")[0]['href']).to eq config.change_password_url
  end
  
  it "should use default forgot password mechanism if external mechanism specified but it's a canvas_login request" do
    @account = Account.default
    config = @account.account_authorization_configs.build
    config.auth_type = 'ldap'
    config.change_password_url = "http://www.instructure.com"
    config.save!
    expect(@account.forgot_password_external_url).to eq config.change_password_url
    assigns[:domain_root_account] = @account
    render :partial => "shared/login", :locals => {:params => {:canvas_login => '1'}}
    page = Nokogiri(response.body)
    expect(page.css("#login_forgot_password")[0]['href']).to eq '#'
  end
end

