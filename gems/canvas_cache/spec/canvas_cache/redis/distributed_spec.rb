# frozen_string_literal: true

#
# Copyright (C) 2011 - present Instructure, Inc.
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

describe CanvasCache::Redis::Distributed do
  it "supports failsafe on hmget" do
    redis = Redis::Distributed.new([])
    redis.add_node("redis://localhost/")
    allow(RedisClient::RubyConnection).to receive(:new).and_raise(RedisClient::TimeoutError)
    expect(redis.hmget("foo", "bar", failsafe: [1, 2])).to eq [1, 2]
  end
end
