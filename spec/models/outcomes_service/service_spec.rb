#
# Copyright (C) 2020 - present Instructure, Inc.
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

require_relative '../../spec_helper'
require_relative '../../sharding_spec_helper'

describe OutcomesService::Service do
  Service = OutcomesService::Service

  let(:root_account) { account_model }
  let(:course) { course_model(root_account: root_account) }

  context 'without settings' do
    describe '.url' do
      it 'returns nil url' do
        expect(Service.url(course)).to be_nil
      end
    end

    describe '.enabled_in_context?' do
      it 'returns not enabled' do
        expect(Service.enabled_in_context?(course)).to eq false
      end
    end

    describe '.jwt' do
      it 'returns nil jwt' do
        expect(Service.jwt(course, 'outcomes.show')).to be_nil
      end
    end
  end

  context 'with settings' do
    before do
      root_account.settings[:provision] = { 'outcomes' => {
        domain: 'canvas.test',
        consumer_key: 'blah',
        jwt_secret: 'woo'
      }}
      root_account.save!
    end

    describe '.url' do
      it 'returns url' do
        expect(Service.url(course)).to eq 'http://canvas.test'
      end
    end

    describe '.enabled_in_context?' do
      it 'returns enabled' do
        expect(Service.enabled_in_context?(course)).to eq true
      end
    end

    describe '.jwt' do
      it 'returns valid jwt' do
        expect(Service.jwt(course, 'outcomes.show')).not_to be_nil
      end

      it 'includes overrides' do
        token = Service.jwt(course, 'outcomes.list', overrides: { context_uuid: 'xyz' })
        decoded = JWT.decode(token, 'woo', true, algorithm: 'HS512')
        expect(decoded[0]).to include(
          'host' => 'canvas.test',
          'consumer_key' => 'blah',
          'scope' => 'outcomes.list',
          'context_uuid' => 'xyz'
        )
      end
    end
  end
end
