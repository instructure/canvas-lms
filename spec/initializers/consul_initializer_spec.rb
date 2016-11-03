require_relative '../spec_helper'
require_relative '../../config/initializers/consul'

describe ConsulInitializer do
  after(:each) do
    Canvas::DynamicSettings.reset_cache!
    Canvas::DynamicSettings.fallback_data = nil
  end

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
    include WebMock::API

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
      stub_request(:put, "https://somewhere-without-consul.gov:123456/v1/kv/config/canvas/rich-content-service/app-host").
        to_return(:status => 500)
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

  describe ".fallback to" do
    let(:fallback_data) do
      {
        'rich-content-service' => {
          'app-host' => 'rce.docker',
          'cdn-host' => 'rce.docker'
        },
        'canvas' => {
          'encryption-secret' => 'asdf',
          'signing-secret' => 'fdas'
        }
      }
    end

    it "provides fallback data to DynamicSettings" do
      ConsulInitializer.fallback_to(fallback_data)
      s_secret = Canvas::DynamicSettings.
        fallback_data['canvas']['signing-secret']
      expect(s_secret).to eq('fdas')
    end

    it "puts the data in with indifferent access" do
      ConsulInitializer.fallback_to(fallback_data)
      e_secret = Canvas::DynamicSettings.
        fallback_data[:canvas]["encryption-secret".to_sym]
      expect(e_secret).to eq('asdf')
    end
  end

  describe "just from loading" do
    it "clears the DynamicSettings cache on reload" do
      Canvas::DynamicSettings.reset_cache!
      Canvas::DynamicSettings.cache["key"] = {
        value: "value",
        timestamp: Time.zone.now.to_i
      }
      expect(Canvas::DynamicSettings.from_cache("key")).to eq("value")
      Canvas::Reloader.reload!
      expect(Canvas::DynamicSettings.cache).to eq({})
    end
  end
end
