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
require_dependency "canvas/plugins/ticketing_system/base_plugin"

module Canvas::Plugins::TicketingSystem
  class FakePlugin < BasePlugin
    def plugin_id; "fake_plugin"; end

    def settings; {setting1: 1, setting2: 2}; end

    def export_error(report, conf)
      reports << [report, conf]
    end

    def reports
      @reports ||= []
    end
  end

  class FakeTicketing
    attr_reader :callback
    def register_plugin(id, settings, &callback)
      @callback = callback
    end
  end

  describe BasePlugin do
    describe "#register!" do
      it "interacts with the ticketing system to get this plugin registered" do
        ticketing = stub()
        plugin = FakePlugin.new(ticketing)
        ticketing.expects(:register_plugin).with("fake_plugin", plugin.settings)
        plugin.register!
      end

      it "builds a callback that submits the report and the plugin conf to the export_error action" do
        tix = FakeTicketing.new
        tix.stubs(:get_settings).with("fake_plugin").returns({fake: "settings"})
        tix.stubs(is_selected?: true)
        plugin = FakePlugin.new(tix)
        plugin.register!
        tix.callback.call(ErrorReport.new)
        log = plugin.reports.first
        expect(log[0]).to be_a(CustomError)
        expect(log[1]).to eq({fake: "settings"})
      end
    end

    describe "#enabled?" do
      let(:ticketing){ stub() }
      let(:plugin){ FakePlugin.new(ticketing) }

      it "is true if the plugin is selected and the config has values" do
        ticketing.stubs(:is_selected?).with("fake_plugin").returns(true)
        ticketing.stubs(:get_settings).with("fake_plugin").returns({some: 'value'})
        expect(plugin.enabled?).to be(true)
      end

      it "is false if the plugin is not selected" do
        ticketing.stubs(:is_selected?).with("fake_plugin").returns(false)
        ticketing.stubs(:get_settings).with("fake_plugin").returns({some: 'value'})
        expect(plugin.enabled?).to be(false)
      end

      it "is false if the config is empty" do
        ticketing.stubs(:is_selected?).with("fake_plugin").returns(true)
        ticketing.stubs(:get_settings).with("fake_plugin").returns({})
        expect(plugin.enabled?).to be(false)
      end
    end
  end

end
