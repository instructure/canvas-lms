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
  end
end
