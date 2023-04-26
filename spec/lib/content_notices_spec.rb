# frozen_string_literal: true

#
# Copyright (C) 2014 - present Instructure, Inc.
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

describe ContentNotices do
  let(:thing_class) do
    Class.new do
      def asset_string
        "thing_1"
      end

      include ContentNotices
      define_content_notice :foo, text: "foo!"
      define_content_notice :bar, text: "baz", should_show: ->(_thing, user) { user == "bob" }
    end
  end

  describe "content_notices" do
    it "returns [] if no notices are active" do
      enable_cache do
        expect(thing_class.new.content_notices("user")).to eql([])
      end
    end

    it "adds and remove a content notice" do
      enable_cache do
        thing = thing_class.new
        thing.add_content_notice :foo
        notices = thing.content_notices("user")
        expect(notices.size).to be(1)
        expect(notices[0].tag).to be(:foo)
        expect(notices[0].text).to eql("foo!")
        thing.remove_content_notice :foo
        expect(thing.content_notices("user")).to be_empty
      end
    end

    it "checks the show condition of a notice" do
      enable_cache do
        thing = thing_class.new
        thing.add_content_notice :foo
        thing.add_content_notice :bar
        expect(thing.content_notices("alice").map(&:tag)).to eql([:foo])
        expect(thing.content_notices("bob").map(&:tag)).to eql([:foo, :bar])
      end
    end

    it "creates expiring notices" do
      enable_cache do
        thing = thing_class.new
        thing.add_content_notice :foo, 1.hour
        expect(thing.content_notices("user").map(&:tag)).to eql([:foo])
        Timecop.freeze(2.hours.from_now) do
          expect(thing.content_notices("user")).to be_empty
        end
      end
    end
  end
end
