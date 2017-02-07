require 'spec_helper'

describe Twitter::Connection do

  describe ".config=" do
    it "accepts any object with a call interface" do
      conf_class = Class.new do
        def call
          { 'monkey' => 'banana' }
        end
      end

      described_class.config =  conf_class.new
      expect(described_class.config['monkey']).to eq('banana')
    end

    it "rejects configs that are not callable" do
      expect { described_class.config = Object.new }.to(
        raise_error(RuntimeError) do |e|
          expect(e.message).to match(/must respond to/)
        end
      )
    end
  end

  describe ".config_check" do
    it "checks new key/secret" do
      settings = { api_key: "key", secret_key: "secret" }

      config = double(call: {})
      Twitter::Connection.config = config
      consumer = double(get_request_token: "token")
      expect(OAuth::Consumer).to receive(:new).
        with("key", "secret", anything).and_return(consumer)

      expect(Twitter::Connection.config_check(settings)).to be_nil
    end
  end

end
