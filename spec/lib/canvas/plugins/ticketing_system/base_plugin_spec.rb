require 'spec_helper'

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
