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

describe "site-wide" do
  before do
    ActionController::Base.consider_all_requests_local = false
  end

  after do
    ActionController::Base.consider_all_requests_local = true
  end

  it "should render 404 when user isn't logged in" do
    Setting.set 'show_feedback_link', 'true'
    expect {
      get "/dashbo"
    }.to change(ErrorReport, :count).by +1
    response.status.should == "404 Not Found"
    ErrorReport.last.category.should == "404"
  end
end
