# frozen_string_literal: true

#
# Copyright (C) 2016 - present Instructure, Inc.
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

module Services
  describe FeatureAnalyticsService do
    context "message delivery" do
      before do
        @client = double("sqs client")
        @config = {
          "queue_url" => "http://queue.url"
        }
        allow(FeatureAnalyticsService).to receive_messages(client: @client, config: @config)
      end

      it "sends messages to the queue_url specified in the config" do
        message = {
          feature: "no_grades",
          context: "Course",
          state: true
        }
        expect(@client).to receive(:send_message).once.with({ queue_url: @config["queue_url"], message_body: message.to_json })
        FeatureAnalyticsService.persist_feature_evaluation(message)
      end
    end
  end
end
