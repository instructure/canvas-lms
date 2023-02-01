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

module Canvas::Plugins
  describe TicketingSystem do
    describe ".is_selected?" do
      let(:fake_settings) { double(settings_for_plugin: { type: "some_service" }) }

      it "is true if the provided plugin id is the byots selection" do
        expect(TicketingSystem.is_selected?("some_service", fake_settings)).to be(true)
      end

      it "is false for plugin ids that don't match the selection" do
        expect(TicketingSystem.is_selected?("other_service", fake_settings)).to be(false)
      end
    end

    describe ".register_plugin" do
      it "registers the given plugin with Canvas::Plugin using the TS tag" do
        id = "some_plugin_id"
        settings = { one: "two" }
        expect(Canvas::Plugin).to receive(:register).with(id, TicketingSystem::PLUGIN_ID, settings)
        TicketingSystem.register_plugin(id, settings) { nil }
      end

      it "fires the provided call back on every error report" do
        passed_report = nil
        TicketingSystem.register_plugin("plugin_id", {}) do |report|
          passed_report = report
        end
        new_report = ErrorReport.new
        new_report.run_callbacks(:on_send_to_external)
        expect(passed_report).to be(new_report)
      end
    end

    describe ".get_settings" do
      it "returns the settings from Canvas::Plugin for that plugin id" do
        plugin_id = "some_plugin"
        allow(Canvas::Plugin).to receive(:find).with(plugin_id).and_return(double(settings: { "a" => "b" }))
        expect(TicketingSystem.get_settings(plugin_id)["a"]).to eq("b")
      end

      it "returns an empty hash if nothing is registered" do
        expect(TicketingSystem.get_settings("none")).to be_empty
      end
    end
  end
end
