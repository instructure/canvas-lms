# frozen_string_literal: true

#
# Copyright (C) 2015 - present Instructure, Inc.
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

module Canvas::Plugins::TicketingSystem
  describe WebPostPlugin do
    describe "#export_error" do
      it "posts the error_report document to the configured endpoint" do
        ticketing = instance_double(Canvas::Plugins::TicketingSystem)
        document = { key: "value", info: "data" }
        report = instance_double(Canvas::Plugins::TicketingSystem::CustomError, to_document: document)
        endpoint = "http://someserver.com/some/endpoint"
        config = { endpoint_uri: endpoint }
        plugin = WebPostPlugin.new(ticketing)
        expect(HTTParty).to receive(:post).with(endpoint, include(body: document.to_json))
        plugin.export_error(report, config)
      end

      it "truncates become_user_uri to the maximum string length" do
        ticketing = instance_double(Canvas::Plugins::TicketingSystem)
        long_uri = "http://something.com/path?become_user_id=42&state=#{"x" * 300}"
        document = { reporter: { become_user_uri: long_uri } }
        report = instance_double(Canvas::Plugins::TicketingSystem::CustomError, to_document: document)
        endpoint = "http://someserver.com/some/endpoint"
        config = { endpoint_uri: endpoint }
        plugin = WebPostPlugin.new(ticketing)

        allow(HTTParty).to receive(:post)
        plugin.export_error(report, config)

        expect(HTTParty).to have_received(:post) do |_url, opts|
          request_body = JSON.parse(opts[:body])
          expect(request_body.dig("reporter", "become_user_uri").length).to be <= ErrorReport.maximum_string_length
        end
      end
    end
  end
end
