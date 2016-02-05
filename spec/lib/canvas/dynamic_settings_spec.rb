require_relative "../../spec_helper"
require 'diplomat'

module Canvas
  describe DynamicSettings do
    before do
      @cached_config = DynamicSettings.config
    end

    after do
      Diplomat::Kv.unstub(:put)
      begin
        DynamicSettings.config = @cached_config
      rescue Faraday::ConnectionFailed
        # don't fail the test if there is no consul running
      end
    end

    describe ".config=" do

      let(:valid_config) do
        {
          "host"      =>"consul",
          "port"      => 8500,
          "ssl"       => true,
          "acl_token" => "some-long-string"
        }
      end

      it "configures diplomat when config is set" do
        Diplomat::Kv.stubs(:put)
        DynamicSettings.config = valid_config
        expect(Diplomat.configuration.url).to eq("https://consul:8500")
      end

      it "sends initial config data by de-nesting a hash into keys" do
        init_data = {
          "rich-content-service" => {
            "app-host" => "rce.docker",
            "cdn-host" => "rce.docker"
          }
        }

        Diplomat::Kv.expects(:put)
          .with("/config/canvas/rich-content-service/app-host", "rce.docker")
          .at_least_once
        Diplomat::Kv.expects(:put)
          .with("/config/canvas/rich-content-service/cdn-host", "rce.docker")
          .at_least_once

        DynamicSettings.config = valid_config.merge({
          "init_values" => init_data
        })

      end
    end

    describe ".find" do
      # we don't need to interact with a real consul for unit tests
      before { Diplomat::Kv.stubs(:put) }

      it "explodes when trying to access it without a config file" do
        DynamicSettings.config = nil
        expect{ DynamicSettings.find("rich-content-service") }.to(
          raise_error(DynamicSettings::ConsulError)
        )
      end

      it "loads the children of a k/v node as a hash" do
        DynamicSettings.config = {} # just to be not nil
        parent_key = "rich-content-service"
        Diplomat::Kv.stubs(:get).with("/config/canvas/#{parent_key}", recurse: true).returns(
          [
            { key: "#{parent_key}/app-host", value: "rce.insops.com"},
            { key: "#{parent_key}/cdn-host", value: "asdfasdf.cloudfront.com"}
          ]
        )
        rce_settings = DynamicSettings.find(parent_key)
        expect(rce_settings).to eq({
          "app-host" => "rce.insops.com",
          "cdn-host" => "asdfasdf.cloudfront.com"
        })
      end
    end


  end
end
