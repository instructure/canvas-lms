#
# Copyright (C) 2011 - present Instructure, Inc.
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

require_relative '../sharding_spec_helper'

describe 'session token', type: :request do
  before do
    user_with_pseudonym
    enable_default_developer_key!
  end

  let(:access_token) { @user.access_tokens.create!(:purpose => "test").full_token }

  it "should work" do
    get 'https://www.example.com/login/session_token?return_to=https://www.example.com/courses',
         params: {access_token: access_token}
    expect(response).to be_successful
    json = JSON.parse(response.body)
    expect(json['session_url']).to match %r{^https://www.example.com/courses\?session_token=[0-9a-zA-Z_\-]+$}

    get json['session_url']
    expect(response).to be_redirect
    expect(response.location).to eq 'https://www.example.com/courses'

    follow_redirect!
    expect(response).to be_successful
  end

  it "should set used_remember_me_token" do
    Account.site_admin.account_users.create!(user: @user)
    @pseudonym = @user.find_or_initialize_pseudonym_for_account(Account.site_admin)
    @pseudonym.save!
    get "http://test1.instructure.com/?session_token=#{SessionToken.new(@pseudonym.id, used_remember_me_token: true)}"
    expect(response).to redirect_to 'http://test1.instructure.com/'

    follow_redirect!
    expect(response).to be_successful
    expect(session[:used_remember_me_token]).to eq true
  end

  it "should reject bad tokens" do
    get 'http://test1.instructure.com/?session_token=garbage'
    expect(response).to be_redirect
    expect(response.location).to eq 'http://test1.instructure.com/login'

    token = SessionToken.new(@pseudonym.id)
    token.created_at = 1.day.ago
    token.signature = Canvas::Security.hmac_sha1(token.signature_string)
    get "http://test1.instructure.com/?session_token=#{token.to_s}"
    expect(response).to be_redirect
    expect(response.location).to eq 'http://test1.instructure.com/login'

    token = SessionToken.new(@pseudonym.id)
    token.pseudonym_id = @pseudonym.id - 1
    get "http://test1.instructure.com/?session_token=#{token.to_s}"
    expect(response).to be_redirect
    expect(response.location).to eq 'http://test1.instructure.com/login'
  end

  it "should remove the token from the url when already logged in" do
    Account.site_admin.account_users.create!(user: @user)

    # login
    user_session(@user, @pseudonym)

    get "http://test1.instructure.com/?session_token=#{SessionToken.new(@pseudonym.id)}"
    expect(response).to redirect_to 'http://test1.instructure.com/'
    follow_redirect!
    expect(response).to be_successful
  end
end
