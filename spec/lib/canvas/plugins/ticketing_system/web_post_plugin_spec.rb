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

require 'spec_helper'
require_dependency "canvas/plugins/ticketing_system/web_post_plugin"

module Canvas::Plugins::TicketingSystem
  describe WebPostPlugin do
    describe "#export_error" do
      it "posts the error_report document to the configured endpoint" do
        ticketing = stub()
        document = {key: "value", info: "data"}
        report = stub(to_document: document)
        endpoint = "http://someserver.com/some/endpoint"
        config = {endpoint_uri: endpoint}
        plugin = WebPostPlugin.new(ticketing)
        HTTParty.expects(:post).with(endpoint, has_entry(body: document.to_json))
        plugin.export_error(report, config)
      end
    end
  end
end
