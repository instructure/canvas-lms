#
# Copyright (C) 2013 Instructure, Inc.
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

describe ContentNotices do
  class Thing
    def asset_string; "thing_1"; end
    include ContentNotices
    define_content_notice :foo, text: 'foo!'
    define_content_notice :bar, template: 'some_template', should_show: ->(thing, user) { user == 'bob' }
  end

  describe "content_notices" do
    it "should return [] if no notices are active" do
      enable_cache do
        Thing.new.content_notices('user').should eql([])
      end
    end

    it "should add and remove a content notice" do
      enable_cache do
        thing = Thing.new
        thing.add_content_notice :foo
        notices = thing.content_notices('user')
        notices.size.should eql(1)
        notices[0].tag.should eql(:foo)
        notices[0].text.should eql('foo!')
        thing.remove_content_notice :foo
        thing.content_notices('user').should be_empty
      end
    end

    it "should check the show condition of a notice" do
      enable_cache do
        thing = Thing.new
        thing.add_content_notice :foo
        thing.add_content_notice :bar
        thing.content_notices('alice').map(&:tag).should eql([:foo])
        thing.content_notices('bob').map(&:tag).should eql([:foo, :bar])
      end
    end

    it "should create expiring notices" do
      enable_cache do
        thing = Thing.new
        thing.add_content_notice :foo, 1.hour
        thing.content_notices('user').map(&:tag).should eql([:foo])
        Timecop.freeze(2.hours.from_now) do
          thing.content_notices('user').should be_empty
        end
      end
    end
  end
end
