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

require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper.rb')

describe "Canvas::Redis::Cassandra" do
  describe "#update_record" do
    it "should do nothing if there are no updates or deletes" do
      statement, args = Canvas::Cassandra::Database.build_update_record_cql("test_table", { :id => 5 }, {})
      statement.should be_nil
    end

    it "should do lone updates" do
      cql1 = Canvas::Cassandra::Database.build_update_record_cql("test_table", { :id => 5 }, { :name => "test" })
      cql2 = Canvas::Cassandra::Database.build_update_record_cql("test_table", { :id => 5 }, { :name => [nil, "test"] })
      cql1.should == ["UPDATE test_table SET name = ? WHERE id = ?", ["test", 5]]
      cql1.should == cql2
    end

    it "should do multi-updates" do
      cql = Canvas::Cassandra::Database.build_update_record_cql("test_table", { :id => 5 }, { :name => "test", :nick => ["old", "new"] })
      cql.should == ["UPDATE test_table SET name = ?, nick = ? WHERE id = ?", ["test", "new", 5]]
    end

    it "should do lone deletes" do
      cql1 = Canvas::Cassandra::Database.build_update_record_cql("test_table", { :id => 5 }, { :name => nil })
      cql2 = Canvas::Cassandra::Database.build_update_record_cql("test_table", { :id => 5 }, { :name => ["old", nil] })
      cql1.should == ["DELETE name FROM test_table WHERE id = ?", [5]]
      cql1.should == cql2
    end

    it "should do multi-deletes" do
      cql = Canvas::Cassandra::Database.build_update_record_cql("test_table", { :id => 5 }, { :name => nil, :nick => ["old", nil] })
      cql.should == ["DELETE name, nick FROM test_table WHERE id = ?", [5]]
    end

    it "should do combined updates and deletes" do
      cql = Canvas::Cassandra::Database.build_update_record_cql("test_table", { :id => 5 }, { :name => "test", :nick => nil })
      cql.should == ["BEGIN BATCH UPDATE test_table SET name = ? WHERE id = ? DELETE nick FROM test_table WHERE id = ? APPLY BATCH", ["test", 5, 5]]
    end

    it "should handle compound primary keys" do
      cql = Canvas::Cassandra::Database.build_update_record_cql("test_table", { :id => 5, :sub_id => "sub!" }, { :name => "test", :id => 5, :sub_id => [nil, "sub!"] })
      cql.should == ["UPDATE test_table SET name = ? WHERE id = ? AND sub_id = ?", ["test", 5, "sub!"]]
    end

    it "should disallow changing a primary key component" do
      expect {
        Canvas::Cassandra::Database.build_update_record_cql("test_table", { :id => 5, :sub_id => "sub!" }, { :name => "test", :id => 5, :sub_id => ["old", "sub!"]})
      }.to raise_error(ArgumentError)
    end
  end
end
