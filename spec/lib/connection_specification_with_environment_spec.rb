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

describe ActiveRecord::Base::ConnectionSpecification do
  it "should allow changing environments" do
    conf = {
        :adapter => 'postgresql',
        :database => 'master',
        :username => 'canvas',
        :deploy => {
          :username => 'deploy'
        },
        :slave => {
          :database => 'slave'
        }
    }
    spec = ActiveRecord::Base::ConnectionSpecification.new(conf, 'adapter')
    spec.config[:username].should == 'canvas'
    spec.config[:database].should == 'master'
    ActiveRecord::Base::ConnectionSpecification.with_environment(:deploy) do
      spec.config[:username].should == 'deploy'
      spec.config[:database].should == 'master'
    end
    spec.config[:username].should == 'canvas'
    spec.config[:database].should == 'master'
    ActiveRecord::Base::ConnectionSpecification.with_environment(:slave) do
      spec.config[:username].should == 'canvas'
      spec.config[:database].should == 'slave'
    end
    spec.config[:username].should == 'canvas'
    spec.config[:database].should == 'master'
  end

  it "should allow using hash insertions" do
    conf = {
        :adapter => 'postgresql',
        :database => 'master',
        :username => '%{schema_search_path}',
        :schema_search_path => 'canvas',
        :deploy => {
            :username => 'deploy'
        }
    }
    spec = ActiveRecord::Base::ConnectionSpecification.new(conf, 'adapter')
    spec.config[:username].should == 'canvas'
    ActiveRecord::Base::ConnectionSpecification.with_environment(:deploy) do
      spec.config[:username].should == 'deploy'
    end
    spec.config[:username].should == 'canvas'
  end

  it "should be cache coherent with modifying the config" do
    conf = {
        :adapter => 'postgresql',
        :database => 'master',
        :username => '%{schema_search_path}',
        :schema_search_path => 'canvas',
        :deploy => {
            :username => 'deploy'
        }
    }
    spec = ActiveRecord::Base::ConnectionSpecification.new(conf.dup, 'adapter')
    spec.config[:username].should == 'canvas'
    spec.config[:schema_search_path] = 'bob'
    spec.config[:username].should == 'bob'
    ActiveRecord::Base::ConnectionSpecification.with_environment(:deploy) do
      spec.config[:schema_search_path].should == 'bob'
      spec.config[:username].should == 'deploy'
    end

    spec.config = conf.dup
    spec.config[:username].should == 'canvas'
  end

  describe "with_environment" do
    before do
      #!!! trick it in to actually switching envs
      Rails.env.stubs(:test?).returns(false)

      # be sure to test bugs where the current env isn't yet included in this hash
      ActiveRecord::Base::ConnectionSpecification.connection_handlers.clear
    end

    it "should call ensure_handler when switching envs" do
      old_handler = ActiveRecord::Base.connection_handler
      ActiveRecord::Base::ConnectionSpecification.expects(:ensure_handler).returns(old_handler).twice
      ActiveRecord::Base::ConnectionSpecification.with_environment(:slave) {}
    end

    it "should not close connections when switching envs" do
      conn = ActiveRecord::Base.connection
      slave_conn = ActiveRecord::Base::ConnectionSpecification.with_environment(:slave) { ActiveRecord::Base.connection }
      conn.should_not == slave_conn
      ActiveRecord::Base.connection.should == conn
    end

    context "non-transactional" do
      self.use_transactional_fixtures = false

      it "should really disconnect" do
        ActiveRecord::Base.connection
        ActiveRecord::Base.connection_pool.should be_connected

        ActiveRecord::Base.clear_all_connections!
        ActiveRecord::Base.connection_pool.should_not be_connected
      end
    end
  end
end
