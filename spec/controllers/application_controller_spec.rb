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

describe ApplicationController do

  before(:each) do
    @controller = ApplicationController.new
  end

  describe "js_env" do
    it "should set items" do
      @controller.js_env :FOO => 'bar'
      @controller.js_env[:FOO].should == 'bar'
    end

    it "should allow multiple items" do
      @controller.js_env :A => 'a', :B => 'b'
      @controller.js_env[:A].should == 'a'
      @controller.js_env[:B].should == 'b'
    end

    it "should not allow overwriting a key" do
      @controller.js_env :REAL_SLIM_SHADY => 'please stand up'
      expect { @controller.js_env(:REAL_SLIM_SHADY => 'poser') }.to raise_error
    end
  end

end


