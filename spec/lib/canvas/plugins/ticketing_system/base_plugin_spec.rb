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
  class FakePlugin < BasePlugin
    def plugin_id
      "fake_plugin"
    end

    def settings
      { setting1: 1, setting2: 2 }
    end

    def export_error(report, conf)
      reports << [report, conf]
    end

    def reports
      @reports ||= []
    end
  end

  class FakeTicketing
    attr_reader :callback

    def register_plugin(_id, _settings, &callback)
      @callback = callback
    end
  end

  describe BasePlugin do
    describe "#register!" do
      it "interacts with the ticketing system to get this plugin registered" do
        ticketing = double
        plugin = FakePlugin.new(ticketing)
        expect(ticketing).to receive(:register_plugin).with("fake_plugin", plugin.settings)
        plugin.register!
      end

      it "builds a callback that submits the report and the plugin conf to the export_error action" do
        tix = FakeTicketing.new
        allow(tix).to receive(:get_settings).with("fake_plugin").and_return({ fake: "settings" })
        allow(tix).to receive_messages(is_selected?: true)
        plugin = FakePlugin.new(tix)
        plugin.register!
        tix.callback.call(ErrorReport.new)
        log = plugin.reports.first
        expect(log[0]).to be_a(CustomError)
        expect(log[1]).to eq({ fake: "settings" })
      end
    end

    describe "#enabled?" do
      let(:ticketing) { double }
      let(:plugin) { FakePlugin.new(ticketing) }

      it "is true if the plugin is selected and the config has values" do
        allow(ticketing).to receive(:is_selected?).with("fake_plugin").and_return(true)
        allow(ticketing).to receive(:get_settings).with("fake_plugin").and_return({ some: "value" })
        expect(plugin.enabled?).to be(true)
      end

      it "is false if the plugin is not selected" do
        allow(ticketing).to receive(:is_selected?).with("fake_plugin").and_return(false)
        allow(ticketing).to receive(:get_settings).with("fake_plugin").and_return({ some: "value" })
        expect(plugin.enabled?).to be(false)
      end

      it "is false if the config is empty" do
        allow(ticketing).to receive(:is_selected?).with("fake_plugin").and_return(true)
        allow(ticketing).to receive(:get_settings).with("fake_plugin").and_return({})
        expect(plugin.enabled?).to be(false)
      end
    end
  end
end
