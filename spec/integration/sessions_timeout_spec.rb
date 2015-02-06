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
require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe "Session Timeout" do 
  context " when sessions timeout is set to 30 minutes" do
    before do
      plugin_setting = PluginSetting.new(:name => "sessions", :settings => {"session_timeout" => "30"})
      plugin_setting.save!
    end

    context "when a user logs in" do 
      before do
        course_with_student(:active_all => true, :user => user_with_pseudonym)
        login_as
      end

      it "should time out after 40 minutes of inactivity" do
        now = Time.now
        get "/"
        expect(response).to be_success

        Time.stubs(:now).returns(now + 40.minutes)
        get "/"
        expect(response).to redirect_to "http://www.example.com/login"
      end

      it "should not time out if the user remains active" do
        now = Time.now
        get "/"
        expect(response).to be_success

        Time.stubs(:now).returns(now + 20.minutes)
        get "/"
        expect(response).to be_success

        Time.stubs(:now).returns(now + 40.minutes)
        get "/"
        expect(response).to be_success
      end
    end
  end
end
