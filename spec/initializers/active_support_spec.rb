require_relative "../spec_helper"

describe 'ActiveSupport::JSON' do
  it "encodes hash keys correctly" do
    expect(ActiveSupport::JSON.encode("<>" => "<>").downcase).to eq "{\"\\u003c\\u003e\":\"\\u003c\\u003e\"}"
  end
end

describe ActiveSupport::TimeZone do
  it 'gives a simple JSON interpretation' do
    expect(ActiveSupport::TimeZone['America/Denver'].to_json).to eq "America/Denver".to_json
  end
end
