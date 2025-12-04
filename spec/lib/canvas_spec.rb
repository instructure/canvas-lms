# frozen_string_literal: true

#
# Copyright (C) 2011 - present Instructure, Inc.
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
#

describe Canvas do
  describe ".timeout_protection" do
    it "wraps the block in a timeout" do
      expect(Timeout).to receive(:timeout).with(15.0, nil).and_yield
      ran = false
      Canvas.timeout_protection("spec") { ran = true }
      expect(ran).to be true

      # service-specific timeout
      Setting.set("service_spec_timeout", "1")
      expect(Timeout).to receive(:timeout).with(1, nil).and_yield
      ran = false
      Canvas.timeout_protection("spec") { ran = true }
      expect(ran).to be true
    end

    it "raises on timeout if raise_on_timeout option is specified" do
      expect(Timeout).to receive(:timeout).and_raise(Timeout::Error)
      expect { Canvas.timeout_protection("spec", raise_on_timeout: true) { nil } }.to raise_error(Timeout::Error)
    end

    it "uses the timeout argument over the generic default" do
      expect(Timeout).to receive(:timeout).with(23, nil)
      Canvas.timeout_protection("foo", fallback_timeout_length: 23)
    end

    it "uses the settings timeout over the timeout argument" do
      Setting.set("service_foo_timeout", "1")
      expect(Timeout).to receive(:timeout).with(1, nil)
      Canvas.timeout_protection("foo", fallback_timeout_length: 23)
    end

    if Canvas.redis_enabled?
      it "skips calling the block after X failures" do
        Setting.set("service_spec_cutoff", "2")
        expect(Timeout).to receive(:timeout).with(15, nil).twice.and_raise(Timeout::Error)
        Canvas.timeout_protection("spec") { nil }
        Canvas.timeout_protection("spec") { nil }
        ran = false
        # third time, won't call timeout
        Canvas.timeout_protection("spec") { ran = true }
        expect(ran).to be false
        # verify the redis key has a ttl
        key = "service:timeouts:spec:error_count"
        expect(Canvas.redis.get(key)).to eq "2"
        expect(Canvas.redis.ttl(key)).to be_present
        # delete the redis key and it'll try again
        Canvas.redis.del(key)
        expect(Timeout).to receive(:timeout).with(15, nil).and_yield
        Canvas.timeout_protection("spec") { ran = true }
        expect(ran).to be true
      end

      it "raises on cutoff if raise_on_timeout option is specified" do
        key = "service:timeouts:spec:error_count"
        Canvas.redis.set(key, 42)
        expect { Canvas.timeout_protection("spec", raise_on_timeout: true) { nil } }
          .to raise_error(Timeout::Error)
        expect(Canvas.redis.get(key)).to eq "42"
      end

      it "calls percent_short_circuit_timeout when set to do so" do
        Setting.set("service_spec_timeout_protection_method", "percentage")
        expect(Canvas).to receive(:percent_short_circuit_timeout).once
        Canvas.timeout_protection("spec") { nil }
      end
    end
  end

  if Canvas.redis_enabled?
    describe ".lookup_cache_store" do
      it "has the switchman namespace when using the pre-existing data redis" do
        store = Canvas.lookup_cache_store({ "cache_store" => "redis_cache_store" }, Rails.env)
        expect(store.options[:namespace]).not_to be_nil
        expect(store.redis).to eq Canvas.redis
      end
    end

    describe ".short_circuit_timeout" do
      it "wraps the block in a timeout" do
        expect(Timeout).to receive(:timeout).with(15, nil).and_yield
        ran = false
        Canvas.short_circuit_timeout(Canvas.redis, "spec", 15, nil) { ran = true }
        expect(ran).to be true
      end

      it "skips calling the block after X failures" do
        Setting.set("service_spec_cutoff", "2")
        expect(Timeout).to receive(:timeout).with(15, nil).twice.and_raise(Timeout::Error)
        expect { Canvas.short_circuit_timeout(Canvas.redis, "spec", 15, nil) { nil } }
          .to raise_error(Timeout::Error)
        expect { Canvas.short_circuit_timeout(Canvas.redis, "spec", 15, nil) { nil } }
          .to raise_error(Timeout::Error)
        ran = false
        # third time, won't call timeout
        expect { Canvas.short_circuit_timeout(Canvas.redis, "spec", 15, nil) { ran = true } }
          .to raise_error(Timeout::Error)
        expect(ran).to be false
        # verify the redis key has a ttl
        key = "service:timeouts:spec:error_count"
        expect(Canvas.redis.get(key)).to eq "2"
        expect(Canvas.redis.ttl(key)).to be_present
        # delete the redis key and it'll try again
        Canvas.redis.del(key)
        expect(Timeout).to receive(:timeout).with(15, nil).and_yield
        Canvas.short_circuit_timeout(Canvas.redis, "spec", 15, nil) { ran = true }
        expect(ran).to be true
      end

      it "raises TimeoutCutoff when the cutoff is reached" do
        Setting.set("service_spec_cutoff", "2")
        key = "service:timeouts:spec:error_count"
        Canvas.redis.set(key, 42)
        expect { Canvas.short_circuit_timeout(Canvas.redis, "spec", 15, nil) { nil } }
          .to raise_error(Canvas::TimeoutCutoff)
        expect(Canvas.redis.get(key)).to eq "42"
      end
    end

    describe ".percent_short_circuit_timeout" do
      it "raises TimeoutCutoff when the protection key is present" do
        Canvas.redis.set("service:timeouts:spec:percent_counter:protection_activated", "true")
        Canvas.redis.expire("service:timeouts:spec:percent_counter:protection_activated", 1)
        expect { Canvas.percent_short_circuit_timeout(Canvas.redis, "spec", 15, nil) { nil } }
          .to raise_error(Canvas::TimeoutCutoff)
      end

      it "raise TimeoutCutoff when the failure rate is too high" do
        counter = Canvas::FailurePercentCounter.new(Canvas.redis,
                                                    "service:timeouts:spec:percent_counter")
        expect(counter).to receive(:failure_rate).and_return(0.2)
        expect(Canvas::FailurePercentCounter).to receive(:new).and_return(counter)
        expect { Canvas.percent_short_circuit_timeout(Canvas.redis, "spec", 15, nil) { nil } }
          .to raise_error(Canvas::TimeoutCutoff)
      end

      it "wraps the block in a timeout" do
        expect(Timeout).to receive(:timeout).with(15, nil).and_yield
        ran = false
        Canvas.percent_short_circuit_timeout(Canvas.redis, "spec", 15, nil) { ran = true }
        expect(ran).to be true
      end

      it "increments the counter when the block is called" do
        counter = Canvas::FailurePercentCounter.new(Canvas.redis,
                                                    "service:timeouts:spec:percent_counter")
        expect(counter).to receive(:failure_rate).and_return(0.0)
        expect(counter).to receive(:increment_count)
        expect(Canvas::FailurePercentCounter).to receive(:new).and_return(counter)
        Canvas.percent_short_circuit_timeout(Canvas.redis, "spec", 15, nil) { nil }
      end

      it "raises Timeout::Error on timeout" do
        expect(Timeout).to receive(:timeout).and_raise(Timeout::Error)
        expect { Canvas.percent_short_circuit_timeout(Canvas.redis, "spec", 15, nil) { nil } }
          .to raise_error(Timeout::Error)
      end

      it "increments the failure count on timeout" do
        expect(Timeout).to receive(:timeout).and_raise(Timeout::Error)
        counter = Canvas::FailurePercentCounter.new(Canvas.redis,
                                                    "service:timeouts:spec:percent_counter")
        expect(counter).to receive(:failure_rate).and_return(0.0)
        expect(counter).to receive(:increment_count)
        expect(counter).to receive(:increment_failure)
        expect(Canvas::FailurePercentCounter).to receive(:new).and_return(counter)
        expect { Canvas.percent_short_circuit_timeout(Canvas.redis, "spec", 15, nil) { nil } }
          .to raise_error(Timeout::Error)
      end

      it "sets the protection activated key if failure rate too high" do
        counter = Canvas::FailurePercentCounter.new(Canvas.redis,
                                                    "service:timeouts:spec:percent_counter")
        expect(counter).to receive(:failure_rate).and_return(0.2)
        expect(Canvas::FailurePercentCounter).to receive(:new).and_return(counter)
        expect { Canvas.percent_short_circuit_timeout(Canvas.redis, "spec", 15, nil) { nil } }
          .to raise_error(Timeout::Error)
        key = "service:timeouts:spec:percent_counter:protection_activated"
        expect(Canvas.redis.get(key)).to eq "true"
        expect(Canvas.redis.ttl(key)).to be_present
      end
    end
  end

  describe ".infer_user" do
    it "is generally safe to call even if nothing set" do
      expect(Canvas.infer_user).to be_nil
    end

    it "infers the real user if the right pseudonym exists" do
      root_account = Account.site_admin
      user = user_model
      pseudonym_model(user:, account: root_account, unique_id: "someuser")
      expect(Canvas.infer_user("someuser")).to eq(user)
    end
  end

  describe ".load_config_from_consul" do
    let(:sample_config) do
      {
        "key" => "value",
        "nested" => { "data" => "test" }
      }
    end

    before do
      allow(Rails).to receive(:env).and_return(ActiveSupport::StringInquirer.new("production"))
    end

    it "loads config from Consul when available" do
      proxy = instance_double(DynamicSettings::PrefixProxy)
      allow(DynamicSettings).to receive(:find).and_return(proxy)
      allow(proxy).to receive(:[]).with("test_config.yml", any_args).and_return(YAML.dump(sample_config))

      config = Canvas.load_config_from_consul("test_config")
      expect(config).to eq({ "key" => "value", "nested" => { "data" => "test" } })
    end

    it "falls back to ConfigFile when Consul returns empty" do
      proxy = instance_double(DynamicSettings::PrefixProxy)
      allow(DynamicSettings).to receive(:find).and_return(proxy)
      allow(proxy).to receive(:[]).with("test_config.yml", any_args).and_return(nil)
      allow(ConfigFile).to receive(:load).with("test_config", "production").and_return({ "fallback" => "data" })

      config = Canvas.load_config_from_consul("test_config")
      expect(config).to eq({ "fallback" => "data" })
    end

    it "falls back to ConfigFile when Consul raises an error" do
      proxy = instance_double(DynamicSettings::PrefixProxy)
      allow(DynamicSettings).to receive(:find).and_return(proxy)
      allow(proxy).to receive(:[]).and_raise(StandardError, "Consul connection failed")
      allow(ConfigFile).to receive(:load).with("test_config", "production").and_return({ "fallback" => "data" })

      config = Canvas.load_config_from_consul("test_config")
      expect(config).to eq({ "fallback" => "data" })
    end

    it "uses failsafe_cache when specified" do
      proxy = instance_double(DynamicSettings::PrefixProxy)
      allow(DynamicSettings).to receive(:find).and_return(proxy)
      expect(proxy).to receive(:[]).with("test_config.yml", failsafe_cache: Rails.root.join("config")).and_return(YAML.dump(sample_config))

      config = Canvas.load_config_from_consul("test_config", failsafe_cache: true)
      expect(config).to eq({ "key" => "value", "nested" => { "data" => "test" } })
    end

    it "accepts cluster parameter" do
      proxy = instance_double(DynamicSettings::PrefixProxy)
      expect(DynamicSettings).to receive(:find).with(tree: :private, cluster: "cluster21", default_ttl: 5.minutes).and_return(proxy)
      allow(proxy).to receive(:[]).and_return(YAML.dump(sample_config))

      config = Canvas.load_config_from_consul("test_config", cluster: "cluster21")
      expect(config).to eq({ "key" => "value", "nested" => { "data" => "test" } })
    end

    it "accepts custom TTL" do
      proxy = instance_double(DynamicSettings::PrefixProxy)
      expect(DynamicSettings).to receive(:find).with(tree: :private, cluster: nil, default_ttl: 10.minutes).and_return(proxy)
      allow(proxy).to receive(:[]).and_return(YAML.dump(sample_config))

      config = Canvas.load_config_from_consul("test_config", default_ttl: 10.minutes)
      expect(config).to eq({ "key" => "value", "nested" => { "data" => "test" } })
    end

    it "returns config with indifferent access" do
      proxy = instance_double(DynamicSettings::PrefixProxy)
      allow(DynamicSettings).to receive(:find).and_return(proxy)
      allow(proxy).to receive(:[]).and_return(YAML.dump(sample_config))

      config = Canvas.load_config_from_consul("test_config")
      expect(config[:key]).to eq("value")
      expect(config["key"]).to eq("value")
    end
  end

  describe ".load_config_from_consul_only" do
    let(:sample_config) do
      {
        "key" => "value",
        "nested" => { "data" => "test" }
      }
    end

    it "loads config from Consul when available" do
      proxy = instance_double(DynamicSettings::PrefixProxy)
      allow(DynamicSettings).to receive(:find).and_return(proxy)
      allow(proxy).to receive(:[]).with("test_config.yml", failsafe_cache: false).and_return(YAML.dump(sample_config))

      config = Canvas.load_config_from_consul_only("test_config")
      expect(config).to eq({ "key" => "value", "nested" => { "data" => "test" } })
    end

    it "returns nil when Consul has no config" do
      proxy = instance_double(DynamicSettings::PrefixProxy)
      allow(DynamicSettings).to receive(:find).and_return(proxy)
      allow(proxy).to receive(:[]).with("test_config.yml", failsafe_cache: false).and_return(nil)

      config = Canvas.load_config_from_consul_only("test_config")
      expect(config).to be_nil
    end

    it "does not fall back to ConfigFile" do
      proxy = instance_double(DynamicSettings::PrefixProxy)
      allow(DynamicSettings).to receive(:find).and_return(proxy)
      allow(proxy).to receive(:[]).with("test_config.yml", failsafe_cache: false).and_return(nil)
      expect(ConfigFile).not_to receive(:load)

      Canvas.load_config_from_consul_only("test_config")
    end

    it "returns config with indifferent access" do
      proxy = instance_double(DynamicSettings::PrefixProxy)
      allow(DynamicSettings).to receive(:find).and_return(proxy)
      allow(proxy).to receive(:[]).and_return(YAML.dump(sample_config))

      config = Canvas.load_config_from_consul_only("test_config")
      expect(config[:key]).to eq("value")
      expect(config["key"]).to eq("value")
    end
  end
end
