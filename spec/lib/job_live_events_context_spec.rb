# frozen_string_literal: true

#
# Copyright (C) 2017 - present Instructure, Inc.
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

require 'spec_helper'

describe JobLiveEventsContext do
  class FakeDelayed
    include JobLiveEventsContext

    attr_accessor :global_id, :tag

    def initialize
      @global_id = 1
      @tag = 'foobar'
    end
  end

  let(:fake_delayed_instance) { FakeDelayed.new }

  describe '#live_events_context' do
    it 'yields a hash with job and default account details' do
      global_id = Account.default.global_id.to_s
      uuid = Account.default.uuid
      lti_guid = Account.default.lti_guid

      expect(fake_delayed_instance.live_events_context).to eq(
        {
          job_id: '1',
          job_tag: 'foobar',
          root_account_id: global_id,
          root_account_uuid: uuid,
          root_account_lti_guid: lti_guid,
          producer: 'canvas',
        }
      )
    end

    it 'stringifies all ids' do
      context_values = fake_delayed_instance.live_events_context.values

      context_values.each do |value|
        expect(value).to be_a(String)
      end
    end
  end
end
