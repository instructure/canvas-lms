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

if Canvas.redis_enabled?
describe "Canvas::Redis" do
  describe "locking" do
    it "should succeed if the lock isn't taken" do
      Canvas::Redis.lock('test1').should == true
      Canvas::Redis.lock('test2').should == true
    end

    it "should fail if the lock is taken" do
      Canvas::Redis.lock('test1').should == true
      Canvas::Redis.lock('test1').should == false
      Canvas::Redis.unlock('test1').should == true
      Canvas::Redis.lock('test1').should == true
    end

    it "should live forever if no expire time is given" do
      Canvas::Redis.lock('test1').should == true
      Canvas.redis.ttl(Canvas::Redis.lock_key('test1')).should == -1
    end

    it "should set the expire time if given" do
      Canvas::Redis.lock('test1', 15).should == true
      ttl = Canvas.redis.ttl(Canvas::Redis.lock_key('test1'))
      ttl.should > 0
      ttl.should <= 15
    end
  end
end
end
