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

require File.expand_path(File.dirname(__FILE__) + '/../spec_helper.rb')

describe ActiveRecord::Base do
  describe "#remove_dropped_columns" do
    before do
      @orig_dropped = ActiveRecord::Base::DROPPED_COLUMNS
    end

    after do
      ActiveRecord::Base.send(:remove_const, :DROPPED_COLUMNS)
      ActiveRecord::Base::DROPPED_COLUMNS = @orig_dropped
      User.reset_column_information
    end

    it "should mask columns marked as dropped from column info methods" do
      User.columns.any? { |c| c.name == 'name' }.should be_true
      User.column_names.should be_include('name')
      # if we ever actually drop the name column, this spec will fail on the line
      # above, so it's all good
      ActiveRecord::Base.send(:remove_const, :DROPPED_COLUMNS)
      ActiveRecord::Base::DROPPED_COLUMNS = { 'users' => %w(name) }
      User.reset_column_information
      User.columns.any? { |c| c.name == 'name' }.should be_false
      User.column_names.should_not be_include('name')
    end

    it "should only drop columns from the specific table specified" do
      ActiveRecord::Base.send(:remove_const, :DROPPED_COLUMNS)
      ActiveRecord::Base::DROPPED_COLUMNS = { 'users' => %w(name) }
      User.reset_column_information
      Group.reset_column_information
      User.columns.any? { |c| c.name == 'name' }.should be_false
      Group.columns.any? { |c| c.name == 'name' }.should be_true
    end

    context "rank helpers" do
      it "should generate appropriate rank sql" do
        ActiveRecord::Base.rank_sql(['a', ['b', 'c'], ['d']], 'foo').
          should eql "CASE WHEN foo IN ('a') THEN 0 WHEN foo IN ('b', 'c') THEN 1 WHEN foo IN ('d') THEN 2 ELSE 3 END"
      end

      it "should generate appropriate rank hashes" do
        hash = ActiveRecord::Base.rank_hash(['a', ['b', 'c'], ['d']])
        hash.should == {'a' => 1, 'b' => 2, 'c' => 2, 'd' => 3}
        hash['e'].should eql 4
      end
    end
  end

  it "should have a valid GROUP BY clause when group_by is used correctly" do
    conn = ActiveRecord::Base.connection
    lambda {
      User.find_by_sql "SELECT id, name FROM users GROUP BY #{conn.group_by('id', 'name')}"
      User.find_by_sql "SELECT id, name FROM (SELECT id, name FROM users) u GROUP BY #{conn.group_by('id', 'name')}"
    }.should_not raise_error
  end

  context "unique_constraint_retry" do
    before do
      @user = user_model
      @assignment = assignment_model
      @orig_user_count = User.count
    end

    it "should normally run once" do
      User.unique_constraint_retry do
        User.create!
      end
      User.count.should eql @orig_user_count + 1
    end

    it "should run twice if it gets a UniqueConstraintViolation" do
      Submission.create!(:user => @user, :assignment => @assignment)
      tries = 0
      User.unique_constraint_retry do
        tries += 1
        User.create!
        Submission.create!(:user => @user, :assignment => @assignment)
      end
      Submission.count.should eql 1
      tries.should eql 2
      User.count.should eql @orig_user_count
    end

    it "should not cause outer transactions to roll back" do
      Submission.create!(:user => @user, :assignment => @assignment)
      User.transaction do
        User.create!
        User.unique_constraint_retry do
          User.create!
          Submission.create!(:user => @user, :assignment => @assignment)
        end
        User.create!
      end
      Submission.count.should eql 1
      User.count.should eql @orig_user_count + 2
    end

    it "should not eat other ActiveRecord::StatementInvalid exceptions" do
      lambda { User.unique_constraint_retry { User.connection.execute "this is not valid sql" } }.should raise_error(ActiveRecord::StatementInvalid)
    end

    it "should not eat any other exceptions" do
      lambda { User.unique_constraint_retry { raise "oh crap" } }.should raise_error
    end
  end
end
