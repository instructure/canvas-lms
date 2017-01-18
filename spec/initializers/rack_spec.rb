require_relative "../spec_helper"

describe 'Rack::Utils' do
  it "raises an exception if the params are too deep" do
    len = Rack::Utils.param_depth_limit

    expect(-> {
      Rack::Utils.parse_nested_query("foo#{"[a]" * len}=bar")
    }).to raise_error(RangeError)

    expect(-> {
      Rack::Utils.parse_nested_query("foo#{"[a]" * (len - 1)}=bar")
    }).to_not raise_error
  end
end
