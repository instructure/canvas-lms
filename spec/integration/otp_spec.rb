#
# Copyright (C) 2012 Instructure, Inc.
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

require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
require 'rotp'

describe "one time passwords" do
  before do
    Account.default.settings[:mfa_settings] = :required
    Account.default.save!
    user_with_pseudonym(:active_all => 1, :password => 'qwertyuiop')
    @user.otp_secret_key = ROTP::Base32.random_base32
    @user.save!
  end

  context "mid-login" do
    before do
      post '/login/canvas', :pseudonym_session => { :unique_id => @pseudonym.unique_id, :password => 'qwertyuiop' }
    end

    it "should redirect" do
      expect(response).to redirect_to(otp_login_url)
    end

    it "should not allow access to the rest of canvas" do
      get '/'
      expect(response).to redirect_to login_url
      follow_redirect!
      expect(response).to redirect_to canvas_login_url
      follow_redirect!
      expect(response).to be_success
    end

    it "should not destroy your session when someone does an XHR accidentally" do
      xhr :get, '/api/v1/conversations/unread_count'
      expect(response.status).to eq 403
      get otp_login_url
      expect(response).to be_success
    end
  end
end
