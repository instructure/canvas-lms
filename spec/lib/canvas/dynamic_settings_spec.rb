require_relative "../../spec_helper"
require_dependency "canvas/dynamic_settings"
require 'imperium/testing' # Not loaded by default

module Canvas
  describe DynamicSettings do
    before do
      @cached_config = DynamicSettings.config
    end

    after do
      begin
        DynamicSettings.config = @cached_config
      rescue Imperium::UnableToConnectError
        # don't fail the test if there is no consul running
      end
      Canvas::DynamicSettings.reset_cache!
      Canvas::DynamicSettings.fallback_data = nil
    end

    let(:parent_key){ "rich-content-service" }
    let(:imperium_read_options){ [:recurse, :stale] }
    let(:kv_client) { DynamicSettings.kv_client }

    describe ".config=" do
      let(:valid_config) do
        {
          "host"      =>"consul",
          "port"      => 8500,
          "ssl"       => true,
          "acl_token" => "some-long-string"
        }
      end

      it "configures imperium when config is set" do
        DynamicSettings.kv_client.stubs(:put)
        DynamicSettings.config = valid_config
        expect(Imperium.configuration.url.to_s).to eq("https://consul:8500")
      end

      it "sends initial config data by de-nesting a hash into keys" do
        config = valid_config.merge({
          'init_values' => {
            "rich-content-service" => {
              "app-host" => "rce.docker",
              "cdn-host" => "rce.docker"
            }
          }
        })

        expect(kv_client).to receive(:put)
          .with("config/canvas/rich-content-service/app-host", "rce.docker")
          .and_return(true)
        expect(kv_client).to receive(:put)
          .with("config/canvas/rich-content-service/cdn-host", "rce.docker")
          .and_return(true)
        # This is super gross but the alternative is to use expect_any_instance
        allow(Imperium::Client).to receive(:reset_default_clients).and_return(true)

        DynamicSettings.config = config
      end

      it 'must pass through timeout settings to the underlying library' do
        DynamicSettings.config = valid_config.merge({
          'connect_timeout' => 1,
          'send_timeout' => 2,
          'receive_timeout' => 3,
        })

        client_config = kv_client.config
        expect(client_config.connect_timeout).to eq 1
        expect(client_config.send_timeout).to eq 2
        expect(client_config.receive_timeout).to eq 3
      end
    end

    describe ".find" do
      describe "with consul config" do
        # we don't need to interact with a real consul for unit tests
        before(:each) do
          DynamicSettings.config = {} # just to be not nil
          DynamicSettings.fallback_data = nil
          allow(kv_client).to receive(:get)
            .with("config/canvas/#{parent_key}", *imperium_read_options)
            .and_return(
              Imperium::Testing.kv_get_response(
                body: [
                  { Key: "config/canvas/#{parent_key}/app-host", Value: "rce.insops.com"},
                  { Key: "config/canvas/#{parent_key}/cdn-host", Value: "asdfasdf.cloudfront.com"}
                ],
                options: imperium_read_options,
                prefix: "config/canvas/#{parent_key}"
              )
            )
        end

        it "loads the children of a k/v node as a hash" do
          rce_settings = DynamicSettings.find(parent_key)
          expect(rce_settings).to eq({
            "app-host" => "rce.insops.com",
            "cdn-host" => "asdfasdf.cloudfront.com"
          })
        end

        it "uses the last found value on catastrophic outage" do
          DynamicSettings.reset_cache!(hard: true)
          DynamicSettings.find(parent_key)
          # some values are now stored in case of connection failure
          allow(kv_client).to receive(:get)
            .with("config/canvas/#{parent_key}", imperium_read_options)
            .and_raise(Imperium::ConnectTimeout, "could not contact consul")

          rce_settings = DynamicSettings.find(parent_key)
          expect(rce_settings).to eq({
            "app-host" => "rce.insops.com",
            "cdn-host" => "asdfasdf.cloudfront.com"
          })
        end

        it "cant recover with no value cached for connection failure" do
          DynamicSettings.reset_cache!(hard: true)
          allow(kv_client).to receive(:get)
            .with("config/canvas/#{parent_key}", *imperium_read_options)
            .and_raise(Imperium::ConnectTimeout)

          expect{ DynamicSettings.find(parent_key) }.to(
            raise_error(Imperium::ConnectTimeout)
          )
        end
      end

      describe "without consul config" do
        before(:each){ DynamicSettings.config = nil }

        it "will load settings from fallback hash" do
          fallback_data = {
            'canvas' => {
              'encryption-secret' => 'asdf',
              'signing-secret' => 'fdas'
            }
          }.with_indifferent_access
          DynamicSettings.fallback_data = fallback_data
          canvas_settings = DynamicSettings.find("canvas")
          expect(canvas_settings).to eq({
            'encryption-secret' => 'asdf',
            'signing-secret' => 'fdas'
          })
        end

        it "errors if no fallback data" do
          DynamicSettings.fallback_data = nil
          expect{ DynamicSettings.find("canvas") }.to(
            raise_error(DynamicSettings::ConsulError,
                        "Unable to contact consul without config")
          )
        end
      end
    end

    describe ".from_cache" do
      before(:each){ DynamicSettings.config = {} } # just to be not nil
      after(:each){ DynamicSettings.reset_cache! }

      def stub_consul_with(value)
        allow(kv_client).to receive(:get)
          .with("config/canvas/#{parent_key}", *imperium_read_options)
          .and_return(
            Imperium::Testing.kv_get_response(
              body: [
                { Key: "config/canvas/#{parent_key}/app-host", Value: value},
              ],
              options: imperium_read_options,
              prefix: "config/canvas/#{parent_key}"
            )
          )
      end

      it "only queries consul the first time" do
        allow(kv_client).to receive(:get)
          .with("config/canvas/#{parent_key}", *imperium_read_options)
          .once # and only once, going to hit it several times
          .and_return(
            Imperium::Testing.kv_get_response(
              body: [
                { Key: "config/canvas/#{parent_key}/app-host", Value: 'rce.insops.net'},
              ],
              options: imperium_read_options,
              prefix: "config/canvas/#{parent_key}"
            )
          )
        5.times{ DynamicSettings.from_cache(parent_key) }
        value = DynamicSettings.from_cache(parent_key)
        expect(value["app-host"]).to eq("rce.insops.net")
      end

      it "definitely doesnt pickup new values once cached" do
        stub_consul_with("rce.insops.com")
        value = DynamicSettings.from_cache(parent_key)
        expect(value["app-host"]).to eq("rce.insops.com")
        stub_consul_with("CHANGED VALUE")
        value = DynamicSettings.from_cache(parent_key)
        expect(value["app-host"]).to eq("rce.insops.com")
      end

      it "returns new values after a cache clear" do
        stub_consul_with("rce.insops.com")
        DynamicSettings.from_cache(parent_key)
        stub_consul_with("CHANGED VALUE")
        DynamicSettings.reset_cache!
        value = DynamicSettings.from_cache(parent_key)
        expect(value["app-host"]).to eq("CHANGED VALUE")
      end

      it "caches values with timeouts" do
        stub_consul_with("rce.insops.com")
        value = DynamicSettings.from_cache(parent_key, expires_in: 5.minutes)
        expect(value["app-host"]).to eq("rce.insops.com")
        stub_consul_with("CHANGED VALUE")
        value = DynamicSettings.from_cache(parent_key, expires_in: 5.minutes)
        expect(value["app-host"]).to eq("rce.insops.com")
      end

      it "loads new values when timeout is past" do
        stub_consul_with("rce.insops.com")
        value = DynamicSettings.from_cache(parent_key, expires_in: 5.minutes)
        Timecop.travel(Time.zone.now + 6.minutes) do
          stub_consul_with("CHANGED VALUE")
          value = DynamicSettings.from_cache(parent_key, expires_in: 5.minutes)
          expect(value["app-host"]).to eq("CHANGED VALUE")
        end
      end

      it "accepts a timeout on a previously inifinity key" do
        stub_consul_with("rce.insops.com")
        value = DynamicSettings.from_cache(parent_key)
        Timecop.travel(Time.zone.now + 11.minutes) do
          stub_consul_with("CHANGED VALUE")
          value = DynamicSettings.from_cache(parent_key, expires_in: 10.minutes)
          expect(value["app-host"]).to eq("CHANGED VALUE")
        end
      end

      context "using catastrophic cache fallback" do
        let!(:now) { Time.zone.now }

        before(:each) do
          stub_consul_with("rce.insops.com")
          DynamicSettings.from_cache(parent_key) # prime cache
        end

        after(:each) do
          Canvas.unstub(:timeout_protection)
        end

        around do |example|
          Timecop.freeze(now + 11.minutes, &example)
        end

        it "still returns old values if connection fails after timeout" do
          Imperium::KV.stubs(:get).
            with("config/canvas/#{parent_key}", imperium_read_options).
            raises(Imperium::TimeoutError, "could not contact consul")
            value = DynamicSettings.from_cache(parent_key, expires_in: 10.minutes)
            expect(value["app-host"]).to eq("rce.insops.com")
        end

        it "returns old value during connection timeout" do
          Imperium::KV.stubs(:get).
            raises(Imperium::TimeoutError, "could not contact consul")
          value = DynamicSettings.from_cache(parent_key, expires_in: 10.minutes)
          expect(value["app-host"]).to eq("rce.insops.com")
        end
      end
    end
  end
end
