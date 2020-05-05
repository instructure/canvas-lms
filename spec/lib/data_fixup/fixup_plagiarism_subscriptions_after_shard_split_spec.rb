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

require 'plagiarism_platform_spec_helper'

describe DataFixup::FixupPlagiarismSubscriptionsAfterShardSplit do
  include_context 'plagiarism_platform'

  describe "run" do
    before(:once) do
      resource_handler.message_handlers << message_handler
      tool_proxy.resources << resource_handler
      tool_proxy.save!
    end

    context 'when there are configured assignments' do
      before do
        assignment.tool_settings_tool = message_handler
        assignment_two.tool_settings_tool = message_handler
        assignment.save!
        assignment_two.save!
      end

      it 'updates all subscriptions' do
        pre_fixup_subscriptions = AssignmentConfigurationToolLookup.all.pluck(:subscription_id)
        DataFixup::FixupPlagiarismSubscriptionsAfterShardSplit.run
        expect(AssignmentConfigurationToolLookup.all.pluck(:subscription_id)).not_to include(
          *pre_fixup_subscriptions
        )
      end

      context 'when an error occurs deleting the subscription' do
        before { allow(subscription_service).to receive(:destroy_tool_proxy_subscription).and_raise 'error' }

        RSpec::Matchers.define :a_failed_to_delete_subscription_message do
          match { |actual| actual.dig(:tags, :type) == 'destroy_subscription_after_shard_split' }
        end

        it 'logs the error' do
          expect(Canvas::Errors).to receive(:capture).twice.with(
            anything,
            a_failed_to_delete_subscription_message
          )
          DataFixup::FixupPlagiarismSubscriptionsAfterShardSplit.run
        end
      end

      context 'when an error occurs creating the subscription' do
        before { allow(subscription_service).to receive(:create_tool_proxy_subscription).and_raise 'error' }

        RSpec::Matchers.define :a_failed_to_create_subscription_message do
          match { |actual| actual.dig(:tags, :type) == 'create_subscription_after_shard_split' }
        end

        it 'logs the error' do
          expect(Canvas::Errors).to receive(:capture).twice.with(
            anything,
            a_failed_to_create_subscription_message
          )
          DataFixup::FixupPlagiarismSubscriptionsAfterShardSplit.run
        end
      end
    end
  end
end