require_relative '../spec_helper'
require_relative '../../config/initializers/linked_in'

describe CanvasLinkedInConfig do

  describe ".call" do
    it "returns a config with indifferent access" do
      plugin = stub(settings: {client_id: "abcdefg", client_secret_dec: "12345"})
      Canvas::Plugin.stubs(:find).with(:linked_in).returns(plugin)
      output = described_class.call
      expect(output['api_key']).to eq("abcdefg")
      expect(output[:api_key]).to eq("abcdefg")
    end
  end

end
