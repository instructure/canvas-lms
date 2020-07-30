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

require File.expand_path(File.dirname(__FILE__) + '/../sharding_spec_helper')

describe 'Notification Policy Override' do
  context 'Multi Shard User' do
    specs_require_sharding

    before(:once) do
      @shard1.activate do
        @teacher = User.create!(name: 'Mr Feeny', workflow_state: 'registered')
        @channel = communication_channel(@teacher, {username: 'feeny@instructure.com', active_cc: true})
        @notification = Notification.create!(name: 'Assignment Created', subject: 'Test', category: 'Due Date', shard: @shard1)
      end

      @shard2.activate do
        @account2 = Account.create!(name: 'Shard 2')
        @course = @account2.courses.create!(name: 'shard 2 math')
        @course.offer
        @course.enroll_user(@teacher)
      end
    end

    context 'enabled_for' do
      it 'queries if notification overrides are enabled correctly when another shard is active' do
        NotificationPolicyOverride.enable_for_context(@teacher, @course, enable: false)
        @shard2.activate do
          expect(NotificationPolicyOverride.enabled_for(@teacher, @course, channel: @channel)).to be false
          NotificationPolicyOverride.enable_for_context(@teacher, @course)
          expect(NotificationPolicyOverride.enabled_for(@teacher, @course, channel: @channel)).to be true
        end
      end
    end

    context 'find_all_for' do
      it 'queries a users policy overrides correctly when another shard is active' do
        NotificationPolicyOverride.create_or_update_for(@channel, 'Due Date', 'immediately', @course)
        @shard2.activate do
          npos = NotificationPolicyOverride.find_all_for(@teacher, @course, channel: @channel)
          expect(npos.count).to eq 1
          expect(npos.first.frequency).to eq 'immediately'
          expect(npos.first.communication_channel_id).to eq @channel.id
        end
      end
    end
  end
end
