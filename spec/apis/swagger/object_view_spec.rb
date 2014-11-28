require File.expand_path(File.dirname(__FILE__) + '/swagger_helper')
require 'object_view'

describe ObjectView do
  let(:text) { "Example\n{ \"id\": 5 } { \"start_date\": \"2012-01-01\" }" }
  let(:view) { ObjectView.new(stub('Element', :text => text)) }

  it "separates json into parts" do
    expect(view.clean_json_text_parts).to eq(
      ["\n{ \"id\": 5 }", "{ \"start_date\": \"2012-01-01\" }"]
    )
  end
end