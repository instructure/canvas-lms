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
        expect(Thing.new.content_notices('user')).to eql([])
      end
    end

    it "should add and remove a content notice" do
      enable_cache do
        thing = Thing.new
        thing.add_content_notice :foo
        notices = thing.content_notices('user')
        expect(notices.size).to eql(1)
        expect(notices[0].tag).to eql(:foo)
        expect(notices[0].text).to eql('foo!')
        thing.remove_content_notice :foo
        expect(thing.content_notices('user')).to be_empty
      end
    end

    it "should check the show condition of a notice" do
      enable_cache do
        thing = Thing.new
        thing.add_content_notice :foo
        thing.add_content_notice :bar
        expect(thing.content_notices('alice').map(&:tag)).to eql([:foo])
        expect(thing.content_notices('bob').map(&:tag)).to eql([:foo, :bar])
      end
    end

    it "should create expiring notices" do
      enable_cache do
        thing = Thing.new
        thing.add_content_notice :foo, 1.hour
        expect(thing.content_notices('user').map(&:tag)).to eql([:foo])
        Timecop.freeze(2.hours.from_now) do
          expect(thing.content_notices('user')).to be_empty
        end
      end
    end
  end
end
