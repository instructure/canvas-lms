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

require "spec_helper"

class TestLogger
  def debug(*args)
  end
end

describe "execute and update" do
  let(:db) do
    # TODO: Setting.from_config really deserves to be its own Config component that we could use here
    config_path = File.expand_path("../../../../../config/cassandra.yml", __FILE__)
    test_config = YAML.load(ERB.new(File.read(config_path)).result)['test']['page_views']
    CanvasCassandra::Database.new("test_conn", test_config['servers'], {keyspace: test_config['keyspace'], cql_version: '3.0.0'}, TestLogger.new)
  end

  before do
    begin
      db.execute("drop table page_views")
    rescue CassandraCQL::Error::InvalidRequestException
    end
    db.execute("create table page_views (request_id text primary key, user_id bigint)")
  end

  after do
    db.execute("drop table page_views")
  end

  it "should return the result from execute" do
    db.execute("select count(*) from page_views").fetch['count'].should == 0
    db.select_value("select count(*) from page_views").should == 0
    db.execute("insert into page_views (request_id, user_id) values (?, ?)", "test", 0).should == nil
  end

  it "should return nothing from update" do
    db.update("select count(*) from page_views").should == nil
    db.update("insert into page_views (request_id, user_id) values (?, ?)", "test", 0).should == nil
  end
end