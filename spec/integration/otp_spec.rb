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

describe "one time passwords" do
  before do
    Account.default.settings[:mfa_settings] = :required
    Account.default.save!
    user_with_pseudonym(:active_all => 1, :password => 'qwerty')
    @user.otp_secret_key = ROTP::Base32.random_base32
    @user.save!
  end

  context "mid-login" do
    before do
      post '/login', :pseudonym_session => { :unique_id => @pseudonym.unique_id, :password => 'qwerty' }
      expect(response).to render_template('otp_login')
    end

    it "should not allow access to the rest of canvas" do
      get '/'
      expect(response).to redirect_to login_url
      follow_redirect!
      expect(response).to be_success
    end

    it "should not allow re-enrolling" do
      get '/login/otp'
      expect(response).to redirect_to login_url
      follow_redirect!
      expect(response).to be_success
    end
  end
end
