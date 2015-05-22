require 'spec_helper'

module Canvas
  describe ErrorStats do
    describe ".capture" do
      before(:each) do
        CanvasStatsd::Statsd.stubs(:increment)
      end
      let(:data){ {} }

      it "increments errors.all always" do
        CanvasStatsd::Statsd.expects(:increment).with("errors.all")
        described_class.capture("something", data)
      end

      it "increments the message name for a string" do
        CanvasStatsd::Statsd.expects(:increment).with("errors.something")
        described_class.capture("something", data)
      end

      it "increments the message name for a symbol" do
        CanvasStatsd::Statsd.expects(:increment).with("errors.something")
        described_class.capture(:something, data)
      end

      it "bumps the exception name for anything else" do
        CanvasStatsd::Statsd.expects(:increment).with("errors.StandardError")
        described_class.capture(StandardError.new, data)
      end
    end
  end
end
