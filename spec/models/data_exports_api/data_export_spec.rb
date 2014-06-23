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

require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper.rb')

describe DataExportsApi::DataExport do #nothing
  context "for" do
    before do
      @dd = DataExportsApi::DataExport.for(Account.default).build(user: user)
      @dd.save!
    end

    it "should find data exports for a given account" do
      DataExportsApi::DataExport.for(Account.default).should == [@dd]
    end

    it "should cancel data export" do
      @dd.cancel
      @dd.workflow_state.should == "cancelled"
    end
  end
end
