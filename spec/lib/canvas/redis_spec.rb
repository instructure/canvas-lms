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

describe "CanvasCache::Redis", if: Canvas.redis_enabled? do
  subject(:store) { Canvas.lookup_cache_store({ cache_store: :redis_cache_store, url: "redis://doesntexist:9873/1" }, Rails.env) }

  it "skips setting cache on error" do
    expect(Setting).to receive(:get).with(anything, anything, skip_cache: true).at_least(:once)
    store.read("foo")
  end

  it "logs an error on error" do
    expect(Canvas::Errors).to receive(:capture)
    store.read("foo")
  end

  it "logs to statsd on error" do
    expect(InstStatsd::Statsd).to receive(:increment).with("redis.errors.all")
    expect(InstStatsd::Statsd).to receive(:increment).with("redis.errors.redis://doesntexist:9873/1", anything)
    expect(InstStatsd::Statsd).to receive(:increment).with("errors.warn", anything).at_least(:once)
    store.read("foo")
  end
end
