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

describe Api::V1::Quiz do
  # Create a test class that includes the module
  let(:test_class) do
    Class.new do
      include Api::V1::Quiz

      attr_accessor :request

      def initialize(request = nil)
        @request = request
      end
    end
  end

  let(:test_instance) { test_class.new(mock_request) }
  let(:mock_request) { double("request") }

  describe "#quiz_client_ip" do
    context "when the feature flag is disabled" do
      before do
        allow(Account.site_admin).to receive(:feature_enabled?)
          .with(:use_client_ip_in_classic_quizzes)
          .and_return(false)
      end

      it "returns the remote_ip from the request" do
        allow(mock_request).to receive(:remote_ip).and_return("192.168.1.1")

        expect(test_instance.quiz_client_ip).to eq("192.168.1.1")
      end

      it "does not check the Client-Ip header" do
        allow(mock_request).to receive_messages(remote_ip: "192.168.1.1", headers: { "Client-Ip" => "10.0.0.1" })

        expect(test_instance.quiz_client_ip).to eq("192.168.1.1")
      end

      it "does not log the info message" do
        allow(mock_request).to receive(:remote_ip).and_return("192.168.1.1")

        expect(Rails.logger).not_to receive(:info)
        test_instance.quiz_client_ip
      end
    end

    context "when the feature flag is enabled" do
      before do
        allow(Account.site_admin).to receive(:feature_enabled?)
          .with(:use_client_ip_in_classic_quizzes)
          .and_return(true)
      end

      it "returns the Client-Ip header value" do
        headers = { "Client-Ip" => "10.0.0.1" }
        allow(mock_request).to receive(:headers).and_return(headers)

        expect(test_instance.quiz_client_ip).to eq("10.0.0.1")
      end

      it "logs an info message when using Client-Ip" do
        headers = { "Client-Ip" => "10.0.0.1" }
        allow(mock_request).to receive(:headers).and_return(headers)

        expect(Rails.logger).to receive(:info).with("Using Client-Ip for Classic Quizzes")
        test_instance.quiz_client_ip
      end

      it "returns nil if Client-Ip header is not present" do
        allow(mock_request).to receive(:headers).and_return({})

        expect(Rails.logger).to receive(:info).with("Using Client-Ip for Classic Quizzes")
        expect(test_instance.quiz_client_ip).to be_nil
      end

      it "does not call remote_ip when feature flag is enabled" do
        headers = { "Client-Ip" => "10.0.0.1" }
        allow(mock_request).to receive(:headers).and_return(headers)
        allow(Rails.logger).to receive(:info)

        expect(mock_request).not_to receive(:remote_ip)
        test_instance.quiz_client_ip
      end
    end
  end
end
