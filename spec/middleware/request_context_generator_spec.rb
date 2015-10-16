require File.expand_path(File.dirname(__FILE__) + '/../spec_helper.rb')

describe "RequestContextGenerator" do
  let(:env) { {} }
  let(:request) { stub('Rack::Request', path_parameters: { controller: 'users', action: 'index' }) }
  let(:context) { stub('Course', class: 'Course', id: 15) }

  it "should generate the X-Canvas-Meta response header" do
    _, headers, _ = RequestContextGenerator.new(->(env) {
      RequestContextGenerator.add_meta_header("a1", "test1")
      RequestContextGenerator.add_meta_header("a2", "test2")
      RequestContextGenerator.add_meta_header("a3", "")
      [ 200, {}, [] ]
    }).call(env)
    expect(headers['X-Canvas-Meta']).to eq "a1=test1;a2=test2;"
  end

  it "should add request data to X-Canvas-Meta" do
    _, headers, _ = RequestContextGenerator.new(->(env) {
      RequestContextGenerator.add_meta_header("a1", "test1")
      RequestContextGenerator.store_request_meta(request, nil)
      [ 200, {}, [] ]
    }).call(env)
    expect(headers['X-Canvas-Meta']).to eq "a1=test1;o=users;n=index;"
  end

  it "should add request and context data to X-Canvas-Meta" do
    _, headers, _ = RequestContextGenerator.new(->(env) {
      RequestContextGenerator.add_meta_header("a1", "test1")
      RequestContextGenerator.store_request_meta(request, context)
      [ 200, {}, [] ]
    }).call(env)
    expect(headers['X-Canvas-Meta']).to eq "a1=test1;o=users;n=index;t=Course;i=15;"
  end

  it "should add page view data to X-Canvas-Meta" do
    _, headers, _ = RequestContextGenerator.new(->(env) {
      RequestContextGenerator.add_meta_header("a1", "test1")
      RequestContextGenerator.store_page_view_meta(page_view_model)
      [ 200, {}, [] ]
    }).call(env)
    expect(headers['X-Canvas-Meta']).to eq "a1=test1;x=5;p=f;"
  end

  it "should generate a request_id and store it in Thread.current" do
    Thread.current[:context] = nil
    _, _, _ = RequestContextGenerator.new(->(env) {[200, {}, []]}).call(env)
    expect(Thread.current[:context][:request_id]).to be_present
  end

  it "should add the request_id to X-Request-Context-Id" do
    Thread.current[:context] = nil
    _, headers, _ = RequestContextGenerator.new(->(env) {
      [200, {}, []]
    }).call(env)
    expect(headers['X-Request-Context-Id']).to be_present
  end

  it "should find the session_id in a cookie and store it in Thread.current" do
    Thread.current[:context] = nil
    env['action_dispatch.cookies'] = { log_session_id: 'abc' }
    _, _, _ = RequestContextGenerator.new(->(env) {[200, {}, []]}).call(env)
    expect(Thread.current[:context][:session_id]).to eq 'abc'
  end

  it "should find the session_id from the rack session and add it to X-Session-Id" do
    Thread.current[:context] = nil
    env['rack.session.options'] = { id: 'abc' }
    _, headers, _ = RequestContextGenerator.new(->(env) {
      [200, {}, []]
    }).call(env)
    expect(headers['X-Session-Id']).to eq 'abc'
  end
end
