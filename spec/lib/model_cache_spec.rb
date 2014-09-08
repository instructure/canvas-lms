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

require File.expand_path(File.dirname(__FILE__) + '/../spec_helper.rb')
require 'lib/model_cache'

describe ModelCache do
  before(:all) do
    class TestModelCacheUser < ActiveRecord::Base
      self.table_name = :users # reuse exiting tables so AR doesn't asplode
      include ModelCache
      cacheable_by :id, :name

      attr_protected
    end

    class TestModelCachePseudonym < ActiveRecord::Base
      self.table_name = :pseudonyms
      include ModelCache

      belongs_to :test_model_cache_user, :foreign_key => :user_id
      cacheable_method :test_model_cache_user, :key_method => :user_id

      belongs_to :test_model_cache_user_copy, :class_name => 'TestModelCacheUser', :foreign_key => :user_id
    end
  end

  before do
    user_with_pseudonym(:name => 'qwerty')
    @user = TestModelCacheUser.where(:id => @user).first
    @pseudonym = TestModelCachePseudonym.where(:id => @pseudonym).first
  end

  after(:all) do
    ModelCache.keys.delete('TestModelCacheUser')
    ModelCache.keys.delete('TestModelCachePseudonym')
    Object.send(:remove_const, :TestModelCacheUser)
    Object.send(:remove_const, :TestModelCachePseudonym)
  end

  it "should not cache by default" do
    u1 = TestModelCacheUser.find_by_id(@user.id)
    u1.should eql(@user)
    u1.should_not equal(@user)

    u2 = TestModelCacheUser.find_by_name(@user.name)
    u2.should eql(@user)
    u2.should_not equal(@user)

    u3 = @pseudonym.test_model_cache_user
    u3.should eql(@user)
    u3.should_not equal(@user)
  end

  context "with_cache" do
    it "should cache configured finder lookups" do
      ModelCache.with_cache(:test_model_cache_users => [@user]) do
        TestModelCacheUser.find_by_id(@user.id).should equal(@user)
        TestModelCacheUser.find_by_name(@user.name).should equal(@user)
      end
    end

    it "should cache configured instance lookups" do
      ModelCache.with_cache(:test_model_cache_users => [@user]) do
        @pseudonym.test_model_cache_user.should equal(@user)
      end
    end

    it "should not cache any other lookups" do
      ModelCache.with_cache(:test_model_cache_users => [@user]) do
        u1 = TestModelCacheUser.where(:id => @user.id).first
        u1.should eql(@user)
        u1.should_not equal(@user)

        u2 = @pseudonym.test_model_cache_user_copy
        u2.should eql(@user)
        u2.should_not equal(@user)
      end
    end

    it "should add to the cache if records are created" do
      ModelCache.with_cache(:test_model_cache_users => [@user]) do
        user = TestModelCacheUser.create(workflow_state: 'registered')

        u1 = TestModelCacheUser.find_by_id(user.id)
        u1.should equal(user)
    
        u2 = TestModelCacheUser.find_by_name(user.name)
        u2.should equal(user)
      end
    end

    it "should update the cache if records are updated" do
      ModelCache.with_cache(:test_model_cache_users => [@user]) do
        old_name = @user.name
        @user.update_attribute :name, "asdf"
        TestModelCacheUser.find_by_name(old_name).should be_nil
        TestModelCacheUser.find_by_name("asdf").should equal(@user)
      end
    end
  end
end
