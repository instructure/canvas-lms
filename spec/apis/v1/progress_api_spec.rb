#
# Copyright (C) 2013 Instructure, Inc.
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

require File.expand_path(File.dirname(__FILE__) + '/../api_spec_helper')

describe ProgressController, :type => :integration do

  describe "show" do
    before do
      @account = account_model
      account_admin_user :account => @account
      @progress = @account.progresses.build :tag => 'course_batch_update', :completion => 55.0, :message => 'hello'
      @progress.user_id = @user.id
      @progress.start!
      @progress.save!

      @path = "/api/v1/progress/#{@progress.id}"
      @params = { :controller => 'progress', :action => 'show', :id => @progress.id.to_s, :format => 'json' }
    end

    it "should show Progress" do
      json = api_call(:get, @path, @params)
      json['completion'].should == 55.0
      json['context_id'].should == @account.id
      json['context_type'].should == 'Account'
      json['user_id'].should == @user.id
      json['id'].should == @progress.id
      json['message'].should == 'hello'
      json['tag'].should == 'course_batch_update'
      json['workflow_state'].should == 'running'
      json['url'].should == "http://www.example.com/api/v1/progress/#{@progress.id}"
    end

    it "should 401 if the caller does not have permission to view the context" do
      other_account = account_model
      account_admin_user :account => other_account
      api_call(:get, @path, @params, {}, {}, { :expected_status => 401 })
    end

    it "should 404 if the object doesn't exist" do
      @progress.destroy
      api_call(:get, @path, @params, {}, {}, { :expected_status => 404 })
    end
  end
end
