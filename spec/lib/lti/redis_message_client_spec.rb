#
# Copyright (C) 2018 - present Instructure, Inc.
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

require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

describe Lti::RedisMessageClient do
  include Lti::RedisMessageClient

  let_once(:context) { course_model }

  let(:launch) { {foo: 'bar'} }

  describe '#cache_launch' do
    it 'caches the launch as JSON' do
      verifier = cache_launch(launch, context)
      redis_key = "#{context.class.name}:#{Lti::RedisMessageClient::LTI_1_3_PREFIX}#{verifier}"
      expect(Canvas.redis.get(redis_key)).to eq launch.to_json
    end

    it 'allows setting the prefix' do
      verifier = cache_launch(launch, context, prefix: Lti::RedisMessageClient::SESSIONLESS_LAUNCH_PREFIX)
      redis_key = "#{context.class.name}:#{Lti::RedisMessageClient::SESSIONLESS_LAUNCH_PREFIX}#{verifier}"
      expect(Canvas.redis.get(redis_key)).to eq launch.to_json
    end
  end

  describe '#fetch_and_delete_launch' do
    let(:redis_key) { cache_launch(launch, context) }

    it 'fetches the launch data' do
      cached_launch = fetch_and_delete_launch(context, redis_key)
      expect(cached_launch).to eq launch.to_json
    end

    it 'deletes the redis entry' do
      fetch_and_delete_launch(context, redis_key)
      cached_launch = fetch_and_delete_launch(context, redis_key)
      expect(cached_launch).to be_nil
    end
  end
end
