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

describe "API Error Handling", type: :request do
  before :once do
    user_with_pseudonym(:active_all => true)
    @token = @user.access_tokens.create!
  end

  describe "ActiveRecord Error JSON override" do
    it "should not return the base object in ErrorMessage.to_json" do
      err = ActiveModel::BetterErrors::ErrorMessage.new(@user, :name, :invalid, "invalid name")
      JSON.parse(err.to_json).should == { 'attribute' => 'name', 'type' => 'invalid', 'message' => 'invalid name', 'options' => {} }
    end

    it "should not return the base object in ActiveRecord::Errors.to_json" do
      page = WikiPage.new(:body => 'blah blah', :title => 'blah blah')
      page.valid?.should be_false
      errors = page.errors.to_json
      parsed = JSON.parse(errors)['errors']
      parsed.size.should > 0
      errors.should_not match(/blah blah/)
      parsed.each { |k,v| v.each { |i| i.keys.sort.should == ['attribute', 'message', 'type'] } }
    end
  end

  it "should respond not_found for 404 errors" do
    get "/api/v1/courses/54321", nil, { 'Authorization' => "Bearer #{@token.full_token}" }
    response.response_code.should == 404
    json = JSON.parse(response.body)
    json['errors'].should == [{'message' => 'The specified resource does not exist.'}]
  end
end

