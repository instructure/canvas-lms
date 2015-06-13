require File.expand_path(File.dirname(__FILE__) + '/../spec_helper.rb')

describe "RequestContextGenerator" do
  let(:env) { {} }

  it "should generate the X-Canvas-Meta response header" do
    _, headers, _ = RequestContextGenerator.new(->(env) {
      RequestContextGenerator.add_meta_header("a1", "test1")
      RequestContextGenerator.add_meta_header("a2", "test2")
      RequestContextGenerator.add_meta_header("a3", "")
      [ 200, {}, [] ]
    }).call(env)
    expect(headers['X-Canvas-Meta']).to eq "a1=test1;a2=test2;"
  end

  it "should add page view data to X-Canvas-Meta" do
    _, headers, _ = RequestContextGenerator.new(->(env) {
      RequestContextGenerator.add_meta_header("a1", "test1")
      RequestContextGenerator.store_page_view_meta(page_view_model)
      [ 200, {}, [] ]
    }).call(env)
    expect(headers['X-Canvas-Meta']).to eq "a1=test1;x=5;p=f;"
  end
end
