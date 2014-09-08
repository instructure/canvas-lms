#
# Copyright (C) 2014 Instructure, Inc.
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

require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

describe Filters::AllowAppProfiling, type: :none do
  describe "for a site admin" do
    let_once(:target_user) { site_admin_user() }

    it "should be disabled at first" do
      Filters::AllowAppProfiling.allow?({}, {}, target_user).should == false
    end

    it "should allow enabling, and remember that in session store" do
      session = {}
      Filters::AllowAppProfiling.allow?({ pp: 'enable' }, session, target_user).should == true
      Filters::AllowAppProfiling.allow?({}, session, target_user).should == true
    end
  end

  describe "for a normal user" do
    let(:target_user) { account_admin_user() }

    it "should not be allowed" do
      Filters::AllowAppProfiling.allow?({}, {}, target_user).should == false
      Filters::AllowAppProfiling.allow?({}, {}, nil).should == false
      Filters::AllowAppProfiling.allow?({ pp: 'enable' }, {}, target_user).should == false
      Filters::AllowAppProfiling.allow?({ pp: 'enable' }, {}, nil).should == false
    end
  end
end
