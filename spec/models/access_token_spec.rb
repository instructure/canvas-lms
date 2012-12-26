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

require File.expand_path(File.dirname(__FILE__) + '/../spec_helper.rb')

describe AccessToken do
  context "hashed tokens" do
    before do
      @at = AccessToken.create!(:user => user_model, :developer_key => DeveloperKey.default)
      @token_string = @at.full_token
    end

    it "should only store the encrypted token" do
      @token_string.should be_present
      @token_string.should_not == @at.crypted_token
      AccessToken.find(@at.id).full_token.should be_nil
    end

    it "should authenticate via crypted_token" do
      AccessToken.authenticate(@token_string).should == @at
    end

    it "should not authenticate expired tokens" do
      @at.update_attribute(:expires_at, 2.hours.ago)
      AccessToken.authenticate(@token_string).should be_nil
    end
  end
end
