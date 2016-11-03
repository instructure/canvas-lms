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
    pv = page_view_model
    _, headers, _ = RequestContextGenerator.new(->(_env) {
      RequestContextGenerator.add_meta_header("a1", "test1")
      RequestContextGenerator.store_page_view_meta(pv)
      [ 200, {}, [] ]
    }).call(env)
    f = pv.created_at.try(:utc).try(:iso8601, 2)
    expect(headers['X-Canvas-Meta']).to eq "a1=test1;x=5.0;p=f;f=#{f};"
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

  it "should calculate the 'queued' time if header is passed" do
    Timecop.freeze do
      Thread.current[:context] = nil
      env['HTTP_X_REQUEST_START'] = "t=#{(1.minute.ago.to_f * 1000000).to_i}"
      _, headers, _ = RequestContextGenerator.new(->(env) {
        [200, {}, []]
      }).call(env)
      q = headers["X-Canvas-Meta"].match(/q=(\d+)/)[1].to_f
      expect(q / 1000000).to eq 60.0
    end
  end

  context "when request provides an override context id" do
    let(:shared_secret){ 'sup3rs3cr3t!!' }
    let(:remote_request_context_id){ '1234-5678-9012-3456-7890-1234-5678' }

    let(:remote_signature) do
      Canvas::Security.sign_hmac_sha512(remote_request_context_id, shared_secret)
    end

    before(:each) do
      Thread.current[:context] = nil
      Canvas::DynamicSettings.reset_cache!
      Canvas::DynamicSettings.cache['canvas'] = {
        timetamp: Time.zone.now.to_i,
        value: { "signing-secret" =>  shared_secret }
      }
      env['HTTP_X_REQUEST_CONTEXT_ID'] = Canvas::Security.base64_encode(remote_request_context_id)
      env['HTTP_X_REQUEST_CONTEXT_SIGNATURE'] = Canvas::Security.base64_encode(remote_signature)
    end

    after(:each){ Canvas::DynamicSettings.reset_cache! }

    def run_middleware
      _, headers, _msg = RequestContextGenerator.new(->(_){ [200, {}, []] }).call(env)
      headers
    end

    it "uses a provided request context id if another service submits one that is correctly signed" do
      headers = run_middleware
      expect(Thread.current[:context][:request_id]).to eq(remote_request_context_id)
      expect(headers['X-Request-Context-Id']).to eq(remote_request_context_id)
    end

    it "won't accept an override without a signature" do
      env['HTTP_X_REQUEST_CONTEXT_SIGNATURE'] = nil
      headers = run_middleware
      expect(Thread.current[:context][:request_id]).not_to eq(remote_request_context_id)
      expect(headers['X-Request-Context-Id']).to eq(Thread.current[:context][:request_id])
    end

    it "rejects a wrong signature" do
      env['HTTP_X_REQUEST_CONTEXT_SIGNATURE'] = "nonsense"
      headers = run_middleware
      expect(Thread.current[:context][:request_id]).not_to eq(remote_request_context_id)
      expect(headers['X-Request-Context-Id']).to eq(Thread.current[:context][:request_id])
    end

    it "rejects a tampered ID" do
      env['HTTP_X_REQUEST_CONTEXT_ID'] = "I-changed-it"
      headers = run_middleware
      expect(Thread.current[:context][:request_id]).not_to eq(remote_request_context_id)
      expect(headers['X-Request-Context-Id']).to eq(Thread.current[:context][:request_id])
    end
  end
end
