require 'spec_helper'

module Canvas::Plugins
  describe TicketingSystem do

    describe ".is_selected?" do
      let(:fake_settings){ stub(settings_for_plugin: {type: 'some_service'}) }
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
        settings = {one: "two"}
        Canvas::Plugin.expects(:register).with(id, TicketingSystem::PLUGIN_ID, settings)
        TicketingSystem.register_plugin(id, settings){|r| }
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
        Canvas::Plugin.stubs(:find).with(plugin_id).returns(stub(settings: {"a" => "b"}))
        expect(TicketingSystem.get_settings(plugin_id)['a']).to eq('b')
      end

      it 'returns an empty hash if nothing is registered' do
        expect(TicketingSystem.get_settings('none')).to be_empty
      end
    end
  end
end
