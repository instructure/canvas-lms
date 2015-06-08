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

describe InfoController do

  describe "GET 'health_check'" do
    it "should work" do
      get 'health_check'
      expect(response).to be_success
      expect(response.body).to eq 'canvas ok'
    end

    it "should respond_to json" do
      request.accept = "application/json"
      Canvas.stubs(:revision).returns("Test Proc")
      get "health_check"
      expect(response).to be_success
      expect(JSON.parse(response.body)).to eq({ "status" => "canvas ok", "revision" => "Test Proc" })
    end
  end

  describe "GET 'help_links'" do
    it "should work" do
      get 'help_links'
      expect(response).to be_success
    end

    it "should set the locale for translated help link text from the current user" do
      user = User.create!(locale: 'es')
      user_session(user)
      # create and save account instance so that we don't invoke I18n's
      # localizer lambda in a request filter prior to loading necessary
      # users, accounts, context etc.
      Account.default
      get 'help_links'
      expect(I18n.locale.to_s).to eq 'es'
    end
  end
end
