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

require File.expand_path(File.dirname(__FILE__) + '/api_spec_helper')

describe "API Error Handling", :type => :integration do
  before do
    user_with_pseudonym(:active_all => true)
    @token = @user.access_tokens.create!
  end

  it "should respond not_found for 404 errors" do
    get "/api/v1/courses/54321", nil, { 'Authorization' => "Bearer #{@token.token}" }
    response.response_code.should == 404
    JSON.parse(response.body).should == { 'status' => 'not_found', 'message' => 'The specified resource does not exist.' }
  end
end

