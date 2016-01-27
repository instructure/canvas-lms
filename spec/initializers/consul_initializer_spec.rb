require_relative '../spec_helper'
require_relative '../../config/initializers/consul'

describe ConsulInitializer do
  class FakeLogger
    attr_reader :messages
    def initialize
      @messages = []
    end

    def warn(message)
      messages << message
    end
  end

  describe ".configure_with" do
    it "passes provided config info to DynamicSettings" do
      config_hash = {hi: "ho", host: "localhost", port: 80}
      ConsulInitializer.configure_with(config_hash.with_indifferent_access)
      expect(Canvas::DynamicSettings.config[:hi]).to eq("ho")
    end

    it "logs connection failure when trying to init data to a consul it can't find" do
      config_hash = {
        host: "somewhere-without-consul.gov",
        port: 123456,
        init_values: {
          'rich-content-service' => {
            'app-host' => 'rce.docker',
            'cdn-host' => 'rce.docker'
          }
        }
      }
      logger = FakeLogger.new
      ConsulInitializer.configure_with(config_hash.with_indifferent_access, logger)
      message = "INITIALIZATION: can't reach consul, attempts to load DynamicSettings will fail"
      expect(logger.messages).to include(message)
    end

    it "logs nothing if there's no config file" do
      logger = FakeLogger.new
      ConsulInitializer.configure_with(nil, logger)
      expect(logger.messages).to eq([])
    end
  end
end
