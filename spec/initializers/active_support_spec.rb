require_relative "../spec_helper"

describe 'ActiveSupport::JSON' do
  it "encodes hash keys correctly" do
    expect(ActiveSupport::JSON.encode("<>" => "<>").downcase).to eq "{\"\\u003c\\u003e\":\"\\u003c\\u003e\"}"
  end
end
