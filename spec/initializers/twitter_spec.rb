require_relative '../spec_helper'
require_relative '../../config/initializers/twitter'

describe CanvasTwitterConfig do

  describe "#call" do
    it "returns a config with indifference access" do
      plugin = stub(settings: {consumer_key: "abcdefg", consumer_secret_dec: "12345"})
      Canvas::Plugin.stubs(:find).with(:twitter).returns(plugin)
      output = described_class.call
      expect(output['api_key']).to eq("abcdefg")
      expect(output[:api_key]).to eq("abcdefg")
    end
  end
end
