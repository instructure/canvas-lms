# frozen_string_literal: true

#
# Copyright (C) 2021 - present Instructure, Inc.
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

describe "Canvas::RedisConnections" do
  before(:each) do
    skip("requires redis") unless CanvasCache::Redis.enabled?
  end

  describe "disconnect!" do
    it "checkes connections without exploding" do
      expect { Canvas::RedisConnections.disconnect! }.to_not raise_error
    end
  end

  describe ".clear_idle!" do
    it "culls connections without exploding" do
      expect { Canvas::RedisConnections.clear_idle! }.to_not raise_error
    end
  end
end