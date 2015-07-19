#
# Copyright (C) 2015 Instructure, Inc.
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

describe Mutable do
  before do
    @klass = Class.new do
      # the signature that Mutable requires. if we care about side
      # effects/return values from these methods for specific tests, we'll mock
      # them
      def muted?; end
      def update_attribute(*args); end
      def save!; end

      include Mutable
    end

    @mutable = @klass.new
  end

  describe "mute!" do
    it "updates if not yet muted" do
      @mutable.expects(:muted?).returns(false)
      @mutable.expects(:update_attribute).once.with(:muted, true)
      @mutable.mute!
    end

    it "skips update if already muted" do
      @mutable.expects(:muted?).returns(true)
      @mutable.expects(:update_attribute).never
      @mutable.mute!
    end
  end

  describe "unmute!" do
    it "updates if currently muted" do
      @mutable.expects(:muted?).returns(true)
      @mutable.expects(:update_attribute).once.with(:muted, false)
      @mutable.unmute!
    end

    it "skips update if not muted" do
      @mutable.expects(:muted?).returns(false)
      @mutable.expects(:update_attribute).never
      @mutable.unmute!
    end

    it "broadcasts unmute event if currently muted" do
      @mutable.expects(:muted?).returns(true)
      @mutable.expects(:broadcast_unmute_event).once
      @mutable.unmute!
    end

    it "skips unmute event if not muted" do
      @mutable.expects(:muted?).returns(false)
      @mutable.expects(:broadcast_unmute_event).never
      @mutable.unmute!
    end
  end
end
