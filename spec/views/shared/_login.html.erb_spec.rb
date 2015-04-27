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
    render partial: "shared/login"
    expect(response).not_to be_nil
  end

  it "should use internal forgot password mechanism by default" do
    render partial: "shared/login"
    page = Nokogiri(response.body)
    expect(page.css("#login_forgot_password")[0]['href']).to eq '#'
  end

  context "with external mechanism specified" do
    let(:account){ Account.default }
    let(:config){ account.account_authorization_configs.build }

    before do
      config.auth_type = 'ldap'
      config.save!
      account.change_password_url = "http://www.instructure.com"
      account.save!
      expect(account.forgot_password_external_url).
        to eq(account.change_password_url)
      assigns[:domain_root_account] = account
    end

    it "should use external forgot password mechanism" do
      render partial: "shared/login"
      page = Nokogiri(response.body)
      expect(page.css("#login_forgot_password")[0]['href']).
        to eq(account.change_password_url)
    end

    it "uses default forgot password mechanism if it's a canvas_login request" do
      render partial: "shared/login", locals: {params: {canvas_login: '1'}}
      page = Nokogiri(response.body)
      expect(page.css("#login_forgot_password")[0]['href']).to eq '#'
    end
  end
end
