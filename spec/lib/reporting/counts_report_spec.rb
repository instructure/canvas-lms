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

require File.expand_path(File.dirname(__FILE__) + '/../../sharding_spec_helper')

describe Reporting::CountsReport do
  shared_examples_for "counts_report" do
    before do
      @shard1 ||= Shard.default
      @account1 = Account.create!
      @account2 = @shard1.activate { Account.create! }
      Reporting::CountsReport.stubs(:last_activity).returns(true)
    end

    it "should create a detailed report for each account" do
      Reporting::CountsReport.process
      @account1.report_snapshots.detailed.first.should_not be_nil
      snapshot = @account2.report_snapshots.detailed.first
      snapshot.should_not be_nil
      snapshot.shard.should == @shard1
    end
  end

  context "sharding" do
    it_should_behave_like "sharding"
    it_should_behave_like "counts_report"
  end

  it_should_behave_like "counts_report"
end
